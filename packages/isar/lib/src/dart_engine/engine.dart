// ignore_for_file: invalid_use_of_protected_member, public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_common.dart';
import 'package:isar/src/common/isar_link_backend.dart';
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
    if (initialState != null) {
      for (final entry in initialState.entries) {
        if (entry.key.startsWith('@')) {
          _state[entry.key] = entry.value;
        }
      }
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
  final FutureOr<void> Function(bool deleteFromDisk)? onClose;
  Future<void> _writeTail = Future.value();
  final _watchers = <String, StreamController<void>>{};
  final _objectWatchers = <String, StreamController<void>>{};

  @override
  String? get directory => null;

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

  DartEngineCollection<dynamic> _collection(String name) =>
      getCollectionByNameInternal(name) as DartEngineCollection<dynamic>;

  Set<Id> linkedIds(
    EngineTransaction transaction,
    String collection,
    String link,
    Id sourceId,
  ) {
    final source = _collection(collection);
    final schema = source.schema.link(link);
    if (!schema.isBacklink) {
      final record = transaction.state[_linkStore(collection, link)]
              ?[sourceId] ??
          const {};
      return record.keys.whereType<Id>().toSet();
    }
    final result = <Id>{};
    final store =
        transaction.state[_linkStore(schema.target, schema.linkName!)] ??
            const {};
    for (final entry in store.entries) {
      if (entry.value.containsKey(sourceId)) result.add(entry.key);
    }
    return result;
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
    final source = _collection(collection);
    final schema = source.schema.link(link);
    if (schema.isBacklink) {
      final store = transaction.state.putIfAbsent(
        _linkStore(schema.target, schema.linkName!),
        () => {},
      );
      if (reset) {
        for (final targets in store.values) {
          targets.remove(sourceId);
        }
      }
      for (final id in remove) {
        store[id]?.remove(sourceId);
      }
      for (final id in add) {
        store.putIfAbsent(id, () => {})[sourceId] = true;
      }
      transaction.changed
        ..add(collection)
        ..add(schema.target);
      transaction.changedObjects
          .putIfAbsent(collection, () => {})
          .add(sourceId);
      return;
    }
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
      if (schema.single) targets.clear();
      targets[id] = true;
    }
    transaction.changed.add(collection);
    transaction.changedObjects.putIfAbsent(collection, () => {}).add(sourceId);
  }

  void cleanupLinks(
    EngineTransaction transaction,
    String collection,
    Id id,
  ) {
    for (final entry in transaction.state.entries) {
      if (!entry.key.startsWith('@link:')) continue;
      final parts = entry.key.split(':');
      if (parts.length < 3) continue;
      final sourceCollection = parts[1];
      final linkName = parts.sublist(2).join(':');
      if (sourceCollection == collection) {
        entry.value.remove(id);
      }
      final link = _collection(sourceCollection).schema.link(linkName);
      if (link.target == collection) {
        for (final targets in entry.value.values) {
          targets.remove(id);
        }
      }
    }
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
  Future<bool> performClose(bool deleteFromDisk) async {
    _state.clear();
    await onClose?.call(deleteFromDisk);
    for (final watcher in _watchers.values) {
      await watcher.close();
    }
    for (final watcher in _objectWatchers.values) {
      await watcher.close();
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

class DartEngineCollection<OBJ> extends IsarCollection<OBJ>
    implements IsarLinkBackend {
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
    final keys = [..._indexKeysData(data, indexName)];
    if (keys.isEmpty) return const [];
    keys.sort(_compareKeys);
    return keys.first;
  }

  List<IndexKey> _indexKeysData(
    Map<Object, dynamic> data,
    String indexName,
  ) {
    final index = schema.index(indexName);
    if (index.properties.length == 1) {
      final indexProperty = index.properties.first;
      final property = schema.property(indexProperty.name);
      final value = _propertyValue(data, indexProperty.name);
      if (property.type.isList && indexProperty.type != IndexType.hash) {
        if (value == null) return const [];
        if (value is! List || value.isEmpty) return const [];
        return value.map((element) {
          dynamic normalized = element;
          if (normalized is String && !indexProperty.caseSensitive) {
            normalized = normalized.toLowerCase();
          }
          return <dynamic>[normalized];
        }).toList();
      }
    }
    return [
      index.properties.map((property) {
        var value = _propertyValue(data, property.name);
        if (value is String && !property.caseSensitive) {
          value = value.toLowerCase();
        }
        return value;
      }).toList(),
    ];
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

  IndexKey? _normalizeIndexKey(String indexName, IndexKey? key) {
    if (key == null) return null;
    final properties = schema.index(indexName).properties;
    return [
      for (var i = 0; i < key.length; i++)
        key[i] is String &&
                i < properties.length &&
                !properties[i].caseSensitive
            ? (key[i] as String).toLowerCase()
            : key[i],
    ];
  }

  Id? _findByIndex(
    Map<Id, Map<Object, dynamic>> records,
    String indexName,
    IndexKey key,
  ) {
    final normalizedKey = _normalizeIndexKey(indexName, key)!;
    for (final entry in records.entries) {
      if (_indexKeysData(entry.value, indexName).any(
        (candidate) => _compareKeyToBound(candidate, normalizedKey) == 0,
      )) {
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
        isar.cleanupLinks(transaction, name, id);
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
        final ids = _records(transaction).keys.toList();
        transaction.changedObjects.putIfAbsent(name, () => {}).addAll(ids);
        _records(transaction).clear();
        for (final id in ids) {
          isar.cleanupLinks(transaction, name, id);
        }
        _setCounter(transaction, 0);
        transaction.changed.add(name);
      });

  @override
  void clearSync() => isar.getTxnSync(true, (EngineTransaction transaction) {
        final ids = _records(transaction).keys.toList();
        transaction.changedObjects.putIfAbsent(name, () => {}).addAll(ids);
        _records(transaction).clear();
        for (final id in ids) {
          isar.cleanupLinks(transaction, name, id);
        }
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
  Future<void> importJson(List<Map<String, dynamic>> json) =>
      isar.getTxn(true, (EngineTransaction transaction) async {
        _importJson(transaction, json);
      });

  @override
  void importJsonSync(List<Map<String, dynamic>> json) =>
      isar.getTxnSync(true, (EngineTransaction transaction) {
        _importJson(transaction, json);
      });

  void _importJson(
    EngineTransaction transaction,
    List<Map<String, dynamic>> objects,
  ) {
    final records = _records(transaction);
    for (final object in objects) {
      var id = object[schema.idName] as int? ?? Isar.autoIncrement;
      if (id == Isar.autoIncrement) id = _counter(transaction) + 1;
      if (id > _counter(transaction)) _setCounter(transaction, id);
      final data = _encodeJsonObject(schema, object);
      data['@json'] = _deepCopy(object);
      for (final index
          in schema.indexes.values.where((index) => index.unique)) {
        final duplicate = _findByIndex(
          records,
          index.name,
          _indexKeyData(data, index.name),
        );
        if (duplicate != null && duplicate != id) {
          if (index.replace) {
            records.remove(duplicate);
          } else {
            throw IsarUniqueViolationError();
          }
        }
      }
      records[id] = data;
      transaction.changed.add(name);
      transaction.changedObjects.putIfAbsent(name, () => {}).add(id);
    }
  }

  Map<Object, dynamic> _encodeJsonObject(
    Schema<dynamic> objectSchema,
    Map<String, dynamic> json,
  ) {
    final offsets = isar.offsets[objectSchema.type]!;
    return {
      for (final property in objectSchema.properties.values)
        offsets[property.id]:
            _encodeJsonProperty(property, json[property.name]),
    };
  }

  dynamic _encodeJsonProperty(PropertySchema property, dynamic value) {
    if (value == null) return null;
    if (property.type == IsarType.object) {
      final embedded = schema.embeddedSchemas[property.target]!;
      return _encodeJsonObject(embedded, (value as Map).cast());
    }
    if (property.type == IsarType.objectList) {
      final embedded = schema.embeddedSchemas[property.target]!;
      return (value as List)
          .map((item) => item == null
              ? null
              : _encodeJsonObject(embedded, (item as Map).cast()))
          .toList();
    }
    if (property.type == IsarType.bool) return value == true ? 1 : 0;
    if (property.type == IsarType.boolList) {
      return (value as List)
          .map((item) => item == null ? null : (item == true ? 1 : 0))
          .toList();
    }
    if (property.type.scalarType == IsarType.dateTime) {
      dynamic encode(dynamic item) => item == null
          ? null
          : item is int
              ? item
              : (item is DateTime ? item : DateTime.parse(item as String))
                  .toUtc()
                  .microsecondsSinceEpoch;
      return property.type.isList
          ? (value as List).map(encode).toList()
          : encode(value);
    }
    if (property.type.scalarType == IsarType.float) {
      dynamic encode(dynamic item) => item == null
          ? null
          : (Float32List(1)..[0] = (item as num).toDouble())[0];
      return property.type.isList
          ? (value as List).map(encode).toList()
          : encode(value);
    }
    return _deepCopy(value);
  }

  Map<String, dynamic> _decodeJsonObject(
    Schema<dynamic> objectSchema,
    Map<Object, dynamic> data,
  ) {
    final offsets = isar.offsets[objectSchema.type]!;
    return {
      for (final property in objectSchema.properties.values)
        property.name: _decodeJsonProperty(
          property,
          data[offsets[property.id]],
        ),
    };
  }

  dynamic _decodeJsonProperty(PropertySchema property, dynamic value) {
    if (value == null) return null;
    if (property.type == IsarType.object) {
      return _decodeJsonObject(
        schema.embeddedSchemas[property.target]!,
        value as Map<Object, dynamic>,
      );
    }
    if (property.type == IsarType.objectList) {
      final embedded = schema.embeddedSchemas[property.target]!;
      return (value as List)
          .map((item) => item == null
              ? null
              : _decodeJsonObject(
                  embedded,
                  item as Map<Object, dynamic>,
                ))
          .toList();
    }
    if (property.type == IsarType.bool) return value == 1;
    if (property.type == IsarType.boolList) {
      return (value as List)
          .map((item) => item == null ? null : item == 1)
          .toList();
    }
    return _deepCopy(value);
  }

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes) async {
    try {
      final decoded = jsonDecode(utf8.decode(jsonBytes));
      if (decoded is! List) throw const FormatException('Expected a list.');
      await importJson(decoded.cast());
    } catch (error) {
      throw IsarError('Invalid JSON: $error');
    }
  }

  @override
  void importJsonRawSync(Uint8List jsonBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(jsonBytes));
      if (decoded is! List) throw const FormatException('Expected a list.');
      importJsonSync(decoded.cast());
    } catch (error) {
      throw IsarError('Invalid JSON: $error');
    }
  }

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
        final records = _records(transaction);
        var size = records.values.fold(
          0,
          (total, value) => total + _estimateValue(value),
        );
        if (includeIndexes) {
          for (final record in records.values) {
            for (final index in schema.indexes.values) {
              size += _indexKeysData(record, index.name).length * 16;
            }
          }
        }
        if (includeLinks) {
          for (final link in schema.links.values.where(
            (link) => !link.isBacklink,
          )) {
            for (final id in records.keys) {
              size +=
                  isar.linkedIds(transaction, name, link.name, id).length * 16;
            }
          }
        }
        return size;
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
  Future<void> updateLinkBackend<T>({
    required IsarCollection<T> targetCollection,
    required String linkName,
    required Id sourceId,
    required Iterable<T> link,
    required Iterable<T> unlink,
    required bool reset,
  }) async {
    final target = targetCollection as DartEngineCollection<T>;
    await isar.getTxn(true, (EngineTransaction transaction) async {
      final add = <Id>[];
      for (final object in link) {
        var id = target.schema.getId(object);
        if (id == Isar.autoIncrement) id = await target.put(object);
        add.add(id);
      }
      isar.updateLink(
        transaction,
        name,
        linkName,
        sourceId,
        add: add,
        remove: unlink.map(target.schema.getId),
        reset: reset,
      );
    });
  }

  @override
  void updateLinkBackendSync<T>({
    required IsarCollection<T> targetCollection,
    required String linkName,
    required Id sourceId,
    required Iterable<T> link,
    required Iterable<T> unlink,
    required bool reset,
  }) {
    final target = targetCollection as DartEngineCollection<T>;
    isar.getTxnSync(true, (EngineTransaction transaction) {
      final add = <Id>[];
      for (final object in link) {
        var id = target.schema.getId(object);
        if (id == Isar.autoIncrement) id = target.putSync(object);
        add.add(id);
      }
      isar.updateLink(
        transaction,
        name,
        linkName,
        sourceId,
        add: add,
        remove: unlink.map(target.schema.getId),
        reset: reset,
      );
    });
  }

  @override
  Future<void> verifyLink(
    String linkName,
    List<int> sourceIds,
    List<int> targetIds,
  ) =>
      isar.getTxn(false, (EngineTransaction transaction) async {
        if (sourceIds.length != targetIds.length) {
          throw IsarError('Source and target link ids must have equal length.');
        }
        final expected = <String>{
          for (var i = 0; i < sourceIds.length; i++)
            '${sourceIds[i]}:${targetIds[i]}',
        };
        final actual = <String>{};
        for (final sourceId in _records(transaction).keys) {
          for (final targetId
              in isar.linkedIds(transaction, name, linkName, sourceId)) {
            actual.add('$sourceId:$targetId');
          }
        }
        if (!_setEquals(actual, expected)) {
          throw IsarError('Link contents do not match expected ids.');
        }
      });
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
    var entries = records.entries
        .where((entry) => _matchesWhere(entry, transaction))
        .toList();
    final indexWhere = whereClauses.whereType<IndexWhereClause>().firstOrNull;
    entries.sort((a, b) {
      var result = indexWhere == null
          ? a.key.compareTo(b.key)
          : _compareKeys(
              collection._indexKeyData(a.value, indexWhere.indexName),
              collection._indexKeyData(b.value, indexWhere.indexName),
            );
      if (result == 0) result = a.key.compareTo(b.key);
      return whereSort == Sort.asc ? result : -result;
    });
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
            ? indexWhere == null
                ? result.id.toString()
                : collection
                    ._indexKeyData(entry.value, indexWhere.indexName)
                    .toString()
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

  bool _matchesWhere(
    MapEntry<Id, Map<Object, dynamic>> entry,
    EngineTransaction transaction,
  ) {
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
        final index = collection.schema.index(clause.indexName);
        if (index.properties.length == 1) {
          final indexProperty = index.properties.first;
          final property = collection.schema.property(indexProperty.name);
          final value = collection._propertyValue(
            entry.value,
            indexProperty.name,
          );
          if (property.type.isList &&
              indexProperty.type != IndexType.hash &&
              value == null) {
            return false;
          }
        }
        return collection
            ._indexKeysData(entry.value, clause.indexName)
            .any((key) => _keyInRange(
                  key,
                  collection._normalizeIndexKey(
                    clause.indexName,
                    clause.lower,
                  ),
                  collection._normalizeIndexKey(
                    clause.indexName,
                    clause.upper,
                  ),
                  clause.includeLower,
                  clause.includeUpper,
                ));
      }
      if (clause is LinkWhereClause) {
        return collection.isar
            .linkedIds(
              transaction,
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
          return values.isEmpty || values.any((value) => value);
        case FilterGroupType.xor:
          return values.where((value) => value).length == 1;
        case FilterGroupType.not:
          return values.isEmpty ||
              operation.filters.first is FilterGroup &&
                  (operation.filters.first as FilterGroup).filters.isEmpty ||
              !values.first;
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
    if (operation is ObjectFilter) {
      final property = collection.schema.property(operation.property);
      final raw = entry.value[collection._offsets[property.id]];
      final target = collection.schema.embeddedSchemas[property.target]!;
      bool matches(dynamic value) =>
          value is Map<Object, dynamic> &&
          _matchesEmbedded(target, value, operation.filter);
      return raw is List ? raw.any(matches) : matches(raw);
    }
    if (operation is! FilterCondition) return false;
    final propertyType = operation.property == collection.schema.idName
        ? IsarType.long
        : collection.schema.property(operation.property).type;
    final raw = _value(entry, operation.property);
    return _matchesCondition(raw, operation, propertyType);
  }

  bool _matchesEmbedded(
    Schema<dynamic> schema,
    Map<Object, dynamic> data,
    FilterOperation operation,
  ) {
    if (operation is FilterGroup) {
      final values = operation.filters
          .map((child) => _matchesEmbedded(schema, data, child))
          .toList();
      switch (operation.type) {
        case FilterGroupType.and:
          return values.every((value) => value);
        case FilterGroupType.or:
          return values.isEmpty || values.any((value) => value);
        case FilterGroupType.xor:
          return values.where((value) => value).length == 1;
        case FilterGroupType.not:
          return values.isEmpty ||
              operation.filters.first is FilterGroup &&
                  (operation.filters.first as FilterGroup).filters.isEmpty ||
              !values.first;
      }
    }
    if (operation is ObjectFilter) {
      final property = schema.property(operation.property);
      final raw = data[collection.isar.offsets[schema.type]![property.id]];
      final target = collection.schema.embeddedSchemas[property.target]!;
      bool matches(dynamic value) =>
          value is Map<Object, dynamic> &&
          _matchesEmbedded(target, value, operation.filter);
      return raw is List ? raw.any(matches) : matches(raw);
    }
    if (operation is! FilterCondition) return false;
    final property = schema.property(operation.property);
    final raw = schema.deserializeProp(
      IsarReaderImpl(data),
      property.id,
      collection.isar.offsets[schema.type]![property.id],
      collection.isar.offsets,
    );
    return _matchesCondition(raw, operation, property.type);
  }

  bool _matchesCondition(
    dynamic raw,
    FilterCondition operation,
    IsarType propertyType,
  ) {
    if (operation.type == FilterConditionType.listLength) {
      if (raw is! List) return false;
      final length = raw.length;
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
    if (propertyType.isList && raw == null) return false;
    final values = raw is List ? raw : [raw];
    return values.any(
      (value) => _matchesValue(
        value,
        operation,
        propertyType.scalarType == IsarType.float,
      ),
    );
  }

  bool _matchesValue(
    dynamic value,
    FilterCondition condition,
    bool float32,
  ) {
    dynamic normalize(dynamic input) {
      if (input is DateTime) return input.toUtc().microsecondsSinceEpoch;
      if (input is String && !condition.caseSensitive)
        return input.toLowerCase();
      if (float32 && input is double) {
        return (Float32List(1)..[0] = input)[0];
      }
      return input;
    }

    final actual = normalize(value);
    final first = normalize(condition.value1);
    final second = normalize(condition.value2);
    final comparison = _compare(actual, first);
    switch (condition.type) {
      case FilterConditionType.equalTo:
        if (actual is double && first is double) {
          return actual == first ||
              actual.isNaN && first.isNaN ||
              (actual - first).abs() <= condition.epsilon;
        }
        return comparison == 0;
      case FilterConditionType.greaterThan:
        if (actual is double && first is double && condition.epsilon != 0) {
          final threshold = condition.include1
              ? first - condition.epsilon
              : first + condition.epsilon;
          return condition.include1 ? actual >= threshold : actual > threshold;
        }
        return condition.include1 ? comparison >= 0 : comparison > 0;
      case FilterConditionType.lessThan:
        if (actual is double && first is double && condition.epsilon != 0) {
          final threshold = condition.include1
              ? first + condition.epsilon
              : first - condition.epsilon;
          return condition.include1 ? actual <= threshold : actual < threshold;
        }
        return condition.include1 ? comparison <= 0 : comparison < 0;
      case FilterConditionType.between:
        if (actual is double &&
            first is double &&
            second is double &&
            condition.epsilon != 0) {
          final lower = condition.include1
              ? actual >= first - condition.epsilon
              : actual > first + condition.epsilon;
          final upper = condition.include2
              ? actual <= second + condition.epsilon
              : actual < second - condition.epsilon;
          return lower && upper;
        } else {
          final lower = condition.include1 ? comparison >= 0 : comparison > 0;
          final upperCompare = _compare(actual, second);
          return lower &&
              (condition.include2 ? upperCompare <= 0 : upperCompare < 0);
        }
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
  Future<R?> aggregate<R>(AggregationOp op) => collection.isar.getTxn(
        false,
        (EngineTransaction transaction) async => _aggregate<R>(
            _results(transaction).map((result) => result.value), op),
      );

  @override
  R? aggregateSync<R>(AggregationOp op) => collection.isar.getTxnSync(
        false,
        (EngineTransaction transaction) => _aggregate<R>(
            _results(transaction).map((result) => result.value), op),
      );

  R? _aggregate<R>(Iterable<T> iterable, AggregationOp op) {
    final values = iterable.toList();
    if (op == AggregationOp.count) return values.length as R;
    if (op == AggregationOp.isEmpty) return (values.isEmpty ? 1 : 0) as R;
    final nonNull = values.whereType<Object>().toList();
    if (nonNull.isEmpty) {
      if (op == AggregationOp.sum) {
        return (R == int ? 0 : 0.0) as R;
      }
      if (op == AggregationOp.average) return double.nan as R;
      return null;
    }
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
  Future<bool> deleteFirst() => collection.isar.getTxn(
        true,
        (EngineTransaction transaction) async {
          final first = _results(transaction).firstOrNull?.id;
          return first != null &&
              collection._deleteIds(transaction, [first]) == 1;
        },
      );

  @override
  bool deleteFirstSync() => collection.isar.getTxnSync(
        true,
        (EngineTransaction transaction) {
          final first = _results(transaction).firstOrNull?.id;
          return first != null &&
              collection._deleteIds(transaction, [first]) == 1;
        },
      );

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
    final original = data['@json'];
    if (original is Map) {
      final json = Map<String, dynamic>.from(original);
      json[collection.schema.idName] = result.id;
      return json;
    }
    return {
      collection.schema.idName: result.id,
      ...collection._decodeJsonObject(collection.schema, data),
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
    return callback(
      Uint8List.fromList(utf8.encode(jsonEncode(results.map(_json).toList()))),
    );
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

bool _setEquals<T>(Set<T> first, Set<T> second) =>
    first.length == second.length && first.containsAll(second);

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
  if (a is List && b is List) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      final result = _compare(a[i], b[i]);
      if (result != 0) return result;
    }
    return a.length.compareTo(b.length);
  }
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
        lower.isEmpty ||
        (includeLower
            ? _compareKeyToBound(value, lower) >= 0
            : _compareKeyToBound(value, lower) > 0)) &&
    (upper == null ||
        upper.isEmpty ||
        (includeUpper
            ? _compareKeyToBound(value, upper) <= 0
            : _compareKeyToBound(value, upper) < 0));

int _compareKeyToBound(IndexKey key, IndexKey bound) {
  for (var i = 0; i < key.length && i < bound.length; i++) {
    final result = _compare(key[i], bound[i]);
    if (result != 0) return result;
  }
  if (bound.length <= key.length) return 0;
  return -1;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
