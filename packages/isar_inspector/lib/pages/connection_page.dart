import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../connected_layout.dart';
import '../error_screen.dart';
import '../state/collections_state.dart';
import '../state/instances_state.dart';
import '../state/isar_connect_state_notifier.dart';

class ConnectionPage extends ConsumerStatefulWidget {
  const ConnectionPage({
    Key? key,
    required this.port,
    required this.secret,
  }) : super(key: key);
  final String port;
  final String secret;

  @override
  ConsumerState<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends ConsumerState<ConnectionPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(isarConnectPortPod.state).state = widget.port;
      ref.read(isarConnectSecretPod.state).state = widget.secret;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final port = ref.watch(isarConnectPortPod);
    if (port.isEmpty) {
      return const Loading();
    }
    final connection = ref.watch(isarConnectPod);
    return connection.map(
      data: (data) => const _InstancesLoader(),
      error: (e) {
        return ErrorScreen(
          message: 'Disconnected',
          retry: () => ref.read(isarConnectPod.notifier).connect(),
        );
      },
      loading: (_) => const Loading(),
    );
  }
}

class _InstancesLoader extends ConsumerWidget {
  const _InstancesLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedInstance = ref.watch(selectedInstancePod);
    return selectedInstance.map(
      data: (data) => const _CollectionsLoader(),
      error: (e) {
        return ErrorScreen(
          message: 'Could not load instances',
          retry: () => ref.refresh(instancesPod),
        );
      },
      loading: (_) => const Loading(),
    );
  }
}

class _CollectionsLoader extends ConsumerWidget {
  const _CollectionsLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCollection = ref.watch(selectedCollectionPod);
    return selectedCollection.map(
      data: (data) => const ConnectedLayout(),
      error: (e) {
        return ErrorScreen(
          message: 'Could not load collections',
          retry: () => ref.refresh(collectionsPod),
        );
      },
      loading: (_) => const Loading(),
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
