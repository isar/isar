// ignore_for_file: invalid_use_of_protected_member, public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_common.dart';
import 'package:isar/src/web/isar_reader_impl.dart';
import 'package:isar/src/web/isar_writer_impl.dart';

typedef EngineState = Map<String, Map<Id, Map<Object, dynamic>>>;

class DartEngineIsar extends IsarCommon {
  DartEngineIsar(
    super.name,
    List<CollectionSchema<dynamic>> schemas, {
    EngineState? initialState,
    this.persist,
    this.onClose,
  }) {
    for (final schema in schemas) {
      offsets[schema.type] = _offsets(schema);
      for (final embedded in schema.embeddedSchemas.values) {
        offsets[embedded.type] = _offsets(embedded);
      }
      _state[schema.name] = initialState?[schema.name] ?? {};
    }

    final collections = <Type, IsarCollection<dynamic>>{};
    for (final schema in schemas) {
      schema.toCollection(<OBJ>() {
        final typed = schema as CollectionSchema<OBJ>;
        collections[OBJ] = DartEngineCollection<OBJ>(this, typed);
      });
    }
    attachCollections(collections);
  }

  final offsets = <Type, List<int>>{};
  EngineState _state = {};
  final Future<void> Function(EngineState state)? persist;
  final void Function()? onClose;
  Future<void> _writeTail = Future.value();
  final _watchers = <String, StreamController<void>>{};
  final _objectWatchers = <String, StreamController<void>>{};

  @override
  String? get directory => null;

  EngineTransaction current(bool write) =>
      getTxnSync(write, (EngineTransaction transaction) => transaction);

  @override
  Future<Transaction> beginTxn(bool write, bool silent) async {
    if (!write) {
      return EngineTransaction(this, false, silent, _copyState(_state));
    }
    final previous = _writeTail;
    final release = Completer<void>();
    _writeTail = previous.then((_) => release.future);
    await previous;
    return EngineTransaction(
      this,
      true,
      silent,
      _copyState(_state),
      release: release,
    );
  }

  @override
  Transaction beginTxnSync(bool write, bool silent) =>
      EngineTransaction(this, write, silent, _copyState(_state));

  void publish(EngineTransaction transaction) {
    if (!transaction.write) return;
    _state = transaction.state;
    if (!transaction.silent) {
      for (final name in transaction.changed) {
        _watchers[name]?.add(null);
      }
      for (final entry in transaction.changedObjects.entries) {
        for (final id in entry.value) {
          _objectWatchers['${entry.key}:$id']?.add(null);
        }
      }
    }
  }

  Future<void> commit(EngineTransaction transaction) async {
    if (!transaction.write) return;
    await persist?.call(_copyState(transaction.state));
    publish(transaction);
  }

  Stream<void> watchCollection(String name, bool fireImmediately) {
    final controller =
        _watchers.putIfAbsent(name, StreamController<void>.broadcast);
    if (!fireImmediately) return controller.stream;
    return (() async* {
      yield null;
      yield* controller.stream;
    })();
  }

  Stream<void> watchObject(String name, Id id, bool fireImmediately) {
    final key = '$name:$id';
    final controller =
        _objectWatchers.putIfAbsent(key, StreamController<void>.broadcast);
    if (!fireImmediately) return controller.stream;
    return (() async* {
      yield null;
      yield* controller.stream;
    })();
  }

  String _linkStore(String collection, String link) =>
      '@link:$collection:$link';

  Set<Id> linkedIds(
    EngineTransaction transaction,
    String collection,
    String link,
    Id sourceId,
  ) {
    final record =
        transaction.state[_linkStore(collection, link)]?[sourceId] ?? const {};
    return record.keys.whereType<Id>().toSet();
  }

