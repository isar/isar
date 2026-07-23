// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:isar/isar.dart';
import 'package:isar/src/dart_engine/engine.dart';
import 'package:web/web.dart';

const _metaStore = '@meta';
const _linksStore = '@links';
const _countersStore = '@counters';
const _legacyStore = 'state';
const _schemaKey = 'schema';
const _revisionKey = 'revision';

String _collectionStore(String name) => 'collection:$name';

Future<Isar> openIsar({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
}) async {
  final lease = await _acquireLease(name);
  IDBDatabase? database;
  var handedOff = false;
  try {
    database = await _openDatabase(name, schemas);
    final expectedSchema =
        jsonEncode(schemas.map((schema) => schema.toJson()).toList());
    final storedSchema = await _readString(database, _metaStore, _schemaKey);
    if (storedSchema != null &&
        !_schemasCompatible(storedSchema, expectedSchema)) {
      throw IsarError(
        'The existing web schema contains an incompatible property change.',
      );
    }

    var revision = int.tryParse(
          await _readString(database, _metaStore, _revisionKey) ?? '',
        ) ??
        0;
    var state = await _readState(database, schemas);
    if (state == null && database.objectStoreNames.contains(_legacyStore)) {
      final snapshot = await _readString(database, _legacyStore, 'snapshot');
      if (snapshot != null) state = _decodeState(snapshot);
    }
    state ??= {};
    if (storedSchema != null && storedSchema != expectedSchema) {
      state = _migrateState(state, storedSchema, schemas);
    }

    if (storedSchema == null || storedSchema != expectedSchema) {
      await _writeState(
        database,
        schemas,
        state,
        revision,
        expectedSchema,
        checkRevision: storedSchema != null,
      );
      revision++;
    }

    final ownedDatabase = database;
    handedOff = true;
    return DartEngineIsar(
      name,
      schemas,
      initialState: state,
      persist: (nextState) async {
        await _writeState(
          ownedDatabase,
          schemas,
          nextState,
          revision,
          expectedSchema,
          checkRevision: true,
        );
        revision++;
      },
      onClose: (deleteFromDisk) async {
        ownedDatabase.close();
        lease.close();
        if (deleteFromDisk) await _deleteDatabase(name);
      },
    );
  } finally {
    if (!handedOff) {
      database?.close();
      lease.close();
    }
  }
}

Isar openIsarSync({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
}) {
  throw UnsupportedError('Synchronous Isar.open is not supported on web.');
}

List<String> _stores(List<CollectionSchema<dynamic>> schemas) => [
      _metaStore,
      _linksStore,
      _countersStore,
      for (final schema in schemas) _collectionStore(schema.name),
    ];

Future<IDBDatabase> _openDatabase(
  String name,
  List<CollectionSchema<dynamic>> schemas,
) async {
  var database = await _openRequest(name, null, schemas);
  final missing = _stores(schemas)
      .where((store) => !database.objectStoreNames.contains(store));
  if (missing.isEmpty) return database;
  final version = database.version + 1;
  database.close();
  database = await _openRequest(name, version, schemas);
  return database;
}

Future<IDBDatabase> _openRequest(
  String name,
  int? version,
  List<CollectionSchema<dynamic>> schemas,
) {
  final completer = Completer<IDBDatabase>();
  final request = version == null
      ? window.indexedDB.open('isar-$name')
      : window.indexedDB.open('isar-$name', version);
  request.onupgradeneeded = ((Event event) {
    final database = request.result as IDBDatabase;
    for (final store in _stores(schemas)) {
      if (!database.objectStoreNames.contains(store)) {
        database.createObjectStore(store);
      }
    }
  }).toJS;
  request.onsuccess = ((Event event) {
    final database = request.result as IDBDatabase;
    database.onversionchange = ((Event event) => database.close()).toJS;
    if (!completer.isCompleted) completer.complete(database);
  }).toJS;
  request.onerror = ((Event event) {
    if (!completer.isCompleted) {
      completer.completeError(
        IsarError(request.error?.message ?? 'Failed to open IndexedDB.'),
      );
    }
  }).toJS;
  request.onblocked = ((Event event) {
    if (!completer.isCompleted) {
      completer.completeError(
        IsarError('IndexedDB open was blocked by another tab.'),
      );
    }
  }).toJS;
  return completer.future;
}

