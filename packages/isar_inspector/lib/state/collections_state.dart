import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_inspector/schema.dart';
import 'package:isar_inspector/state/instances_state.dart';

import 'package:isar_inspector/state/isar_connect_state_notifier.dart';

final collectionsPod = FutureProvider((ref) async {
  ref.watch(isarConnectPod);
  final isarConnect = ref.watch(isarConnectPod.notifier);
  final schema = await isarConnect.getSchema();
  return schema
      .map((e) => ICollection.fromJson(e as Map<String, dynamic>, schema))
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
