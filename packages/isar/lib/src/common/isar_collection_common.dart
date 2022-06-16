import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_link_common.dart';

class AsyncLink {
  final int sourceId;
  final int targetId;
  final int linkName;

  AsyncLink({
    required this.sourceId,
    required this.targetId,
    required this.linkName,
  });
}

class AsyncObjectLinkList<OBJ> {
  final objects = <OBJ>[];
  final addedLinks = <AsyncLink>[];
  final removedLinks = <AsyncLink>[];
}

abstract class IsarCollectionBase<OBJ> extends IsarCollection<OBJ> {
  CollectionSchema<OBJ> get schema;

  @override
  Future<OBJ?> get(int id) {
    return getAll([id]).then((objects) => objects[0]);
  }

  @override
  OBJ? getSync(int id) {
    return getAllSync([id])[0];
  }

  @override
  Future<OBJ?> getByIndex(
    String indexName,
    List<Object?> key,
  ) {
    return getAllByIndex(indexName, [key]).then((objects) => objects[0]);
  }

  @override
  OBJ? getByIndexSync(
    String indexName,
    List<Object?> key,
  ) {
    return getAllByIndexSync(indexName, [key])[0];
  }

  @override
  Future<int> put(OBJ object) {
    return putAll([object]).then((ids) => ids[0]);
  }

  @override
  int putSync(OBJ object) {
    return putAllSync([object])[0];
  }

  @override
  Future<List<int>> putAll(List<OBJ> objects) async {
    final list = AsyncObjectLinkList<OBJ>();
    for (var object in objects) {
      list.objects.add(object);
      if (schema.hasLinks) {
        for (var link in schema.getLinks(object)) {
          if (link is IsarLinkCommon) {
          } else if (link is IsarLinksCommon) {}
        }
      }
    }

    final ids = await putAllNative(list);

    for (var i = 0; i < objects.length; i++) {
      final object = objects[i];
      final id = ids[i];
      schema.setId?.call(object, id);
      schema.attachLinks(this, id, object);
    }

    return ids;
  }

  Future<List<int>> putAllNative(AsyncObjectLinkList<OBJ> list);

  @override
  Future<bool> delete(int id) => deleteAll([id]).then((count) => count == 1);

  @override
  bool deleteSync(int id) => deleteAllSync([id]) == 1;

  @override
  Future<bool> deleteByIndex(String indexName, List<Object?> key) =>
      deleteAllByIndex(indexName, [key]).then((count) => count == 1);

  @override
  bool deleteByIndexSync(String indexName, List<Object?> key) =>
      deleteAllByIndexSync(indexName, [key]) == 1;
}