  void updateLink(
    EngineTransaction transaction,
    String collection,
    String link,
    Id sourceId, {
    required Iterable<Id> add,
    required Iterable<Id> remove,
    required bool reset,
  }) {
    final store = transaction.state.putIfAbsent(
      _linkStore(collection, link),
      () => {},
    );
    final targets = store.putIfAbsent(sourceId, () => {});
    if (reset) targets.clear();
    for (final id in remove) {
      targets.remove(id);
    }
    for (final id in add) {
      targets[id] = true;
    }
    transaction.changed.add(collection);
  }

  @override
  Future<int> getSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) async =>
      getSizeSync(
        includeIndexes: includeIndexes,
        includeLinks: includeLinks,
      );

  @override
  int getSizeSync({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) =>
      _state.values.fold(
        0,
        (total, collection) =>
            total +
            collection.values.fold(
              0,
              (size, value) => size + _estimateValue(value),
            ),
      );

  @override
  Future<void> copyToFile(String targetPath) =>
      Future.error(UnsupportedError('The Dart engine has no filesystem.'));

  @override
  bool performClose(bool deleteFromDisk) {
    _state.clear();
    onClose?.call();
    for (final watcher in _watchers.values) {
      watcher.close();
    }
    for (final watcher in _objectWatchers.values) {
      watcher.close();
    }
    return true;
  }

  @override
  Future<void> verify() async {
    for (final collection in _state.values) {
      for (final entry in collection.entries) {
        if (entry.key == Isar.autoIncrement) {
          throw IsarError('Invalid auto increment id in committed state.');
        }
      }
    }
  }
}

class EngineTransaction extends Transaction {
  EngineTransaction(
    DartEngineIsar isar,
    bool write,
    this.silent,
    this.state, {
    this.release,
  }) : super(isar, true, write);

  final bool silent;
  final EngineState state;
  final Completer<void>? release;
  final changed = <String>{};
  final changedObjects = <String, Set<Id>>{};
  bool _active = true;

  @override
  bool get active => _active;

  @override
  Future<void> abort() async => abortSync();

  @override
  void abortSync() {
    _active = false;
    if (release?.isCompleted == false) release!.complete();
  }

  @override
  Future<void> commit() async {
    if (!_active) throw IsarError('Transaction is no longer active.');
    await (isar as DartEngineIsar).commit(this);
    _active = false;
    if (release?.isCompleted == false) release!.complete();
  }

  @override
  void commitSync() {
    if (!_active) throw IsarError('Transaction is no longer active.');
    if (write && (isar as DartEngineIsar).persist != null) {
      throw UnsupportedError('Persistent transactions must be asynchronous.');
    }
    (isar as DartEngineIsar).publish(this);
    _active = false;
    if (release?.isCompleted == false) release!.complete();
  }
}

class DartEngineCollection<OBJ> extends IsarCollection<OBJ> {
  DartEngineCollection(this.isar, this.schema);

  @override
  final DartEngineIsar isar;
  @override
  final CollectionSchema<OBJ> schema;

  List<int> get _offsets => isar.offsets[OBJ]!;

  Map<Object, dynamic> _serialize(OBJ object) {
    final data = <Object, dynamic>{};
    schema.serialize(object, IsarWriterImpl(data), _offsets, isar.offsets);
    return _deepCopy(data) as Map<Object, dynamic>;
  }

  OBJ _deserialize(Id id, Map<Object, dynamic> data) {
    final object = schema.deserialize(
      id,
      IsarReaderImpl(_deepCopy(data) as Map<Object, dynamic>),
      _offsets,
      isar.offsets,
    );
    schema.attach(this, id, object);
    return object;
  }

  Map<Id, Map<Object, dynamic>> _records(EngineTransaction transaction) =>
      transaction.state[name]!;

  int _counter(EngineTransaction transaction) =>
      transaction.state['@counters']?[schema.id]?[0] as int? ?? 0;

  void _setCounter(EngineTransaction transaction, int value) {
    final counters = transaction.state.putIfAbsent('@counters', () => {});
    counters[schema.id] = {0: value};
  }

