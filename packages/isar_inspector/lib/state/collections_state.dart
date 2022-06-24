import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../schema.dart';
import 'instances_state.dart';

import 'isar_connect_state_notifier.dart';

final collectionsPod = FutureProvider((ref) async {
  ref.watch(isarConnectPod);
  final isarConnect = ref.watch(isarConnectPod.notifier);
  final schema = await isarConnect.getSchema();
  return schema
      .map((e) => ICollection.fromJson(e as Map<String, dynamic>))
      .toList();
});

final selectedCollectionNamePod = StateProvider<String?>((ref) => null);

final selectedCollectionPod = FutureProvider<ICollection>((ref) async {
  final collections = await ref.watch(collectionsPod.future);
  final selectedCollection = ref.watch(selectedCollectionNamePod);

  return collections.firstWhere(
    (e) => e.name == selectedCollection,
    orElse: () => collections.first,
  );
});

final collectionInfoPod = StateProvider((ref) {
  ref.watch(selectedInstancePod);
  return <String, ConnectCollectionInfo>{};
});
