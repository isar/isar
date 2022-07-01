import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:isar_inspector/state/collections_state.dart';
import 'package:isar_inspector/state/instances_state.dart';
import 'package:isar_inspector/state/isar_connect_state_notifier.dart';

const int objectsPerPage = 50;

class QueryObject {
  const QueryObject(this.data);
  final Map<String, dynamic> data;

  dynamic getValue(String propertyName) => data[propertyName];
}

final queryPagePod = StateProvider((ref) => 0);

final queryFilterPod = StateProvider<FilterOperation?>((ref) => null);

final querySortPod = StateProvider<SortProperty?>((ref) => null);

class QueryResult {
  QueryResult({required this.objects, required this.hasMore});
  final List<QueryObject> objects;
  final bool hasMore;
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
      offset: page * objectsPerPage,
      limit: objectsPerPage + 1,
    ),
  );

  final objects = result.map(QueryObject.new).toList();

  if (objects.isEmpty && page != 0) {
    Timer.run(() {
      ref.read(queryPagePod.state).state = 0;
    });
  }

  return QueryResult(
    objects: objects.length > objectsPerPage
        ? objects.sublist(0, objectsPerPage - 1)
        : objects,
    hasMore: objects.length > objectsPerPage,
  );
});