  @override
  Future<List<OBJ?>> getAll(List<Id> ids) =>
      isar.getTxn(false, (EngineTransaction transaction) async {
        final records = _records(transaction);
        return ids
            .map((id) =>
                records[id] == null ? null : _deserialize(id, records[id]!))
            .toList();
      });

  @override
  List<OBJ?> getAllSync(List<Id> ids) =>
      isar.getTxnSync(false, (EngineTransaction transaction) {
        final records = _records(transaction);
        return ids
            .map((id) =>
                records[id] == null ? null : _deserialize(id, records[id]!))
            .toList();
      });

  Id _put(EngineTransaction transaction, OBJ object, String? indexName) {
    final records = _records(transaction);
    var id = schema.getId(object);
    if (indexName != null) {
      final existing =
          _findByIndex(records, indexName, _indexKey(object, indexName));
      if (existing != null) id = existing;
    }
    if (id == Isar.autoIncrement) {
      id = _counter(transaction) + 1;
    }
    if (id > _counter(transaction)) {
      _setCounter(transaction, id);
    }
    final data = _serialize(object);
    for (final index in schema.indexes.values.where((index) => index.unique)) {
      final key = _indexKeyData(data, index.name);
      final duplicate = _findByIndex(records, index.name, key);
      if (duplicate != null && duplicate != id) {
        if (index.replace) {
          records.remove(duplicate);
        } else {
          throw IsarUniqueViolationError();
        }
      }
    }
    records[id] = data;
    schema.attach(this, id, object);
    transaction.changed.add(name);
    transaction.changedObjects.putIfAbsent(name, () => {}).add(id);
    return id;
  }

  @override
  Future<List<Id>> putAll(List<OBJ> objects) => putAllByIndex(null, objects);

  @override
  Future<List<Id>> putAllByIndex(String? indexName, List<OBJ> objects) =>
      isar.getTxn(
          true,
          (EngineTransaction transaction) async => objects
              .map((object) => _put(transaction, object, indexName))
              .toList());

  @override
  List<Id> putAllSync(List<OBJ> objects, {bool saveLinks = true}) =>
      putAllByIndexSync(null, objects, saveLinks: saveLinks);

  @override
  List<Id> putAllByIndexSync(
    String? indexName,
    List<OBJ> objects, {
    bool saveLinks = true,
  }) =>
      isar.getTxnSync(true, (EngineTransaction transaction) {
        final ids = objects
            .map((object) => _put(transaction, object, indexName))
            .toList();
        if (saveLinks) {
          for (final object in objects) {
            for (final link in schema.getLinks(object)) {
              link.saveSync();
            }
          }
        }
        return ids;
      });

  IndexKey _indexKey(OBJ object, String indexName) =>
      _indexKeyData(_serialize(object), indexName);

  IndexKey _indexKeyData(Map<Object, dynamic> data, String indexName) {
    final index = schema.index(indexName);
    return index.properties.map((property) {
      var value = _propertyValue(data, property.name);
      if (value is String && !property.caseSensitive) {
        value = value.toLowerCase();
      }
      return value;
    }).toList();
  }

  dynamic _propertyValue(Map<Object, dynamic> data, String propertyName) {
    final property = schema.property(propertyName);
    return schema.deserializeProp(
      IsarReaderImpl(data),
      property.id,
      _offsets[property.id],
      isar.offsets,
    );
  }

