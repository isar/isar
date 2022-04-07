import 'dart:ffi';

import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_link_common.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_core.dart';

mixin IsarBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  IsarCollectionImpl get col => super.col as IsarCollectionImpl;

  @override
  IsarCollectionImpl<OBJ> get targetCol =>
      super.targetCol as IsarCollectionImpl<OBJ>;

  int get linkIndex => isBacklink ? col.backlinkIds[linkName]! : col.linkIds[linkName]!;

  @override
  Future<void> reset() async {
    final containingId = requireAttached();
    return col.isar.getTxn(true, (txn) async {
      IC.isar_link_replace(col.ptr, txn.ptr, linkIndex, isBacklink,
          containingId, Isar.autoIncrement);
      await txn.wait();
      resetContent();
    });
  }

  @override
  void resetSync() {
    final containingId = requireAttached();
    return col.isar.getTxnSync(true, (txn) async {
      IC.isar_link_replace(col.ptr, txn.ptr, linkIndex, isBacklink,
          containingId, Isar.autoIncrement);
      resetContent();
    });
  }
}

class IsarLinkImpl<OBJ> extends IsarLinkCommon<OBJ> with IsarBaseMixin<OBJ> {
  @override
  Future<void> load() {
    final containingId = requireAttached();
    return col.isar.getTxn(false, (txn) async {
      final rawObjPtr = txn.alloc<RawObject>();

      nCall(IC.isar_link_get_first(
          col.ptr, txn.ptr, linkIndex, isBacklink, containingId, rawObjPtr));
      await txn.wait();

      final obj = targetCol.deserializeObjectOrNull(rawObjPtr.ref);
      applyLoaded(obj);
    });
  }

  @override
  void loadSync() {
    final containingId = requireAttached();
    col.isar.getTxnSync(false, (txn) {
      final rawObjPtr = txn.allocRawObject();
      nCall(IC.isar_link_get_first(
          col.ptr, txn.ptr, linkIndex, isBacklink, containingId, rawObjPtr));
      final obj = targetCol.deserializeObjectOrNull(rawObjPtr.ref);
      applyLoaded(obj);
    });
  }

  @override
  Future<void> save() {
    final containingId = requireAttached();
    if (!isChanged) Future.value();

    final val = value;
    return col.isar.getTxn(true, (txn) async {
      var targetId = Isar.autoIncrement;
      if (val != null) {
        targetId = targetCol.getId(val) ?? await targetCol.put(val);
      }
      IC.isar_link_replace(
          col.ptr, txn.ptr, linkIndex, isBacklink, containingId, targetId);
      await txn.wait();
      applySaved(val);
    });
  }

  @override
  void saveSync() {
    final containingId = requireAttached();
    if (!isChanged) return;

    final val = value;
    col.isar.getTxnSync(true, (txn) {
      var targetId = Isar.autoIncrement;
      if (val != null) {
        targetId = targetCol.getId(val) ?? targetCol.putSync(val);
      }
      nCall(IC.isar_link_replace(
          col.ptr, txn.ptr, linkIndex, isBacklink, containingId, targetId));
      applySaved(val);
    });
  }
}

class IsarLinksImpl<OBJ> extends IsarLinksCommon<OBJ> with IsarBaseMixin<OBJ> {
  @override
  Future<void> load({bool overrideChanges = true}) async {
    final containingId = requireAttached();
    if (overrideChanges) {
      clearChanges();
    }
    final objects = await col.isar.getTxn(false, (txn) async {
      final resultsPtr = txn.alloc<RawObjectSet>();
      try {
        IC.isar_link_get_all(
            col.ptr, txn.ptr, linkIndex, isBacklink, containingId, resultsPtr);
        await txn.wait();
        return targetCol.deserializeObjects(resultsPtr.ref);
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
      }
    });
    applyLoaded(objects);
  }

  @override
  void loadSync({bool overrideChanges = true}) {
    final containingId = requireAttached();
    if (overrideChanges) {
      clearChanges();
    }
    final objects = col.isar.getTxnSync(false, (txn) {
      final resultsPtr = txn.allocRawObjectsSet();
      try {
        nCall(IC.isar_link_get_all(
            col.ptr, txn.ptr, linkIndex, isBacklink, containingId, resultsPtr));
        return targetCol.deserializeObjects(resultsPtr.ref);
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
      }
    });
    applyLoaded(objects);
  }

  @override
  Future<void> save() {
    final containingId = requireAttached();
    if (!isChanged) return Future.value();

    final added = addedObjects.toList();
    final removed = removedObjects.toList();
    return col.isar.getTxn(true, (txn) async {
      final count = added.length + removed.length;
      final idsPtr = txn.alloc<Int64>(count);
      final ids = idsPtr.asTypedList(count);

      var i = 0;
      final unsavedAdded = <OBJ>[];
      for (var object in added) {
        final id = targetCol.getId(object);
        if (id == null) {
          unsavedAdded.add(object);
        } else {
          ids[i++] = id;
        }
      }

      if (unsavedAdded.isNotEmpty) {
        final unsavedIds = await targetCol.putAll(unsavedAdded);
        ids.setAll(i, unsavedIds);
        i += unsavedIds.length;
      }

      for (var removed in removed) {
        final removedId = targetCol.getId(removed);
        if (removedId != null) {
          ids[i++] = removedId;
        }
      }

      IC.isar_link_update_all(col.ptr, txn.ptr, linkIndex, isBacklink,
          containingId, idsPtr, added.length, i - added.length);
      await txn.wait();
      applySaved(added, removed);
    });
  }

  @override
  void saveSync() {
    final containingId = requireAttached();
    if (!isChanged) return;

    col.isar.getTxnSync(true, (txn) {
      for (var added in addedObjects) {
        var id = targetCol.getId(added);
        if (id == null) {
          targetCol.putSync(added);
          id = targetCol.getId(added)!;
        }
        nCall(IC.isar_link(
            col.ptr, txn.ptr, linkIndex, isBacklink, containingId, id));
      }
      for (var removed in removedObjects) {
        final removedId = targetCol.getId(removed);
        if (removedId != null) {
          nCall(IC.isar_link_unlink(col.ptr, txn.ptr, linkIndex, isBacklink,
              containingId, removedId));
        }
      }
    });
    clearChanges();
  }
}
