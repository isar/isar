// ignore_for_file: public_member_api_docs

import 'dart:collection';

import 'package:isar/isar.dart';

const bool _kIsWeb = identical(0, 0.0);

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
          'a link to a different collection.',
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

  int requireGetId(OBJ object) {
    final id = getId(object);
    if (id != null) {
      return id;
    } else {
      throw IsarError(
        'Object "$object" has no id and can therefore not be linked. '
        'Make sure to .put() objects before you use them in links.',
      );
    }
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

  Future<void> update({
    List<OBJ> link = const [],
    List<OBJ> unlink = const [],
    bool reset = false,
  });

  void updateSync({
    List<OBJ> link = const [],
    List<OBJ> unlink = const [],
    bool reset = false,
  });
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
  OBJ? get value {
    if (!_isLoaded && !_isChanged && !_kIsWeb) {
      loadSync();
    }
    return _value;
  }

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

    await update(link: [if (object != null) object], reset: true);
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
    updateSync(link: [if (object != null) object], reset: true);

    if (identical(_value, object)) {
      _isChanged = false;
    }
    _isLoaded = true;
  }

  @override
  Future<void> reset() async {
    await update(reset: true);
    _value = null;
    _isChanged = false;
    _isLoaded = true;
  }

  @override
  void resetSync() {
    updateSync(reset: true);
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

  HashSet<OBJ> get _loadedObjects {
    if (!_isLoaded && !_kIsWeb) {
      loadSync();
    }
    return _objects;
  }

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
    await update(link: added, unlink: removed);

    addedObjects.removeAll(added);
    removedObjects.removeAll(removed);
    _isLoaded = true;
  }

  @override
  void saveSync() {
    if (!isChanged) {
      return;
    }

    final added = addedObjects.toList();
    final removed = removedObjects.toList();
    updateSync(link: added, unlink: removed);

    addedObjects.clear();
    removedObjects.clear();
    _isLoaded = true;
  }

  @override
  Future<void> reset() async {
    await update(reset: true);
    clear();
    _isLoaded = true;
  }

  @override
  void resetSync() {
    updateSync(reset: true);
    clear();
    _isLoaded = true;
  }

  @override
  bool add(OBJ value) {
    if (_loadedObjects.add(value)) {
      addedObjects.add(value);
      removedObjects.remove(value);
      return true;
    } else {
      return false;
    }
  }

  @override
  bool contains(Object? element) => _loadedObjects.contains(element);

  @override
  Iterator<OBJ> get iterator => _loadedObjects.iterator;

  @override
  int get length => _loadedObjects.length;

  @override
  OBJ? lookup(Object? element) => _loadedObjects.lookup(element);

  @override
  bool remove(Object? value) {
    if (value is OBJ) {
      final removed = _loadedObjects.remove(value);
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
    _loadedObjects.clear();
    addedObjects.clear();
    removedObjects.clear();
  }

  @override
  Set<OBJ> toSet() => _loadedObjects.toSet();
}