  Id? _findByIndex(
    Map<Id, Map<Object, dynamic>> records,
    String indexName,
    IndexKey key,
  ) {
    for (final entry in records.entries) {
      if (_compareKeys(_indexKeyData(entry.value, indexName), key) == 0) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Future<List<OBJ?>> getAllByIndex(String indexName, List<IndexKey> keys) =>
      isar.getTxn(false, (EngineTransaction transaction) async {
        final records = _records(transaction);
        return keys.map((key) {
          final id = _findByIndex(records, indexName, key);
          return id == null ? null : _deserialize(id, records[id]!);
        }).toList();
      });

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List<IndexKey> keys) =>
      isar.getTxnSync(false, (EngineTransaction transaction) {
        final records = _records(transaction);
        return keys.map((key) {
          final id = _findByIndex(records, indexName, key);
          return id == null ? null : _deserialize(id, records[id]!);
        }).toList();
      });

  @override
  Future<int> deleteAll(List<Id> ids) => isar.getTxn(true,
      (EngineTransaction transaction) async => _deleteIds(transaction, ids));

  @override
  int deleteAllSync(List<Id> ids) => isar.getTxnSync(
      true, (EngineTransaction transaction) => _deleteIds(transaction, ids));

  int _deleteIds(EngineTransaction transaction, Iterable<Id> ids) {
    final records = _records(transaction);
    var count = 0;
    for (final id in ids.toSet()) {
      if (records.remove(id) != null) {
        count++;
        transaction.changedObjects.putIfAbsent(name, () => {}).add(id);
      }
    }
    if (count != 0) transaction.changed.add(name);
    return count;
  }

  @override
  Future<int> deleteAllByIndex(String indexName, List<IndexKey> keys) =>
      isar.getTxn(true, (EngineTransaction transaction) async {
        final records = _records(transaction);
        return _deleteIds(
          transaction,
          keys
              .map((key) => _findByIndex(records, indexName, key))
              .whereType<Id>(),
        );
      });

  @override
  int deleteAllByIndexSync(String indexName, List<IndexKey> keys) =>
      isar.getTxnSync(true, (EngineTransaction transaction) {
        final records = _records(transaction);
        return _deleteIds(
          transaction,
          keys
              .map((key) => _findByIndex(records, indexName, key))
              .whereType<Id>(),
        );
      });

  @override
  Future<void> clear() =>
      isar.getTxn(true, (EngineTransaction transaction) async {
        transaction.changedObjects
            .putIfAbsent(name, () => {})
            .addAll(_records(transaction).keys);
        _records(transaction).clear();
        _setCounter(transaction, 0);
        transaction.changed.add(name);
      });

  @override
  void clearSync() => isar.getTxnSync(true, (EngineTransaction transaction) {
        transaction.changedObjects
            .putIfAbsent(name, () => {})
            .addAll(_records(transaction).keys);
        _records(transaction).clear();
        _setCounter(transaction, 0);
        transaction.changed.add(name);
      });

  @override
  Future<int> count() async => (await getAllIds()).length;

  Future<List<Id>> getAllIds() => isar.getTxn(
      false,
      (EngineTransaction transaction) async =>
          _records(transaction).keys.toList());

  @override
  int countSync() => isar.getTxnSync(
        false,
        (EngineTransaction transaction) => _records(transaction).length,
      );

  @override
  Query<T> buildQuery<T>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterOperation? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  }) =>
      DartEngineQuery<T, OBJ>(
        this,
        whereClauses,
        whereDistinct,
        whereSort,
        filter,
        sortBy,
        distinctBy,
        offset,
        limit,
        property,
      );

  @override
  Future<void> importJson(List<Map<String, dynamic>> json) => Future.error(
      UnsupportedError('Typed JSON import requires generated objects.'));

  @override
  void importJsonSync(List<Map<String, dynamic>> json) =>
      throw UnsupportedError('Typed JSON import requires generated objects.');

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes) =>
      importJson((jsonDecode(utf8.decode(jsonBytes)) as List).cast());

  @override
  void importJsonRawSync(Uint8List jsonBytes) =>
      importJsonSync((jsonDecode(utf8.decode(jsonBytes)) as List).cast());

  @override
  Future<int> getSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) async =>
      getSizeSync(includeIndexes: includeIndexes, includeLinks: includeLinks);

  @override
  int getSizeSync({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) =>
      isar.getTxnSync(false, (EngineTransaction transaction) {
        return _records(transaction).values.fold(
              0,
              (size, value) => size + _estimateValue(value),
            );
      });

  @override
  Stream<void> watchLazy({bool fireImmediately = false}) =>
      isar.watchCollection(name, fireImmediately);

  @override
  Stream<OBJ?> watchObject(Id id, {bool fireImmediately = false}) {
    final changes = isar.watchObject(name, id, false).asyncMap((_) => get(id));
    if (!fireImmediately) return changes;
    return (() async* {
      yield await get(id);
      yield* changes;
    })();
  }

  @override
  Stream<void> watchObjectLazy(Id id, {bool fireImmediately = false}) =>
      isar.watchObject(name, id, fireImmediately);

  @override
  Future<void> verify(List<OBJ> objects) async {
    final actual = await getAll(objects.map(schema.getId).toList());
    if (actual.any((object) => object == null)) {
      throw IsarError('Collection contents do not match expected objects.');
    }
  }

  @override
  Future<void> verifyLink(
    String linkName,
    List<int> sourceIds,
    List<int> targetIds,
  ) =>
      Future.error(UnsupportedError('Links are not implemented yet.'));
}

