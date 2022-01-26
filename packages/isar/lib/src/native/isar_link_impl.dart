import 'dart:collection';
import 'dart:ffi';

import 'package:isar/isar.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_core.dart';

IsarLink<OBJ> nativeIsarLink<OBJ>() {
  return IsarLinkImpl();
}

IsarLinks<OBJ> nativeIsarLinks<OBJ>() {
  return IsarLinksImpl();
}

abstract class IsarLinkBaseImpl<OBJ> implements IsarLinkBase<OBJ> {
  late IsarCollectionImpl<dynamic> col;
  late IsarCollectionImpl<OBJ> targetCol;
  late dynamic containingObject;
  late int linkIndex;
  late bool backlink;

  @override
  bool isAttached = false;

  @override
  void attach(IsarCollection col, IsarCollection<OBJ> targetCol,
      dynamic containingObject, String linkName, bool backlink) {
    if (!identical(col.isar, targetCol.isar)) {
      throw IsarError('Collections need to have the same Isar instance.');
    }
    this.col = col as IsarCollectionImpl;
    this.targetCol = targetCol as IsarCollectionImpl<OBJ>;
    this.containingObject = containingObject;
    final index = backlink ? col.backlinkIds[linkName] : col.linkIds[linkName];
    if (index == null) {
      throw IsarError('Unknown link "$linkName".');
    }
    linkIndex = index;
    this.backlink = backlink;
    isAttached = true;
  }

  int requireAttached() {
    if (!isAttached) {
      throw IsarError(
          'Containing object needs to be managed by Isar to use this method.');
    }

    final id = (col as dynamic).getId(containingObject);
    if (id == null) {
      throw IsarError('Containing object has no id.');
    }
    return id;
  }
}

class IsarLinkImpl<OBJ> extends IsarLinkBaseImpl<OBJ> implements IsarLink<OBJ> {
  OBJ? _value;

  @override
  bool isChanged = false;

  @override
  OBJ? get value => _value;

  @override
  set value(OBJ? value) {
    int? oldId;
    int? newId;
    if (isAttached) {
      oldId = _value != null ? targetCol.getId(_value!) : null;
      newId = value != null ? targetCol.getId(value) : null;
    }
    if (oldId != newId || _value != value) {
      _value = value;
      isChanged = true;
    }
  }

  @override
  Future<void> load() {
    final containingId = requireAttached();
    return col.isar.getTxn(false, (txn) async {
      final rawObjPtr = txn.alloc<RawObject>();

      nCall(IC.isar_link_get_first(
          col.ptr, txn.ptr, linkIndex, backlink, containingId, rawObjPtr));
      await txn.wait();

      _value = targetCol.deserializeObjectOrNull(rawObjPtr.ref);
      isChanged = false;
    });
  }

  @override
  void loadSync() {
    final containingId = requireAttached();
    col.isar.getTxnSync(true, (txn) {
      final rawObjPtr = txn.allocRawObject();
      nCall(IC.isar_link_get_first(
          col.ptr, txn.ptr, linkIndex, backlink, containingId, rawObjPtr));
      _value = targetCol.deserializeObjectOrNull(rawObjPtr.ref);
      isChanged = false;
    });
  }

  @override
  Future<void> save() {
    final containingId = requireAttached();
    if (!isChanged) Future.value();

    return col.isar.getTxn(true, (txn) async {
      var targetOid = minLong;
      if (_value != null) {
        final id = targetCol.getId(_value!);
        if (id == null) {
          targetOid = await targetCol.put(_value!);
        } else {
          targetOid = id;
        }
      }
      IC.isar_link_replace(
          col.ptr, txn.ptr, linkIndex, backlink, containingId, targetOid);
      await txn.wait();
      isChanged = false;
    });
  }

  @override
  void saveSync() {
    final containingId = requireAttached();
    if (!isChanged) return;

    col.isar.getTxnSync(true, (txn) {
      var targetOid = minLong;
      if (_value != null) {
        final id = targetCol.getId(_value!);
        if (id == null) {
          targetCol.putSync(_value!);
          targetOid = targetCol.getId(_value!)!;
        } else {
          targetOid = id;
        }
      }
      nCall(IC.isar_link_replace(
          col.ptr, txn.ptr, linkIndex, backlink, containingId, targetOid));
      isChanged = false;
    });
  }
}

