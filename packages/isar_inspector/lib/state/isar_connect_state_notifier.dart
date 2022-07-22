// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/src/isar_connect_api.dart';
import 'package:isar_inspector/state/collections_state.dart';
import 'package:isar_inspector/state/instances_state.dart';
import 'package:isar_inspector/state/query_state.dart';
import 'package:vm_service/vm_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

export 'package:isar/src/isar_connect_api.dart';

class IsarConnection {
  IsarConnection(this.vmService, this.isolateId);

  final VmService vmService;
  final String isolateId;
}

final isarConnectPortPod = StateProvider((ref) => '');
final isarConnectSecretPod = StateProvider((ref) => '');

final isarConnectPod =
    StateNotifierProvider<IsarConnectStateNotifier, AsyncValue<IsarConnection>>(
  (ref) {
    return IsarConnectStateNotifier(
      ref: ref,
      port: ref.watch(isarConnectPortPod),
      secret: ref.watch(isarConnectSecretPod),
    );
  },
);

class IsarConnectStateNotifier
    extends StateNotifier<AsyncValue<IsarConnection>> {
  IsarConnectStateNotifier({
    required this.ref,
    required this.port,
    required this.secret,
  }) : super(const AsyncValue.loading()) {
    connect();
  }

  static const Duration kNormalTimeout = Duration(seconds: 4);
  static const Duration kLongTimeout = Duration(seconds: 10);

  final Ref ref;
  final String port;
  final String secret;

  late final Map<String, void Function(Map<String, dynamic> _)> eventHandler = {
    ConnectEvent.instancesChanged.event: _onInstancesChanged,
    ConnectEvent.collectionInfoChanged.event: _onCollectionInfoChanged,
    ConnectEvent.queryChanged.event: _onQueryChanged,
  };

  Future<void> connect() async {
    state = const AsyncValue.loading();
    try {
      final wsUrl = Uri.parse('ws://127.0.0.1:$port/$secret=/ws');
      final channel = WebSocketChannel.connect(wsUrl);

      var done = false;
      final stream = channel.stream.handleError((_) {
        done = true;
        if (mounted) {
          state = const AsyncValue.error('disconnected');
        }
      });

      final service = VmService(
        stream,
        channel.sink.add,
        disposeHandler: channel.sink.close,
      );
      final vm = await service.getVM();
      final isolateId = vm.isolates!.where((e) => e.name == 'main').first.id!;
      await service.streamListen(EventStreams.kExtension);

      service.onExtensionEvent.listen((Event event) {
        final data = event.extensionData?.data ?? {};
        eventHandler[event.extensionKind]?.call(data);
      });

      if (!done) {
        state = AsyncValue.data(IsarConnection(service, isolateId));
      }
    } catch (e) {
      state = AsyncValue.error(e);
    }
  }

  Future<T> _call<T>(
    ConnectAction action, {
    Duration? timeout = kNormalTimeout,
    Map<String, dynamic>? args,
  }) async {
    final connection = state.value!;
    var responseFuture = connection.vmService.callServiceExtension(
      action.method,
      isolateId: connection.isolateId,
      args: {
        if (args != null) 'args': jsonEncode(args),
      },
    );
    if (timeout != null) {
      responseFuture = responseFuture.timeout(timeout);
    }

    final response = await responseFuture;
    return response.json?['result'] as T;
  }

  void _onInstancesChanged(_) {
    ref.refresh(instancesPod);
  }

  void _onCollectionInfoChanged(Map<String, dynamic> data) {
    final collectionInfo = ConnectCollectionInfo.fromJson(data);
    final infoPod = ref.read(collectionInfoPod.state);
    infoPod.state = {
      ...infoPod.state,
      collectionInfo.collection: collectionInfo
    };
  }

  void _onQueryChanged(_) {
    ref.refresh(queryResultsPod);
  }

  Future<int> getVersion() => _call(ConnectAction.getVersion);

  Future<List<dynamic>> getSchema() => _call(ConnectAction.getSchema);

  Future<List<String>> listInstances() async {
    final instances = await _call<List<dynamic>>(ConnectAction.listInstances);
    return instances.cast();
  }

  Future<void> watchInstance(String instance) async {
    await _call<dynamic>(
      ConnectAction.watchInstance,
      args: {'instance': instance},
    );
  }

  Future<Map<String, Object?>> executeQuery(ConnectQuery query) async {
    return _call<Map<String, Object?>>(
      ConnectAction.executeQuery,
      args: query.toJson(),
      timeout: kLongTimeout,
    );
  }

  Future<void> removeQuery(ConnectQuery query) async {
    await _call<dynamic>(
      ConnectAction.removeQuery,
      args: query.toJson(),
      timeout: kLongTimeout,
    );
  }

  Future<List<dynamic>> exportJson(ConnectQuery query) async {
    final data = await _call<List<dynamic>>(
      ConnectAction.exportJson,
      args: query.toJson(),
      timeout: kLongTimeout,
    );

    return data.cast();
  }

  Future<void> editProperty(ConnectEdit edit) async {
    await _call<dynamic>(
      ConnectAction.editProperty,
      args: edit.toJson(),
      timeout: kLongTimeout,
    );
  }

  Future<void> addInList(ConnectEdit edit) async {
    await _call<dynamic>(
      ConnectAction.addInList,
      args: edit.toJson(),
      timeout: kLongTimeout,
    );
  }

  Future<void> removeFromList(ConnectEdit edit) async {
    await _call<dynamic>(
      ConnectAction.removeFromList,
      args: edit.toJson(),
      timeout: kLongTimeout,
    );
  }

  Future<void> disconnect() async {
    await state.value?.vmService.dispose();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