class DartEngineQuery<T, OBJ> extends Query<T> {
  DartEngineQuery(
    this.collection,
    this.whereClauses,
    this.whereDistinct,
    this.whereSort,
    this.filter,
    this.sortBy,
    this.distinctBy,
    this.offset,
    this.limit,
    this.property,
  );

  final DartEngineCollection<OBJ> collection;
  final List<WhereClause> whereClauses;
  final bool whereDistinct;
  final Sort whereSort;
  final FilterOperation? filter;
  final List<SortProperty> sortBy;
  final List<DistinctProperty> distinctBy;
  final int? offset;
  final int? limit;
  final String? property;

  @override
  Isar get isar => collection.isar;

  List<_Result<T>> _results(EngineTransaction transaction) {
    final records = collection._records(transaction);
    var entries = records.entries.where(_matchesWhere).toList();
    entries.sort((a, b) => whereSort == Sort.asc
        ? a.key.compareTo(b.key)
        : b.key.compareTo(a.key));
    if (filter != null) {
      entries = entries
          .where((entry) => _matchesFilter(entry, filter!, transaction))
          .toList();
    }
    if (sortBy.isNotEmpty) {
      entries.sort((a, b) {
        for (final sort in sortBy) {
          final result = _compare(
            _value(a, sort.property),
            _value(b, sort.property),
          );
          if (result != 0) return sort.sort == Sort.asc ? result : -result;
        }
        return a.key.compareTo(b.key);
      });
    }
    final seen = <String>{};
    var results = entries.map((entry) {
      final value = property == null
          ? collection._deserialize(entry.key, entry.value)
          : _value(entry, property!);
      return _Result<T>(entry.key, value as T);
    });
    if (whereDistinct || distinctBy.isNotEmpty) {
      results = results.where((result) {
        final entry = MapEntry(result.id, records[result.id]!);
        final key = distinctBy.isEmpty
            ? result.id.toString()
            : distinctBy.map((d) {
                final value = _value(entry, d.property);
                return d.caseSensitive != false
                    ? value
                    : value.toString().toLowerCase();
              }).join('\u0000');
        return seen.add(key.toString());
      });
    }
    if (offset != null) results = results.skip(offset!);
    if (limit != null) results = results.take(limit!);
    return results.toList();
  }

  bool _matchesWhere(MapEntry<Id, Map<Object, dynamic>> entry) {
    if (whereClauses.isEmpty) return true;
    return whereClauses.any((clause) {
      if (clause is IdWhereClause) {
        return _inRange(
          entry.key,
          clause.lower,
          clause.upper,
          clause.includeLower,
          clause.includeUpper,
        );
      }
      if (clause is IndexWhereClause) {
        final key = collection._indexKeyData(entry.value, clause.indexName);
        return _keyInRange(
          key,
          clause.lower,
          clause.upper,
          clause.includeLower,
          clause.includeUpper,
        );
      }
      if (clause is LinkWhereClause) {
        return collection.isar
            .linkedIds(
              collection.isar.current(false),
              clause.linkCollection,
              clause.linkName,
              clause.id,
            )
            .contains(entry.key);
      }
      return false;
    });
  }

