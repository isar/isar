// ignore_for_file: public_member_api_docs

import 'dart:collection';

import 'package:isar/isar.dart';

abstract class IsarLinkBaseImpl<OBJ> implements IsarLinkBase<OBJ> {
  var _initialized = false;

  int? _objectId;

  late final String linkName;

  late final IsarCollection<dynamic> sourceCollection;

  late final IsarCollection<OBJ> targetCollection;

  @override
  bool get isAttached => _objectId != null;

  @override
  void attach(
    IsarCollection<dynamic> sourceCollection,
    IsarCollection<OBJ> targetCollection,
    String linkName,
    int? objectId,
  ) {
    if (_initialized) {
      if (linkName != this.linkName ||
          !identical(sourceCollection, this.sourceCollection) ||
          !identical(targetCollection, this.targetCollection)) {
        throw IsarError(
          'Link has been moved! It is not allowed to move '
          'a link to a differenct collection.',
        );
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
        'Containing object needs to be managed by Isar to use this method.',
      );
    } else {
      return _objectId!;
    }
  }

  int? Function(OBJ obj) get getId;

  List<int> objectsToIds(Iterable<OBJ> objetcs) {
    final ids = <int>[];
    for (final object in objetcs) {
      final id = getId(object);
      if (id != null) {
        ids.add(id);
      } else {
        throw IsarError(
          'Object $object has no id and can therefore not be linked.',
        );
      }
    }
    return ids;
  }

  QueryBuilder<OBJ, OBJ, QAfterFilterCondition> filter() {
    final containingId = requireAttached();
    final qb = QueryBuilderInternal(
      collection: targetCollection,
      whereClauses: [
        LinkWhereClause(
          linkCollection: sourceCollection.name,
          linkName: linkName,
          id: containingId,
        ),
      ],
    );
    return QueryBuilder(qb);
  }

  Future<void> updateNative(List<int> linkIds, List<int> unlinkIds, bool reset);

  void updateNativeSync(List<int> linkIds, List<int> unlinkIds, bool reset);
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
    if (!isChanged) {
      return;
    }

    final object = _value;
    final objectIds = objectsToIds([if (object != null) object]);

    await updateNative(objectIds, [], true);
    if (identical(_value, object)) {
      _isChanged = false;
    }
    _isLoaded = true;
  }

  @override
  void saveSync() {
    if (!isChanged) {
      return;
    }

    final object = _value;
    final objectIds = objectsToIds([if (object != null) object]);

    updateNativeSync(objectIds, [], true);
    if (identical(_value, object)) {
      _isChanged = false;
    }
    _isLoaded = true;
  }

  @override
  Future<void> reset() async {
    await updateNative([], [], true);
    _value = null;
    _isChanged = false;
    _isLoaded = true;
  }

  @override
  void resetSync() {
    updateNativeSync([], [], true);
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

  List<int> get addedIds => objectsToIds(addedObjects);
  List<int> get removedIds => objectsToIds(removedObjects);

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
    if (!isChanged) {
      return;
    }

    final added = addedObjects.toList();
    final removed = removedObjects.toList();

    await updateNative(addedIds, removedIds, false);

    addedObjects.removeAll(added);
    removedObjects.removeAll(removed);
    _isLoaded = true;
  }

  @override
  void saveSync() {
    if (!isChanged) {
      return;
    }

    updateNativeSync(addedIds, removedIds, false);

    addedObjects.clear();
    removedObjects.clear();
    _isLoaded = true;
  }

  @override
  Future<void> update({
    List<OBJ> link = const [],
    List<OBJ> unlink = const [],
  }) {
    return updateNative(objectsToIds(link), objectsToIds(unlink), false);
  }

  @override
  void updateSync({List<OBJ> link = const [], List<OBJ> unlink = const []}) {
    return updateNativeSync(objectsToIds(link), objectsToIds(unlink), false);
  }

  @override
  Future<void> reset() async {
    await updateNative([], [], true);
    clear();
    _isLoaded = true;
  }

  @override
  void resetSync() {
    updateNativeSync([], [], true);
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
