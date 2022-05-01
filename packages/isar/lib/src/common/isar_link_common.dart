import 'dart:collection';

import 'package:isar/isar.dart';

abstract class IsarLinkBaseImpl<OBJ> implements IsarLinkBase<OBJ> {
  var _initialized = false;

  int? _objectId;

  late final String linkName;

  late final IsarCollection sourceCollection;

  late final IsarCollection<OBJ> targetCollection;

  @override
  bool get isAttached => _objectId != null;

  @override
  void attach(
    IsarCollection sourceCollection,
    IsarCollection<OBJ> targetCollection,
    String linkName,
    int? objectId,
  ) {
    if (_initialized) {
      if (linkName != this.linkName ||
          !identical(sourceCollection, this.sourceCollection) ||
          !identical(targetCollection, this.targetCollection)) {
        throw IsarError(
            'Link has been moved! It is not allowed to move a link to a differenct collection.');
      }
    } else {
      _initialized = true;
      this.sourceCollection = sourceCollection;
      this.targetCollection = targetCollection;
      this.linkName = linkName;
    }

    _objectId = objectId;
  }

  int requireAttached() {
    if (_objectId == null) {
      throw IsarError(
          'Containing object needs to be managed by Isar to use this method.');
    } else {
      return _objectId!;
    }
  }

  int? Function(OBJ obj) get getId;

  QueryBuilder<OBJ, OBJ, QAfterFilterCondition> filter() {
    final containingId = requireAttached();
    final qb = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>(
      targetCollection,
      false,
      Sort.asc,
    );

    // ignore: invalid_use_of_protected_member
    return qb.addWhereClauseInternal(LinkWhereClause(
      linkCollection: sourceCollection.name,
      linkName: linkName,
      id: containingId,
    ));
  }

  Future<void> updateInternal(
      Iterable<OBJ> link, Iterable<OBJ> unlink, bool reset) async {
    final unsavedAdded = <OBJ>[];
    final linkIds = <int>[];
    final unlinkIds = <int>[];

    for (var object in link) {
      final id = getId(object);
      if (id != null) {
        linkIds.add(id);
      } else {
        unsavedAdded.add(object);
      }
    }

    if (unsavedAdded.isNotEmpty) {
      final unsavedIds = await targetCollection.putAll(unsavedAdded);
      linkIds.addAll(unsavedIds);
    }

    for (var object in unlink) {
      final removedId = getId(object);
      if (removedId != null) {
        unlinkIds.add(removedId);
      }
    }

    await updateIdsInternal(linkIds, unlinkIds, reset);
  }

  void updateInternalSync(
      Iterable<OBJ> link, Iterable<OBJ> unlink, bool reset) {
    final linkIds = <int>[];
    final unlinkIds = <int>[];

    for (var object in link) {
      final id = getId(object) ?? targetCollection.putSync(object);
      linkIds.add(id);
    }

    for (var object in unlink) {
      final removedId = getId(object);
      if (removedId != null) {
        unlinkIds.add(removedId);
      }
    }

    updateIdsInternalSync(linkIds, unlinkIds, reset);
  }

  Future<void> updateIdsInternal(
      List<int> linkIds, List<int> unlinkIds, bool reset);

  void updateIdsInternalSync(
      List<int> linkIds, List<int> unlinkIds, bool reset);
}

abstract class IsarLinkCommon<OBJ> extends IsarLinkBaseImpl<OBJ>
    with IsarLink<OBJ> {
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

  @override
  Future<void> load() async {
    _value = await filter().findFirst();
    _isChanged = false;
    _isLoaded = true;
  }

  @override
  void loadSync() {
    _value = filter().findFirstSync();
    _isChanged = false;
    _isLoaded = true;
  }

  @override
  Future<void> save() async {
    if (!isChanged) return;
    final object = _value;

    await updateInternal([if (object != null) object], [], true);
    if (identical(_value, object)) {
      _isChanged = false;
    }
    _isLoaded = true;
  }

  @override
  void saveSync() {
    if (!isChanged) return;
    final object = _value;

    updateInternalSync([if (object != null) object], [], true);
    if (identical(_value, object)) {
      _isChanged = false;
    }
    _isLoaded = true;
  }

  @override
  Future<void> reset() async {
    await updateIdsInternal([], [], true);
    _value = null;
    _isChanged = false;
    _isLoaded = true;
  }

  @override
  void resetSync() {
    updateIdsInternal([], [], true);
    _value = null;
    _isChanged = false;
    _isLoaded = true;
  }
}

abstract class IsarLinksCommon<OBJ> extends IsarLinkBaseImpl<OBJ>
    with IsarLinks<OBJ>, SetMixin<OBJ> {
  final _objects = HashSet<OBJ>.identity();
  final addedObjects = HashSet<OBJ>.identity();
  final removedObjects = HashSet<OBJ>.identity();

  var _isLoaded = false;

  @override
  bool get isChanged => addedObjects.isNotEmpty || removedObjects.isNotEmpty;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> load({bool overrideChanges = true}) async {
    final objects = await filter().findAll();
    _applyLoaded(objects, overrideChanges);
  }

  @override
  void loadSync({bool overrideChanges = true}) {
    final objects = filter().findAllSync();
    _applyLoaded(objects, overrideChanges);
  }

  void _applyLoaded(List<OBJ> objects, bool overrideChanges) {
    if (overrideChanges) {
      addedObjects.clear();
      removedObjects.clear();
    }
    _objects.clear();
    _objects.addAll(objects);
    _objects.addAll(addedObjects);
    _objects.removeAll(removedObjects);
    _isLoaded = true;
  }

  @override
  Future<void> save() async {
    if (!isChanged) return;

    final added = addedObjects.toList();
    final removed = removedObjects.toList();

    await updateInternal(added, removed, false);

    addedObjects.removeAll(added);
    removedObjects.removeAll(removed);
    _isLoaded = true;
  }

  @override
  void saveSync() {
    if (!isChanged) return;

    updateInternalSync(addedObjects, removedObjects, false);

    addedObjects.clear();
    removedObjects.clear();
    _isLoaded = true;
  }

  @override
  Future<void> update({
    List<OBJ> link = const [],
    List<OBJ> unlink = const [],
  }) {
    return updateInternal(link, unlink, false);
  }

  @override
  void updateSync({List<OBJ> link = const [], List<OBJ> unlink = const []}) {
    return updateInternalSync(link, unlink, false);
  }

  @override
  Future<void> reset() async {
    await updateIdsInternal([], [], true);
    clear();
    _isLoaded = true;
  }

  @override
  void resetSync() {
    updateIdsInternalSync([], [], true);
    clear();
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
