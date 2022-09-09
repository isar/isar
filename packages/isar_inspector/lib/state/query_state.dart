import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:isar_inspector/state/collections_state.dart';
import 'package:isar_inspector/state/instances_state.dart';
import 'package:isar_inspector/state/isar_connect_state_notifier.dart';

const int objectsPerPage = 20;

class QueryObject {
  const QueryObject(this.data);

  final Map<String, dynamic> data;

  dynamic getValue(String propertyName) => data[propertyName];
}

final queryPagePod = StateProvider((ref) => 1);

final queryFilterPod = StateProvider<FilterOperation?>((ref) => null);

final querySortPod = StateProvider<SortProperty?>((ref) => null);

class QueryResult {
  QueryResult({
    required this.objects,
    required this.count,
    required this.collectionName,
  });

  final List<QueryObject> objects;
  final int count;
  final String collectionName;
}

final queryResultsPod = FutureProvider<QueryResult>((ref) async {
  final page = ref.watch(queryPagePod);
  final filter = ref.watch(queryFilterPod);
  final sort = ref.watch(querySortPod);
  final isarConnect = ref.watch(isarConnectPod.notifier);
  final selectedInstance = await ref.watch(selectedInstancePod.future);
  final selectedCollection = await ref.watch(selectedCollectionPod.future);

  final result = await isarConnect.executeQuery(
    ConnectQuery(
      instance: selectedInstance,
      collection: selectedCollection.name,
      filter: filter,
      sortProperty: sort,
      offset: (page - 1) * objectsPerPage,
      limit: objectsPerPage,
    ),
  );

  final objects = (result['results']! as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList()
      .map(QueryObject.new)
      .toList();

  return QueryResult(
    objects: objects,
    count: result['count']! as int,
    collectionName: selectedCollection.name,
  );
});
