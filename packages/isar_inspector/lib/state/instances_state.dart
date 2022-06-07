import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'isar_connect_state_notifier.dart';

final instancesPod = FutureProvider((ref) {
  final isarConnect = ref.watch(isarConnectPod.notifier);
  return isarConnect.listInstances();
});

final selectedInstanceNamePod = StateProvider((ref) => 'isar');

final selectedInstancePod = FutureProvider<String>((ref) async {
  final instances = await ref.watch(instancesPod.future);
  final selectedInstance = ref.watch(selectedInstanceNamePod);

  return instances.firstWhere(
    (e) => e == selectedInstance,
    orElse: () => selectedInstance,
  );
});
