// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:isar/isar.dart';
import 'package:isar/src/dart_engine/engine.dart';
import 'package:web/web.dart';

const _store = 'state';
const _snapshotKey = 'snapshot';
const _schemaKey = 'schema';
const _revisionKey = 'revision';

Future<Isar> openIsar({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
}) async {
  final lease = await _acquireLease(name);
  final database = await _openDatabase(name);
  final expectedSchema =
      jsonEncode(schemas.map((schema) => schema.toJson()).toList());
  final storedSchema = await _read(database, _schemaKey);
  if (storedSchema != null && storedSchema != expectedSchema) {
    database.close();
    lease.close();
    throw IsarError(
      'The existing web schema is incompatible. Automatic web schema '
      'migration is not supported in this beta.',
    );
  }
  final snapshot = await _read(database, _snapshotKey);
  var revision = int.tryParse(await _read(database, _revisionKey) ?? '') ?? 0;
  final state = snapshot == null ? null : _decodeState(snapshot);
  if (storedSchema == null) {
    await _write(database, {
      _schemaKey: expectedSchema,
      _revisionKey: revision.toString(),
      if (snapshot != null) _snapshotKey: snapshot,
    });
  }
  return DartEngineIsar(
    name,
    schemas,
    initialState: state,
    persist: (state) async {
      await _writeRevision(database, revision, {
        _schemaKey: expectedSchema,
        _snapshotKey: _encodeState(state),
      });
      revision++;
    },
    onClose: () {
      database.close();
      lease.close();
    },
  );
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

Future<IDBDatabase> _openDatabase(String name) {
  final completer = Completer<IDBDatabase>();
  final request = window.indexedDB.open('isar-$name', 1);
  request.onupgradeneeded = ((Event event) {
    final database = request.result as IDBDatabase;
    if (!database.objectStoreNames.contains(_store)) {
      database.createObjectStore(_store);
    }
  }).toJS;
  request.onsuccess = ((Event event) {
    final database = request.result as IDBDatabase;
    database.onversionchange = ((Event event) => database.close()).toJS;
    completer.complete(database);
  }).toJS;
  request.onerror = ((Event event) {
    completer.completeError(
      IsarError(request.error?.message ?? 'Failed to open IndexedDB.'),
    );
  }).toJS;
  request.onblocked = ((Event event) {
    completer.completeError(
      IsarError('IndexedDB open was blocked by another tab.'),
    );
  }).toJS;
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

Future<String?> _read(IDBDatabase database, String key) async {
  final transaction = database.transaction(_store.toJS, 'readonly');
  final request = transaction.objectStore(_store).get(key.toJS);
  final result = await _request(request);
  return result == null ? null : (result as JSString).toDart;
}

Future<void> _write(IDBDatabase database, Map<String, String> values) async {
  final transaction = database.transaction(_store.toJS, 'readwrite');
  final store = transaction.objectStore(_store);
  for (final entry in values.entries) {
    store.put(entry.value.toJS, entry.key.toJS);
  }
  await _transaction(transaction);
}

Future<void> _writeRevision(
  IDBDatabase database,
  int expectedRevision,
  Map<String, String> values,
) async {
  final transaction = database.transaction(_store.toJS, 'readwrite');
  final store = transaction.objectStore(_store);
  final result = await _request(store.get(_revisionKey.toJS));
  final actualRevision =
      result == null ? 0 : int.parse((result as JSString).toDart);
  if (actualRevision != expectedRevision) {
    transaction.abort();
    throw IsarError(
      'IndexedDB revision changed from $expectedRevision to $actualRevision.',
    );
  }
  for (final entry in values.entries) {
    store.put(entry.value.toJS, entry.key.toJS);
  }
  store.put((expectedRevision + 1).toString().toJS, _revisionKey.toJS);
  await _transaction(transaction);
}

Future<JSAny?> _request(IDBRequest request) {
  final completer = Completer<JSAny?>();
  request.onsuccess =
      ((Event event) => completer.complete(request.result)).toJS;
  request.onerror = ((Event event) {
    completer.completeError(
      IsarError(request.error?.message ?? 'IndexedDB request failed.'),
    );
  }).toJS;
  return completer.future;
}

Future<void> _transaction(IDBTransaction transaction) {
  final completer = Completer<void>();
  transaction.oncomplete = ((Event event) => completer.complete()).toJS;
  transaction.onerror = ((Event event) {
    completer.completeError(
      IsarError(transaction.error?.message ?? 'IndexedDB transaction failed.'),
    );
  }).toJS;
  transaction.onabort = ((Event event) {
    completer.completeError(
      IsarError(transaction.error?.message ?? 'IndexedDB transaction aborted.'),
    );
  }).toJS;
  return completer.future;
}

String _encodeState(EngineState state) => jsonEncode({
      for (final collection in state.entries)
        collection.key: {
          for (final object in collection.value.entries)
            object.key.toString(): _stringifyKeys(object.value),
        },
    });

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
    return <Object, dynamic>{
      for (final entry in value.entries)
        int.tryParse(entry.key) ?? entry.key: _integerKeys(entry.value),
    };
  }
  if (value is List) return value.map(_integerKeys).toList();
  return value;
}
