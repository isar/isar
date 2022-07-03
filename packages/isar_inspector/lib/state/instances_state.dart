import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:isar_inspector/state/isar_connect_state_notifier.dart';

final instancesPod = FutureProvider((ref) {
  final isarConnect = ref.watch(isarConnectPod.notifier);
  return isarConnect.listInstances();
});

final _selectedInstanceNamePod = StateProvider((ref) => 'isar');

void selectInstance(WidgetRef ref, String instance) {
  ref.read(_selectedInstanceNamePod.state).state = instance;
}

final selectedInstancePod = FutureProvider<String>((ref) async {
  final instances = await ref.watch(instancesPod.future);
  final selectedInstance = ref.watch(_selectedInstanceNamePod);

  return instances.firstWhere(
    (e) => e == selectedInstance,
    orElse: () => instances.first,
  );
});
