import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'collections_state.dart';
import 'instances_state.dart';
import 'isar_connect_state_notifier.dart';

const objectsPerPage = 50;

class QueryObject {
  final Map<String, dynamic> data;

  const QueryObject(this.data);

  String getValue(String propertyName) {
    return data[propertyName]?.toString() ?? '';
  }
}

final queryPagePod = StateProvider((ref) => 0);

final queryFilterPod = StateProvider<FilterOperation?>((ref) => null);

final querySortPod = StateProvider<SortProperty?>((ref) => null);

class QueryResult {
  final List<QueryObject> objects;
  final bool hasMore;

  QueryResult({required this.objects, required this.hasMore});
}

final queryResultsPod = FutureProvider<QueryResult>((ref) async {
  final page = ref.watch(queryPagePod);
  final filter = ref.watch(queryFilterPod);
  final sort = ref.watch(querySortPod);
  final isarConnect = ref.watch(isarConnectPod.notifier);
  final selectedInstance = await ref.watch(selectedInstancePod.future);
  final selectedCollection = await ref.watch(selectedCollectionPod.future);

  final result = await isarConnect.executeQuery(ConnectQuery(
    instance: selectedInstance,
    collection: selectedCollection.name,
    filter: filter,
    sortProperty: sort,
    offset: page * objectsPerPage,
    limit: objectsPerPage + 1,
  ));

  final objects = result.map(QueryObject.new).toList();

  if (objects.isEmpty && page != 0) {
    Timer.run(() {
      ref.read(queryPagePod.state).state = 0;
    });
  }

  return QueryResult(
    objects: objects.isNotEmpty ? objects.sublist(0, objectsPerPage - 1) : [],
    hasMore: objects.length > objectsPerPage,
  );
});