  dynamic _value(MapEntry<Id, Map<Object, dynamic>> entry, String name) {
    if (name == collection.schema.idName) return entry.key;
    return collection._propertyValue(entry.value, name);
  }

  bool _matchesFilter(
    MapEntry<Id, Map<Object, dynamic>> entry,
    FilterOperation operation,
    EngineTransaction transaction,
  ) {
    if (operation is FilterGroup) {
      final values = operation.filters
          .map((child) => _matchesFilter(entry, child, transaction))
          .toList();
      switch (operation.type) {
        case FilterGroupType.and:
          return values.every((value) => value);
        case FilterGroupType.or:
          return values.any((value) => value);
        case FilterGroupType.xor:
          return values.where((value) => value).length == 1;
        case FilterGroupType.not:
          return values.isEmpty || !values.first;
      }
    }
    if (operation is LinkFilter) {
      final ids = collection.isar.linkedIds(
        transaction,
        collection.name,
        operation.linkName,
        entry.key,
      );
      if (operation.filter == null) {
        return ids.length >= operation.lower! && ids.length <= operation.upper!;
      }
      final targetName = collection.schema.link(operation.linkName).target;
      final target = collection.isar.getCollectionByNameInternal(targetName)
          as DartEngineCollection<dynamic>;
      final targetQuery = DartEngineQuery<dynamic, dynamic>(
        target,
        const [],
        false,
        Sort.asc,
        null,
        const [],
        const [],
        null,
        null,
        null,
      );
      final records = target._records(transaction);
      return ids.any((id) {
        final data = records[id];
        return data != null &&
            targetQuery._matchesFilter(
              MapEntry(id, data),
              operation.filter!,
              transaction,
            );
      });
    }
    if (operation is! FilterCondition) return false;
    final raw = _value(entry, operation.property);
    if (operation.type == FilterConditionType.listLength) {
      final length = raw is List ? raw.length : 0;
      return length >= (operation.value1! as int) &&
          length <= (operation.value2! as int);
    }
    if (operation.type == FilterConditionType.isNull) return raw == null;
    if (operation.type == FilterConditionType.isNotNull) return raw != null;
    if (operation.type == FilterConditionType.elementIsNull) {
      return raw is List && raw.contains(null);
    }
    if (operation.type == FilterConditionType.elementIsNotNull) {
      return raw is List && raw.any((value) => value != null);
    }
    final values = raw is List ? raw : [raw];
    return values.any((value) => _matchesValue(value, operation));
  }

  bool _matchesValue(dynamic value, FilterCondition condition) {
    dynamic normalize(dynamic input) {
      if (input is DateTime) return input.toUtc().microsecondsSinceEpoch;
      if (input is String && !condition.caseSensitive)
        return input.toLowerCase();
      return input;
    }

    final actual = normalize(value);
    final first = normalize(condition.value1);
    final second = normalize(condition.value2);
    final comparison = _compare(actual, first);
    switch (condition.type) {
      case FilterConditionType.equalTo:
        if (actual is double && first is double) {
          return actual.isNaN && first.isNaN ||
              (actual - first).abs() <= condition.epsilon;
        }
        return comparison == 0;
      case FilterConditionType.greaterThan:
        return condition.include1 ? comparison >= 0 : comparison > 0;
      case FilterConditionType.lessThan:
        return condition.include1 ? comparison <= 0 : comparison < 0;
      case FilterConditionType.between:
        final lower = condition.include1 ? comparison >= 0 : comparison > 0;
        final upperCompare = _compare(actual, second);
        return lower &&
            (condition.include2 ? upperCompare <= 0 : upperCompare < 0);
      case FilterConditionType.startsWith:
        return actual is String && actual.startsWith(first as String);
      case FilterConditionType.endsWith:
        return actual is String && actual.endsWith(first as String);
      case FilterConditionType.contains:
        return actual is String && actual.contains(first as String);
      case FilterConditionType.matches:
        if (actual is! String || first is! String) return false;
        final pattern = RegExp(
          '^${RegExp.escape(first).replaceAll(r'\*', '.*').replaceAll(r'\?', '.')}\$',
        );
        return pattern.hasMatch(actual);
      default:
        return false;
    }
  }