Future<EngineState?> _readState(
  IDBDatabase database,
  List<CollectionSchema<dynamic>> schemas,
) async {
  final state = <String, Map<Id, Map<Object, dynamic>>>{};
  var found = false;
  for (final schema in schemas) {
    final values =
        await _readAllStrings(database, _collectionStore(schema.name));
    final records = <Id, Map<Object, dynamic>>{};
    for (final value in values) {
      final record = jsonDecode(value) as Map<String, dynamic>;
      records[record['id'] as int] =
          _integerKeys(record['data']) as Map<Object, dynamic>;
    }
    state[schema.name] = records;
    found |= records.isNotEmpty;
  }
  for (final value in await _readAllStrings(database, _linksStore)) {
    final record = jsonDecode(value) as Map<String, dynamic>;
    state.putIfAbsent(
            record['store'] as String, () => {})[record['id'] as int] =
        _integerKeys(record['data']) as Map<Object, dynamic>;
    found = true;
  }
  final counters = <Id, Map<Object, dynamic>>{};
  for (final value in await _readAllStrings(database, _countersStore)) {
    final record = jsonDecode(value) as Map<String, dynamic>;
    counters[record['id'] as int] =
        _integerKeys(record['data']) as Map<Object, dynamic>;
    found = true;
  }
  if (counters.isNotEmpty) state['@counters'] = counters;
  return found ? state : null;
}

Future<void> _writeState(
  IDBDatabase database,
  List<CollectionSchema<dynamic>> schemas,
  EngineState state,
  int expectedRevision,
  String schemaJson, {
  required bool checkRevision,
}) async {
  final names = _stores(schemas);
  final transaction = database.transaction(
    names.map((name) => name.toJS).toList().toJS,
    'readwrite',
  );
  final meta = transaction.objectStore(_metaStore);
  if (checkRevision) {
    final result = await _request(meta.get(_revisionKey.toJS));
    final actual = result == null ? 0 : int.parse((result as JSString).toDart);
    if (actual != expectedRevision) {
      transaction.abort();
      throw IsarError(
        'IndexedDB revision changed from $expectedRevision to $actual.',
      );
    }
  }

  for (final schema in schemas) {
    final store = transaction.objectStore(_collectionStore(schema.name));
    store.clear();
    for (final record in (state[schema.name] ?? const {}).entries) {
      store.put(
        jsonEncode({
          'id': record.key,
          'data': _stringifyKeys(record.value),
        }).toJS,
        record.key.toString().toJS,
      );
    }
  }

  final links = transaction.objectStore(_linksStore);
  links.clear();
  for (final collection in state.entries.where(
    (entry) => entry.key.startsWith('@link:'),
  )) {
    for (final record in collection.value.entries) {
      links.put(
        jsonEncode({
          'store': collection.key,
          'id': record.key,
          'data': _stringifyKeys(record.value),
        }).toJS,
        '${collection.key}:${record.key}'.toJS,
      );
    }
  }

  final counters = transaction.objectStore(_countersStore);
  counters.clear();
  for (final record in (state['@counters'] ?? const {}).entries) {
    counters.put(
      jsonEncode({
        'id': record.key,
        'data': _stringifyKeys(record.value),
      }).toJS,
      record.key.toString().toJS,
    );
  }
  meta.put(schemaJson.toJS, _schemaKey.toJS);
  meta.put((expectedRevision + 1).toString().toJS, _revisionKey.toJS);
  await _transaction(transaction);
}

Future<String?> _readString(
  IDBDatabase database,
  String storeName,
  String key,
) async {
  final transaction = database.transaction(storeName.toJS, 'readonly');
  final result =
      await _request(transaction.objectStore(storeName).get(key.toJS));
  return result == null ? null : (result as JSString).toDart;
}

