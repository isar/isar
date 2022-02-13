import 'package:isar/src/common/isar_link_common.dart';
import 'package:isar/src/web/bindings.dart';

import 'isar_collection_impl.dart';
import 'isar_web.dart';

mixin IsarBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  IsarCollectionImpl get col => super.col as IsarCollectionImpl;

  @override
  IsarCollectionImpl<OBJ> get targetCol =>
      super.targetCol as IsarCollectionImpl<OBJ>;

  IsarLinkJs? _link;
  IsarLinkJs get link {
    _link ??= col.col.getLink(linkName);
    return _link!;
  }

  @override
  Future<void> reset() {
    final containingId = requireAttached();
    return col.isar.getTxn(true, (txn) async {
      await link.clear(txn, containingId, isBacklink).wait();
      resetContent();
    });
  }

  @override
  void saveSync() => unsupportedOnWeb();

  @override
  void resetSync() => unsupportedOnWeb();
}

class IsarLinkImpl<OBJ> extends IsarLinkCommon<OBJ> with IsarBaseMixin<OBJ> {
  @override
  Future<void> load() {
    final containingId = requireAttached();
    return col.isar.getTxn(false, (txn) async {
      final obj = await link.loadFirst(txn, containingId, isBacklink).wait();
      applyLoaded(targetCol.deserializeObject(obj));
    });
  }

  @override
  Future<void> save() {
    final containingId = requireAttached();
    if (!isChanged) Future.value();

    final val = value;
    return col.isar.getTxn(true, (txn) async {
      if (val != null) {
        final id = getId(val) ?? await targetCol.put(val);
        await link.replace(txn, containingId, id, isBacklink).wait();
      } else {
        await link.clear(txn, containingId, isBacklink).wait();
      }

      applySaved(val);
    });
  }

  @override
  void loadSync() => unsupportedOnWeb();
}

class IsarLinksImpl<OBJ> extends IsarLinksCommon<OBJ> with IsarBaseMixin<OBJ> {
  @override
  Future<void> load({bool overrideChanges = true}) async {
    final containingId = requireAttached();
    if (overrideChanges) {
      clearChanges();
    }
    final objects = await col.isar.getTxn(false, (txn) {
      return link.loadAll(txn, containingId, isBacklink).wait();
    });
    final result = targetCol.deserializeObjects(objects).cast<OBJ>();
    applyLoaded(result);
  }

  @override
  Future<void> save() {
    final containingId = requireAttached();
    if (!isChanged) return Future.value();

    final added = addedObjects.toList();
    final removed = removedObjects.toList();
    return col.isar.getTxn(true, (txn) async {
      final addedIds = <int>[];
      for (var object in added) {
        var id = targetCol.getId(object);
        id ??= await targetCol.put(object);
        addedIds.add(id);
      }

      final removedIds = <int>[];
      for (var object in removed) {
        final removedId = targetCol.getId(object);
        if (removedId != null) {
          removedIds.add(removedId);
        }
      }

      await link
          .update(txn, containingId, addedIds, removedIds, isBacklink)
          .wait();
    });
  }

  @override
  void loadSync({bool overrideChanges = false}) => unsupportedOnWeb();
}