  @override
  Future<List<T>> findAll() => collection.isar.getTxn(
      false,
      (EngineTransaction transaction) async =>
          _results(transaction).map((result) => result.value).toList());

  @override
  List<T> findAllSync() => collection.isar.getTxnSync(
      false,
      (EngineTransaction transaction) =>
          _results(transaction).map((result) => result.value).toList());

  @override
  Future<T?> findFirst() async => (await findAll()).firstOrNull;

  @override
  T? findFirstSync() => findAllSync().firstOrNull;

  @override
  Future<R?> aggregate<R>(AggregationOp op) async => aggregateSync<R>(op);

  @override
  R? aggregateSync<R>(AggregationOp op) {
    final values = findAllSync();
    if (op == AggregationOp.count) return values.length as R;
    if (op == AggregationOp.isEmpty) return (values.isEmpty ? 1 : 0) as R;
    final nonNull = values.whereType<Object>().toList();
    if (nonNull.isEmpty) return null;
    if (op == AggregationOp.min || op == AggregationOp.max) {
      nonNull.sort(_compare);
      return (op == AggregationOp.min ? nonNull.first : nonNull.last) as R;
    }
    final numbers = nonNull.cast<num>();
    final sum = numbers.fold<num>(0, (total, value) => total + value);
    if (op == AggregationOp.average) return (sum / numbers.length) as R;
    return (R == int ? sum.toInt() : sum.toDouble()) as R;
  }

  @override
  Future<bool> deleteFirst() async => collection.isar.writeTxn(() async {
        final first = await _firstId();
        return first != null && await collection.delete(first);
      });

  @override
  bool deleteFirstSync() => collection.isar.writeTxnSync(() {
        final first = _firstIdSync();
        return first != null && collection.deleteSync(first);
      });

  Future<Id?> _firstId() => collection.isar.getTxn(
      false,
      (EngineTransaction transaction) async =>
          _results(transaction).firstOrNull?.id);

  Id? _firstIdSync() => collection.isar.getTxnSync(false,
      (EngineTransaction transaction) => _results(transaction).firstOrNull?.id);

  @override
  Future<int> deleteAll() =>
      collection.isar.getTxn(true, (EngineTransaction transaction) async {
        final ids = _results(transaction).map((result) => result.id).toList();
        return collection._deleteIds(transaction, ids);
      });

  @override
  int deleteAllSync() =>
      collection.isar.getTxnSync(true, (EngineTransaction transaction) {
        final ids = _results(transaction).map((result) => result.id).toList();
        return collection._deleteIds(transaction, ids);
      });

  @override
  Stream<List<T>> watch({bool fireImmediately = false}) {
    var signature = _watchSignature();
    final changes = collection
        .watchLazy()
        .asyncMap<List<T>?>((_) async {
          final nextSignature = _watchSignature();
          if (nextSignature == signature) return null;
          signature = nextSignature;
          return findAll();
        })
        .where((value) => value != null)
        .cast<List<T>>();
    if (!fireImmediately) return changes;
    return (() async* {
      yield await findAll();
      yield* changes;
    })();
  }

  @override
  Stream<void> watchLazy({bool fireImmediately = false}) =>
      watch(fireImmediately: fireImmediately).map((_) {});

  String _watchSignature() => collection.isar.getTxnSync(
        false,
        (EngineTransaction transaction) {
          final records = collection._records(transaction);
          return _results(transaction)
              .map((result) => '${result.id}:${records[result.id]}')
              .join('|');
        },
      );

