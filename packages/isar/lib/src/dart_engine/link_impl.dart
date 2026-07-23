import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_link_base_impl.dart';
import 'package:isar/src/common/isar_link_common.dart';
import 'package:isar/src/common/isar_links_common.dart';
import 'package:isar/src/dart_engine/engine.dart';

mixin DartEngineLinkMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  Id Function(OBJ) get getId => targetCollection.schema.getId;

  @override
  Future<void> update({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  }) async {
    final source = sourceCollection as DartEngineCollection<dynamic>;
    final target = targetCollection as DartEngineCollection<OBJ>;
    final isar = source.isar;
    final sourceId = requireAttached();
    final add = <Id>[];
    for (final object in link) {
      var id = getId(object);
      if (id == Isar.autoIncrement) {
        id = await target.put(object);
      }
      add.add(id);
    }
    final remove = unlink.map(requireGetId).toList();
    await isar.getTxn(true, (EngineTransaction transaction) async {
      isar.updateLink(
        transaction,
        source.name,
        linkName,
        sourceId,
        add: add,
        remove: remove,
        reset: reset,
      );
    });
  }

  @override
  void updateSync({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  }) {
    final source = sourceCollection as DartEngineCollection<dynamic>;
    final target = targetCollection as DartEngineCollection<OBJ>;
    final isar = source.isar;
    final sourceId = requireAttached();
    isar.getTxnSync(true, (EngineTransaction transaction) {
      final add = <Id>[];
      for (final object in link) {
        var id = getId(object);
        if (id == Isar.autoIncrement) {
          id = target.putSync(object);
        }
        add.add(id);
      }
      isar.updateLink(
        transaction,
        source.name,
        linkName,
        sourceId,
        add: add,
        remove: unlink.map(requireGetId),
        reset: reset,
      );
    });
  }
}

class IsarLinkImpl<OBJ> extends IsarLinkCommon<OBJ>
    with DartEngineLinkMixin<OBJ> {}

class IsarLinksImpl<OBJ> extends IsarLinksCommon<OBJ>
    with DartEngineLinkMixin<OBJ> {}