Future<List<String>> _readAllStrings(
  IDBDatabase database,
  String storeName,
) async {
  final transaction = database.transaction(storeName.toJS, 'readonly');
  final result = await _request(transaction.objectStore(storeName).getAll());
  if (result == null) return const [];
  return (result as JSArray<JSAny?>)
      .toDart
      .map((value) => (value as JSString).toDart)
      .toList();
}

Future<void> _deleteDatabase(String name) {
  final completer = Completer<void>();
  final request = window.indexedDB.deleteDatabase('isar-$name');
  request.onsuccess = ((Event event) => completer.complete()).toJS;
  request.onerror = ((Event event) => completer.completeError(
        IsarError(request.error?.message ?? 'Failed to delete IndexedDB.'),
      )).toJS;
  request.onblocked = ((Event event) => completer.completeError(
        IsarError('IndexedDB deletion was blocked by another tab.'),
      )).toJS;
  return completer.future;
}

Future<BroadcastChannel> _acquireLease(String name) async {
  final channel = BroadcastChannel('isar-owner-$name');
  final token =
      '${DateTime.now().microsecondsSinceEpoch}-${window.crypto.randomUUID()}';
  var claimed = false;
  var conflict = false;
  channel.onmessage = ((Event event) {
    final message = ((event as MessageEvent).data as JSString?)?.toDart;
    if (message == null) return;
    if (claimed && message.startsWith('probe:')) {
      channel.postMessage('owned:${message.substring(6)}'.toJS);
    } else if (message == 'owned:$token') {
      conflict = true;
    } else if (message.startsWith('claim:') && message != 'claim:$token') {
      conflict = true;
    }
  }).toJS;
  channel.postMessage('probe:$token'.toJS);
  await Future<void>.delayed(const Duration(milliseconds: 75));
  if (conflict) {
    channel.close();
    throw IsarError('Another tab owns Isar instance "$name".');
  }
  claimed = true;
  channel.postMessage('claim:$token'.toJS);
  await Future<void>.delayed(const Duration(milliseconds: 75));
  if (conflict) {
    channel.close();
    throw IsarError('Another tab is opening Isar instance "$name".');
  }
  return channel;
}

Future<JSAny?> _request(IDBRequest request) {
  final completer = Completer<JSAny?>();
  request.onsuccess =
      ((Event event) => completer.complete(request.result)).toJS;
  request.onerror = ((Event event) => completer.completeError(
        IsarError(request.error?.message ?? 'IndexedDB request failed.'),
      )).toJS;
  return completer.future;
}

Future<void> _transaction(IDBTransaction transaction) {
  final completer = Completer<void>();
  transaction.oncomplete = ((Event event) => completer.complete()).toJS;
  transaction.onerror = ((Event event) => completer.completeError(
        IsarError(
            transaction.error?.message ?? 'IndexedDB transaction failed.'),
      )).toJS;
  transaction.onabort = ((Event event) => completer.completeError(
        IsarError(
            transaction.error?.message ?? 'IndexedDB transaction aborted.'),
      )).toJS;
  return completer.future;
}

bool _schemasCompatible(String storedSource, String expectedSource) {
  final stored =
      (jsonDecode(storedSource) as List).cast<Map<String, dynamic>>();
  final expected =
      (jsonDecode(expectedSource) as List).cast<Map<String, dynamic>>();
  final expectedCollections = {
    for (final collection in expected) collection['name']: collection,
  };
  for (final oldCollection in stored) {
    final collection = expectedCollections[oldCollection['name']];
    if (collection == null) continue;
    final properties = {
      for (final property in collection['properties'] as List)
        (property as Map<String, dynamic>)['name']: property,
    };
    for (final oldProperty in oldCollection['properties'] as List) {
      final old = oldProperty as Map<String, dynamic>;
      final property = properties[old['name']];
      if (property != null && property['type'] != old['type']) return false;
    }
  }
  return true;
}

