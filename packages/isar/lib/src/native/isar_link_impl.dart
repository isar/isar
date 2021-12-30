import 'dart:collection';

import 'package:isar/isar.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_core.dart';
import 'util/native_call.dart';

IsarLink<OBJ> newIsarLink<OBJ>() {
  return IsarLinkImpl();
}

IsarLinks<OBJ> newIsarLinks<OBJ>() {
  return IsarLinksImpl();
}

class _IsarLinkBase<OBJ> {
  late IsarCollectionImpl<dynamic> col;
  late IsarCollectionImpl<OBJ> targetCol;
  late dynamic containingObject;
  late int linkIndex;
  late bool backlink;
  bool attached = false;
  bool changed = false;

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
    attached = true;
  }

  int requireAttached() {
    if (!attached) {
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

class IsarLinkImpl<OBJ> extends _IsarLinkBase<OBJ> implements IsarLink<OBJ> {
  OBJ? _value;

  @override
  OBJ? get value => _value;

  @override
  set value(OBJ? value) {
    if (value == null || _value == null) {
      if (value != null || _value != null) {
        _value = value;
        changed = true;
      }
    } else {
      _value = value;
      changed = true;
    }
  }

  @override
  bool get isChanged => changed;

  @override
  Future<void> load() {
    final containingId = requireAttached();
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final rawObjPtr = malloc<RawObject>();
      IC.isar_link_get_first(
          col.ptr, txnPtr, linkIndex, backlink, containingId, rawObjPtr);
      try {
        await stream.first;
        _value = targetCol.deserializeObject(rawObjPtr.ref);
        changed = false;
      } finally {
        malloc.free(rawObjPtr);
      }
    });
  }

  @override
  void loadSync() {
    final containingId = requireAttached();
    col.isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = malloc<RawObject>();
      try {
        nCall(IC.isar_link_get_first(
            col.ptr, txnPtr, linkIndex, backlink, containingId, rawObjPtr));
        _value = targetCol.deserializeObject(rawObjPtr.ref);
        changed = false;
      } finally {
        malloc.free(rawObjPtr);
      }
    });
  }

  @override
  Future<void> save() {
    final containingId = requireAttached();
    if (!changed) {
      return Future.value();
    }
    return col.isar.getTxn(true, (txnPtr, stream) async {
      var targetOid = minLong;
      if (_value != null) {
        final id = targetCol.getId(_value!);
        if (id == null) {
          targetOid = await targetCol.put(_value!);
        } else {
          targetOid = id;
        }
      }
      final rawObjPtr = malloc<RawObject>();
      IC.isar_link_replace(
          col.ptr, txnPtr, linkIndex, backlink, containingId, targetOid);
      try {
        await stream.first;
        changed = false;
      } finally {
        malloc.free(rawObjPtr);
      }
    });
  }

  @override
  void saveSync() {
    final containingId = requireAttached();
    if (!changed) {
      return;
    }
    col.isar.getTxnSync(true, (txnPtr) {
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
      final rawObjPtr = malloc<RawObject>();
      try {
        nCall(IC.isar_link_replace(
            col.ptr, txnPtr, linkIndex, backlink, containingId, targetOid));
        changed = false;
      } finally {
        malloc.free(rawObjPtr);
      }
    });
  }
}

class IsarLinksImpl<OBJ> extends _IsarLinkBase<OBJ>
    with SetMixin<OBJ>
    implements IsarLinks<OBJ> {
  final _objects = <OBJ>{};
  final _addedObjects = <OBJ>{};
  final _removedObjects = <OBJ>{};

  @override
  bool get hasChanges => changed;

  @override
  Future<void> load({bool overrideChanges = false}) async {
    final containingId = requireAttached();
    if (overrideChanges) {
      _addedObjects.clear();
      _removedObjects.clear();
    }
    final objects = await col.isar.getTxn(false, (txnPtr, stream) async {
      final resultsPtr = malloc<RawObjectSet>();
      try {
        IC.isar_link_get_all(
            col.ptr, txnPtr, linkIndex, backlink, containingId, resultsPtr);
        await stream.first;
        return targetCol.deserializeObjects(resultsPtr.ref);
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
        malloc.free(resultsPtr);
      }
    });
    _objects.clear();
    _objects.addAll(objects);
  }

  @override
  void loadSync({bool overrideChanges = false}) {
    final containingId = requireAttached();
    if (overrideChanges) {
      _addedObjects.clear();
      _removedObjects.clear();
    }
    final objects = col.isar.getTxnSync(false, (txnPtr) {
      final resultsPtr = malloc<RawObjectSet>();
      try {
        nCall(IC.isar_link_get_all(
            col.ptr, txnPtr, linkIndex, backlink, containingId, resultsPtr));
        return targetCol.deserializeObjects(resultsPtr.ref);
      } finally {
        malloc.free(resultsPtr);
      }
    });
    _objects.clear();
    _objects.addAll(objects);
  }

  @override
  Future<void> saveChanges() {
    final containingId = requireAttached();
    if (!changed) {
      return Future.value();
    }
    return col.isar.getTxn(true, (txnPtr, stream) async {
      final newObjects = <OBJ>[];
      for (var added in _addedObjects) {
        if (targetCol.getId(added) == null) {
          newObjects.add(added);
        }
      }
      if (newObjects.isNotEmpty) {
        await targetCol.putAll(newObjects);
      }

      final count = _addedObjects.length + _removedObjects.length;
      final idsPtr = malloc<Int64>(count);
      final ids = idsPtr.asTypedList(count);
      var i = 0;
      for (var added in _addedObjects) {
        ids[i++] = targetCol.getId(added)!;
      }
      for (var removed in _removedObjects) {
        ids[i++] = targetCol.getId(removed)!;
      }
      IC.isar_link_update_all(col.ptr, txnPtr, linkIndex, backlink,
          containingId, idsPtr, _addedObjects.length, _removedObjects.length);

      try {
        await stream.first;
      } finally {
        malloc.free(idsPtr);
      }
    });
  }

  @override
  void saveChangesSync() {
    final containingId = requireAttached();
    if (!changed) {
      return;
    }
    col.isar.getTxnSync(true, (txnPtr) {
      for (var added in _addedObjects) {
        var id = targetCol.getId(added);
        if (id == null) {
          targetCol.putSync(added);
          id = targetCol.getId(added)!;
        }
        nCall(IC.isar_link(
            col.ptr, txnPtr, linkIndex, backlink, containingId, id));
      }
      for (var removed in _removedObjects) {
        final removedId = targetCol.getId(removed)!;
        nCall(IC.isar_link_unlink(
            col.ptr, txnPtr, linkIndex, backlink, containingId, removedId));
      }
    });
  }

  @override
  bool add(OBJ value) {
    if (_objects.add(value)) {
      _addedObjects.add(value);
      _removedObjects.remove(value);
      changed = true;
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
    if (value is OBJ && _objects.remove(value)) {
      _addedObjects.remove(value);
      _removedObjects.add(value);
      changed = true;
      return true;
    } else {
      return false;
    }
  }

  @override
  Set<OBJ> toSet() => _objects.toSet();
}