class IsarLinksImpl<OBJ> extends IsarLinkBaseImpl<OBJ>
    with SetMixin<OBJ>
    implements IsarLinks<OBJ> {
  late final _objects = newLinkSet();
  late final _addedObjects = newLinkSet();
  late final _removedObjects = newLinkSet();

  HashSet<OBJ> newLinkSet() {
    return HashSet<OBJ>(
      equals: (a, b) {
        if (isAttached) {
          final idA = targetCol.getId(a);
          final idB = targetCol.getId(b);
          if (idA != null || idB != null) return idA == idB;
        }
        return a == b;
      },
      hashCode: (obj) {
        if (isAttached) {
          final id = targetCol.getId(obj);
          if (id != null) return id;
        }
        return obj.hashCode;
      },
    );
  }

  @override
  bool get isChanged => _addedObjects.isNotEmpty || _removedObjects.isNotEmpty;

  @override
  Future<void> load({bool overrideChanges = false}) async {
    final containingId = requireAttached();
    if (overrideChanges) {
      _addedObjects.clear();
      _removedObjects.clear();
    }
    final objects = await col.isar.getTxn(false, (txn) async {
      final resultsPtr = txn.alloc<RawObjectSet>();
      try {
        IC.isar_link_get_all(
            col.ptr, txn.ptr, linkIndex, backlink, containingId, resultsPtr);
        await txn.wait();
        return targetCol.deserializeObjects(resultsPtr.ref);
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
      }
    });
    applyLoaded(objects);
  }

  @override
  void loadSync({bool overrideChanges = false}) {
    final containingId = requireAttached();
    if (overrideChanges) {
      _addedObjects.clear();
      _removedObjects.clear();
    }
    final objects = col.isar.getTxnSync(false, (txn) {
      final resultsPtr = txn.allocRawObjectsSet();
      try {
        nCall(IC.isar_link_get_all(
            col.ptr, txn.ptr, linkIndex, backlink, containingId, resultsPtr));
        return targetCol.deserializeObjects(resultsPtr.ref);
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
      }
    });
    applyLoaded(objects);
  }

  void applyLoaded(List<OBJ> objects) {
    _objects.clear();
    _objects.addAll(objects);
    _objects.addAll(_addedObjects);
    _objects.removeAll(_removedObjects);
  }

  @override
  Future<void> save() {
    final containingId = requireAttached();
    if (!isChanged) return Future.value();

    return col.isar.getTxn(true, (txn) async {
      final count = _addedObjects.length + _removedObjects.length;
      final idsPtr = txn.alloc<Int64>(count);
      final ids = idsPtr.asTypedList(count);

      var i = 0;
      for (var object in _addedObjects) {
        var id = targetCol.getId(object);
        id ??= await targetCol.put(object);
        ids[i++] = id;
      }

      for (var removed in _removedObjects) {
        ids[i++] = targetCol.getId(removed)!;
      }

      IC.isar_link_update_all(col.ptr, txn.ptr, linkIndex, backlink,
          containingId, idsPtr, _addedObjects.length, _removedObjects.length);
      await txn.wait();
    });
  }

  @override
  void saveSync() {
    final containingId = requireAttached();
    if (!isChanged) return;

    col.isar.getTxnSync(true, (txn) {
      for (var added in _addedObjects) {
        var id = targetCol.getId(added);
        if (id == null) {
          targetCol.putSync(added);
          id = targetCol.getId(added)!;
        }
        nCall(IC.isar_link(
            col.ptr, txn.ptr, linkIndex, backlink, containingId, id));
      }
      for (var removed in _removedObjects) {
        final removedId = targetCol.getId(removed)!;
        nCall(IC.isar_link_unlink(
            col.ptr, txn.ptr, linkIndex, backlink, containingId, removedId));
      }
    });
  }

  @override
  bool add(OBJ value) {
    if (_objects.add(value)) {
      _addedObjects.add(value);
      _removedObjects.remove(value);
      return true;
    } else {
      return false;
    }
  }

  @override
  bool contains(Object? element) => _objects.contains(element);

  @override
  Iterator<OBJ> get iterator => _objects.iterator;

  @override
  int get length => _objects.length;

  @override
  OBJ? lookup(Object? element) => _objects.lookup(element);

  @override
  bool remove(Object? value) {
    if (value is OBJ) {
      var removed = false;
      removed |= _objects.remove(value);
      removed |= _addedObjects.remove(value);
      if (targetCol.getId(value) != null) {
        removed |= _removedObjects.add(value);
      }
      return removed;
    }
    return false;
  }

  @override
  void clear() {
    _objects.clear();
    _addedObjects.clear();
    _removedObjects.clear();
  }

  @override
  Set<OBJ> toSet() => _objects.toSet();
}