EngineState _migrateState(
  EngineState state,
  String storedSource,
  List<CollectionSchema<dynamic>> schemas,
) {
  final oldCollections = {
    for (final collection in (jsonDecode(storedSource) as List))
      (collection as Map<String, dynamic>)['name'] as String: collection,
  };
  final collectionNames = schemas.map((schema) => schema.name).toSet();
  final validLinkStores = {
    for (final schema in schemas)
      for (final link in schema.links.values)
        if (collectionNames.contains(link.target))
          '@link:${schema.name}:${link.name}',
  };
  return {
    for (final schema in schemas)
      schema.name: {
        for (final record in (state[schema.name] ?? const {}).entries)
          record.key: _migrateRecord(
            record.value,
            oldCollections[schema.name],
            schema,
          ),
      },
    for (final entry in state.entries)
      if (entry.key == '@counters' || validLinkStores.contains(entry.key))
        entry.key: entry.value,
  };
}

Map<Object, dynamic> _migrateRecord(
  Map<Object, dynamic> data,
  Map<String, dynamic>? oldSchema,
  Schema<dynamic> schema, {
  Map<String, Map<String, dynamic>>? oldEmbedded,
  Map<String, Schema<dynamic>>? newEmbedded,
}) {
  if (oldSchema == null) return data;
  final oldProperties =
      (oldSchema['properties'] as List).cast<Map<String, dynamic>>();
  oldEmbedded ??= {
    for (final embedded in (oldSchema['embeddedSchemas'] as List? ?? const []))
      (embedded as Map<String, dynamic>)['name'] as String: embedded,
  };
  newEmbedded ??=
      schema is CollectionSchema ? schema.embeddedSchemas : const {};
  final migrated = <Object, dynamic>{};
  for (final property in schema.properties.values) {
    final oldId = oldProperties.indexWhere(
      (oldProperty) => oldProperty['name'] == property.name,
    );
    if (oldId < 0 || !data.containsKey(oldId)) continue;
    if (oldProperties[oldId]['target'] != property.target) continue;
    var value = data[oldId];
    if (property.target != null && value != null) {
      final target = property.target!;
      final targetSchema = newEmbedded[target];
      final oldTarget = oldEmbedded[target];
      if (targetSchema != null && oldTarget != null) {
        if (value is List) {
          value = [
            for (final element in value)
              if (element is Map<Object, dynamic>)
                _migrateRecord(
                  element,
                  oldTarget,
                  targetSchema,
                  oldEmbedded: oldEmbedded,
                  newEmbedded: newEmbedded,
                )
              else
                element,
          ];
        } else if (value is Map<Object, dynamic>) {
          value = _migrateRecord(
            value,
            oldTarget,
            targetSchema,
            oldEmbedded: oldEmbedded,
            newEmbedded: newEmbedded,
          );
        }
      }
    }
    migrated[property.id] = value;
  }
  if (data.containsKey('@json')) migrated['@json'] = data['@json'];
  return migrated;
}

EngineState _decodeState(String source) {
  final decoded = jsonDecode(source) as Map<String, dynamic>;
  return {
    for (final collection in decoded.entries)
      collection.key: {
        for (final object in (collection.value as Map<String, dynamic>).entries)
          int.parse(object.key):
              _integerKeys(object.value) as Map<Object, dynamic>,
      },
  };
}

dynamic _stringifyKeys(dynamic value) {
  if (value is double && !value.isFinite) {
    return {
      '@double': value.isNaN
          ? 'nan'
          : value.isNegative
              ? '-infinity'
              : 'infinity',
    };
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _stringifyKeys(entry.value),
    };
  }
  if (value is List) return value.map(_stringifyKeys).toList();
  return value;
}

dynamic _integerKeys(dynamic value) {
  if (value is Map<String, dynamic>) {
    if (value.length == 1 && value['@double'] is String) {
      return switch (value['@double']) {
        'nan' => double.nan,
        '-infinity' => double.negativeInfinity,
        'infinity' => double.infinity,
        _ => value,
      };
    }
    return <Object, dynamic>{
      for (final entry in value.entries)
        int.tryParse(entry.key) ?? entry.key: _integerKeys(entry.value),
    };
  }
  if (value is List) return value.map(_integerKeys).toList();
  return value;
}
