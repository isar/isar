// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:isar/src/isar_connect_api.dart';
import 'package:vm_service/vm_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

export 'package:isar/src/isar_connect_api.dart';

class ConnectClient {
  ConnectClient(this.vmService, this.isolateId);

  static const Duration kNormalTimeout = Duration(seconds: 4);
  static const Duration kLongTimeout = Duration(seconds: 10);

  final VmService vmService;
  final String isolateId;

  final collectionInfo = <String, ConnectCollectionInfo>{};

  final _instancesChangedController = StreamController<void>.broadcast();
  final _collectionInfoChangedController = StreamController<void>.broadcast();
  final _queryChangedController = StreamController<void>.broadcast();

  Stream<void> get instancesChanged => _instancesChangedController.stream;
  Stream<void> get collectionInfoChanged =>
      _collectionInfoChangedController.stream;
  Stream<void> get queryChanged => _queryChangedController.stream;

  static Future<ConnectClient> connect(String port, String secret) async {
    final wsUrl = Uri.parse('ws://127.0.0.1:$port/$secret=/ws');
    final channel = WebSocketChannel.connect(wsUrl);

    // ignore: avoid_print
    final stream = channel.stream.handleError(print);

    final service = VmService(
      stream,
      channel.sink.add,
      disposeHandler: channel.sink.close,
    );
    final vm = await service.getVM();
    final isolateId = vm.isolates!.where((e) => e.name == 'main').first.id!;
    await service.streamListen(EventStreams.kExtension);

    final client = ConnectClient(service, isolateId);
    final handlers = {
      ConnectEvent.instancesChanged.event: (_) {
        client._instancesChangedController.add(null);
      },
      ConnectEvent.collectionInfoChanged.event: (Map<String, dynamic> json) {
        final collectionInfo = ConnectCollectionInfo.fromJson(json);
        client.collectionInfo[collectionInfo.collection] = collectionInfo;
        client._collectionInfoChangedController.add(null);
      },
      ConnectEvent.queryChanged.event: (_) {
        client._queryChangedController.add(null);
      },
    };
    service.onExtensionEvent.listen((Event event) {
      final data = event.extensionData?.data ?? {};
      handlers[event.extensionKind]?.call(data);
    });

    return client;
  }

  Future<T> _call<T>(
    ConnectAction action, {
    Duration? timeout = kNormalTimeout,
    Map<String, dynamic>? args,
  }) async {
    var responseFuture = vmService.callServiceExtension(
      action.method,
      isolateId: isolateId,
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

  Future<List<CollectionSchema<dynamic>>> getSchema() async {
    final schema = await _call<List<dynamic>>(ConnectAction.getSchema);
    return schema
        .map(
          (e) => CollectionSchema<dynamic>.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<String>> listInstances() async {
    final instances = await _call<List<dynamic>>(ConnectAction.listInstances);
    return instances.cast();
  }

  Future<void> watchInstance(String instance) async {
    collectionInfo.clear();
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

  Future<void> importJson(
    String instance,
    String collection,
    List<dynamic> objects,
  ) async {
    await _call<dynamic>(
      ConnectAction.importJson,
      args: {
        'instance': instance,
        'collection': collection,
        'objects': objects,
      },
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

  Future<void> disconnect() async {
    await vmService.dispose();
  }
}