  Map<String, dynamic> _json(_Result<T> result) {
    final data = collection.isar.getTxnSync(
      false,
      (EngineTransaction transaction) =>
          collection._records(transaction)[result.id]!,
    );
    return {
      collection.schema.idName: result.id,
      for (final property in collection.schema.properties.values)
        property.name: collection._propertyValue(data, property.name),
    };
  }

  @override
  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback) async =>
      exportJsonRawSync(callback);

  @override
  R exportJsonRawSync<R>(R Function(Uint8List) callback) {
    final results = collection.isar.getTxnSync(
      false,
      (EngineTransaction transaction) => _results(transaction),
    );
    return callback(Uint8List.fromList(
        utf8.encode(jsonEncode(results.map(_json).toList()))));
  }
}

class _Result<T> {
  const _Result(this.id, this.value);
  final Id id;
  final T value;
}

List<int> _offsets(Schema<dynamic> schema) {
  if (schema.properties.isEmpty) return const [0];
  final max = schema.properties.values
      .map((property) => property.id)
      .reduce((a, b) => a > b ? a : b);
  return List.generate(max + 2, (index) => index);
}

EngineState _copyState(EngineState state) => {
      for (final collection in state.entries)
        collection.key: {
          for (final object in collection.value.entries)
            object.key: _deepCopy(object.value) as Map<Object, dynamic>,
        },
    };

dynamic _deepCopy(dynamic value) {
  if (value is Map) {
    return <Object, dynamic>{
      for (final entry in value.entries)
        entry.key as Object: _deepCopy(entry.value),
    };
  }
  if (value is List) return value.map(_deepCopy).toList();
  if (value is DateTime)
    return DateTime.fromMicrosecondsSinceEpoch(value.microsecondsSinceEpoch,
        isUtc: value.isUtc);
  if (value is Uint8List) return Uint8List.fromList(value);
  return value;
}

int _estimateValue(dynamic value) {
  if (value == null) return 0;
  if (value is bool) return 1;
  if (value is num || value is DateTime) return 8;
  if (value is String) return utf8.encode(value).length;
  if (value is Uint8List) return value.length;
  if (value is Iterable) {
    return value.fold(0, (size, item) => size + _estimateValue(item));
  }
  if (value is Map) {
    return value.values.fold(0, (size, item) => size + _estimateValue(item));
  }
  return utf8.encode(value.toString()).length;
}

int _compare(dynamic a, dynamic b) {
  if (identical(a, b)) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  if (a is num && b is num) {
    if (a.isNaN) return b.isNaN ? 0 : -1;
    if (b.isNaN) return 1;
    return a.compareTo(b);
  }
  if (a is DateTime && b is DateTime) return a.compareTo(b);
  if (a is bool && b is bool) return a == b ? 0 : (a ? 1 : -1);
  if (a is String && b is String) return a.compareTo(b);
  return a.toString().compareTo(b.toString());
}

int _compareKeys(IndexKey a, IndexKey b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    final result = _compare(a[i], b[i]);
    if (result != 0) return result;
  }
  return a.length.compareTo(b.length);
}

bool _inRange(
  dynamic value,
  dynamic lower,
  dynamic upper,
  bool includeLower,
  bool includeUpper,
) =>
    (lower == null ||
        (includeLower
            ? _compare(value, lower) >= 0
            : _compare(value, lower) > 0)) &&
    (upper == null ||
        (includeUpper
            ? _compare(value, upper) <= 0
            : _compare(value, upper) < 0));

bool _keyInRange(
  IndexKey value,
  IndexKey? lower,
  IndexKey? upper,
  bool includeLower,
  bool includeUpper,
) =>
    (lower == null ||
        (includeLower
            ? _compareKeys(value, lower) >= 0
            : _compareKeys(value, lower) > 0)) &&
    (upper == null ||
        (includeUpper
            ? _compareKeys(value, upper) <= 0
            : _compareKeys(value, upper) < 0));

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
