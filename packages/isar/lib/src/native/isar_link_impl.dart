part of isar_native;

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

  void attach(IsarCollectionImpl col, IsarCollectionImpl<OBJ> targetCol,
      dynamic containingObject, int linkIndex, bool backlink) {
    assert(identical(col.isar, targetCol.isar),
        'Collections need to have the same Isar instance.');
    this.col = col;
    this.targetCol = targetCol;
    this.containingObject = containingObject;
    this.linkIndex = linkIndex;
    this.backlink = backlink;
    attached = true;
  }

  void requireAttached() {
    if (!attached) {
      throw IsarError(
          'Containing object needs to be managed by Isar to use this method.');
    }
  }

  int get containingOid => (col as dynamic).getId(containingObject)!;

  Pointer get linkColPtr => backlink ? targetCol.ptr : col.ptr;
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
    requireAttached();
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final rawObjPtr = malloc<RawObject>();
      IC.isar_link_get_first_async(
          linkColPtr, txnPtr, linkIndex, backlink, containingOid, rawObjPtr);
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
    requireAttached();
    col.isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = malloc<RawObject>();
      try {
        nCall(IC.isar_link_get_first(
            linkColPtr, txnPtr, linkIndex, backlink, containingOid, rawObjPtr));
        _value = targetCol.deserializeObject(rawObjPtr.ref);
        changed = false;
      } finally {
        malloc.free(rawObjPtr);
      }
    });
  }

  @override
  Future<void> save() {
    requireAttached();
    if (!changed) {
      return Future.value();
    }
    return col.isar.getTxn(true, (txnPtr, stream) async {
      var targetOid = minLong;
      if (_value != null) {
        final id = targetCol.getId(_value!);
        if (id == null) {
          await targetCol.put(_value!);
          targetOid = targetCol.getId(_value!)!;
        } else {
          targetOid = id;
        }
      }
      final rawObjPtr = malloc<RawObject>();
      IC.isar_link_replace_async(
          linkColPtr, txnPtr, linkIndex, backlink, containingOid, targetOid);
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
    requireAttached();
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
            linkColPtr, txnPtr, linkIndex, backlink, containingOid, targetOid));
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
    requireAttached();
    if (overrideChanges) {
      _addedObjects.clear();
      _removedObjects.clear();
    }
    final objects = await col.isar.getTxn(false, (txnPtr, stream) async {
      final resultsPtr = malloc<RawObjectSet>();
      try {
        IC.isar_link_get_all_async(
            linkColPtr, txnPtr, linkIndex, backlink, containingOid, resultsPtr);
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
    requireAttached();
    if (overrideChanges) {
      _addedObjects.clear();
      _removedObjects.clear();
    }
    final objects = col.isar.getTxnSync(false, (txnPtr) {
      final resultsPtr = malloc<RawObjectSet>();
      try {
        nCall(IC.isar_link_get_all(linkColPtr, txnPtr, linkIndex, backlink,
            containingOid, resultsPtr));
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
    requireAttached();
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
      IC.isar_link_update_all_async(linkColPtr, txnPtr, linkIndex, backlink,
          containingOid, idsPtr, _addedObjects.length, _removedObjects.length);

      try {
        await stream.first;
      } finally {
        malloc.free(idsPtr);
      }
    });
  }

  @override
  void saveChangesSync() {
    requireAttached();
    if (!changed) {
      return;
    }
    final oid = containingOid;
    col.isar.getTxnSync(true, (txnPtr) {
      for (var added in _addedObjects) {
        var id = targetCol.getId(added);
        if (id == null) {
          targetCol.putSync(added);
          id = targetCol.getId(added)!;
        }
        nCall(IC.isar_link(linkColPtr, txnPtr, linkIndex, backlink, oid, id));
      }
      for (var removed in _removedObjects) {
        final removedId = targetCol.getId(removed)!;
        nCall(IC.isar_link_unlink(
            linkColPtr, txnPtr, linkIndex, backlink, oid, removedId));
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
