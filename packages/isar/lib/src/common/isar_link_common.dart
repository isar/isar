import 'dart:collection';

import 'package:isar/isar.dart';

abstract class IsarLinkBaseImpl<OBJ> implements IsarLinkBase<OBJ> {
  int? _objectId;
  late IsarCollection<dynamic> col;
  late IsarCollection<OBJ> targetCol;
  late String linkName;
  late bool isBacklink;

  @override
  bool get isAttached => _objectId != null;

  @override
  void attach(int? objectId, IsarCollection col, IsarCollection targetCol,
      String linkName, bool isBacklink) {
    if (!identical(col.isar, targetCol.isar)) {
      throw IsarError('Collections need to have the same Isar instance.');
    }
    _objectId = objectId;
    this.col = col;
    this.targetCol = targetCol as IsarCollection<OBJ>;
    this.linkName = linkName;
    this.isBacklink = isBacklink;
  }

  int requireAttached() {
    if (_objectId == null) {
      throw IsarError(
          'Containing object needs to be managed by Isar to use this method.');
    } else {
      return _objectId!;
    }
  }

  int? getId(OBJ obj) => (targetCol as dynamic).getId(obj);

  void resetContent();
}

abstract class IsarLinkCommon<OBJ> extends IsarLinkBaseImpl<OBJ>
    implements IsarLink<OBJ> {
  OBJ? _value;

  var _isChanged = false;

  var _isLoaded = false;

  @override
  bool get isChanged => _isChanged;

  @override
  bool get isLoaded => _isLoaded;

  @override
  OBJ? get value => _value;

  @override
  set value(OBJ? value) {
    _isChanged |= !identical(_value, value);
    _value = value;
    _isLoaded = true;
  }

  void applyLoaded(OBJ? object) {
    _value = object;
    _isChanged = false;
    _isLoaded = true;
  }

  void applySaved(OBJ? object) {
    if (identical(value, object)) {
      _isChanged = false;
    }
    _isLoaded = true;
  }

  @override
  void resetContent() {
    _value = null;
    _isChanged = false;
    _isLoaded = true;
  }
}

abstract class IsarLinksCommon<OBJ> extends IsarLinkBaseImpl<OBJ>
    with SetMixin<OBJ>
    implements IsarLinks<OBJ> {
  final _objects = HashSet<OBJ>.identity();
  final addedObjects = HashSet<OBJ>.identity();
  final removedObjects = HashSet<OBJ>.identity();

  var _isLoaded = false;

  @override
  bool get isChanged => addedObjects.isNotEmpty || removedObjects.isNotEmpty;

  @override
  bool get isLoaded => _isLoaded;

  void applyLoaded(List<OBJ> objects) {
    _objects.clear();
    _objects.addAll(objects);
    _objects.addAll(addedObjects);
    _objects.removeAll(removedObjects);
    _isLoaded = true;
  }

  void applySaved(List<OBJ> added, List<OBJ> removed) {
    addedObjects.removeAll(added);
    removedObjects.removeAll(removed);
    _isLoaded = true;
  }

  void clearChanges() {
    addedObjects.clear();
    removedObjects.clear();
  }

  @override
  void resetContent() {
    clearChanges();
    _objects.clear();
    _isLoaded = true;
  }

  @override
  bool add(OBJ value) {
    if (_objects.add(value)) {
      addedObjects.add(value);
      removedObjects.remove(value);
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
      final removed = _objects.remove(value);
      addedObjects.remove(value);
      if (removed && isAttached) {
        removedObjects.add(value);
      }
      return removed;
    }
    return false;
  }

  @override
  void clear() {
    _objects.clear();
    addedObjects.clear();
    removedObjects.clear();
  }

  @override
  Set<OBJ> toSet() => _objects.toSet();
}
