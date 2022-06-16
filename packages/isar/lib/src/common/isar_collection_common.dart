import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_link_common.dart';

class AsyncLink {
  final int sourceIndex;
  final int targetId;
  final String linkName;

  AsyncLink({
    required this.sourceIndex,
    required this.targetId,
    required this.linkName,
  });
}

class AsyncObjectLinkList<OBJ> {
  final objects = <OBJ>[];
  final addedLinks = <AsyncLink>[];
  final removedLinks = <AsyncLink>[];
  final resetLinks = <AsyncLink>[];
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
      for (var link in schema.getLinks(object)) {
        if (!link.isChanged) continue;
        if (link is IsarLinkCommon) {
          final target = link.value;
          if (target != null) {
            final targetId = link.getId(target);
            if (targetId != null) {
              list.addedLinks.add(AsyncLink(
                sourceIndex: list.objects.length - 1,
                targetId: targetId,
                linkName: link.linkName,
              ));
            }
          }

          list.resetLinks.add(AsyncLink(
            sourceIndex: list.objects.length - 1,
            targetId: 0,
            linkName: link.linkName,
          ));
        } else if (link is IsarLinksCommon) {
          for (var added in link.addedObjects) {
            final addedId = link.getId(added);
            if (addedId != null) {
              list.addedLinks.add(AsyncLink(
                sourceIndex: list.objects.length - 1,
                targetId: addedId,
                linkName: link.linkName,
              ));
            }
          }

          for (var removed in link.removedObjects) {
            final removedId = link.getId(removed);
            if (removedId != null) {
              list.addedLinks.add(AsyncLink(
                sourceIndex: list.objects.length - 1,
                targetId: removedId,
                linkName: link.linkName,
              ));
            }
          }
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
