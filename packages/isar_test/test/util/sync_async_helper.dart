import 'dart:async';
import 'dart:typed_data';

import 'package:isar/isar.dart';

import 'sync_future.dart';

bool get syncTest => Zone.current[#syncTest] as bool? ?? false;

Future<Isar> tOpen({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  String name = Isar.defaultName,
  bool relaxedDurability = true,
}) {
  if (syncTest) {
    final isar = Isar.openSync(
      schemas,
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
      inspector: false,
    );
    return SynchronousFuture(isar);
  } else {
    return Isar.open(
      schemas,
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
      inspector: false,
    );
  }
}

extension TIsar on Isar {
  Future<T> tTxn<T>(Future<T> Function() callback) {
    if (syncTest) {
      return Future.value(txnSync(callback));
    } else {
      return txn(callback);
    }
  }

  Future<T> tWriteTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    if (syncTest) {
      return writeTxnSync(callback, silent: silent);
    } else {
      return writeTxn(callback, silent: silent);
    }
  }

  Future<void> tClear() {
    if (syncTest) {
      clearSync();
      return SynchronousFuture(null);
    } else {
      return clear();
    }
  }
}

extension TIsarCollection<OBJ> on IsarCollection<OBJ> {
  Future<OBJ?> tGet(Id id) {
    if (syncTest) {
      return SynchronousFuture(getSync(id));
    } else {
      return get(id);
    }
  }

  Future<List<OBJ?>> tGetAll(List<int> ids) {
    if (syncTest) {
      return SynchronousFuture(getAllSync(ids));
    } else {
      return getAll(ids);
    }
  }

  Future<int> tPut(OBJ object, {bool saveLinks = false}) {
    if (syncTest) {
      return SynchronousFuture(putSync(object, saveLinks: saveLinks));
    } else {
      return put(object);
    }
  }

  Future<List<int>> tPutAll(List<OBJ> objects, {bool saveLinks = false}) {
    if (syncTest) {
      return SynchronousFuture(putAllSync(objects, saveLinks: saveLinks));
    } else {
      return putAll(objects);
    }
  }

  Future<bool> tDelete(Id id) {
    if (syncTest) {
      return SynchronousFuture(deleteSync(id));
    } else {
      return delete(id);
    }
  }

  Future<int> tDeleteAll(List<int> ids) {
    if (syncTest) {
      return SynchronousFuture(deleteAllSync(ids));
    } else {
      return deleteAll(ids);
    }
  }

  Future<void> tClear() {
    if (syncTest) {
      clearSync();
      return SynchronousFuture(null);
    } else {
      return clear();
    }
  }

  Future<void> tImportJsonRaw(Uint8List jsonBytes) {
    if (syncTest) {
      importJsonRawSync(jsonBytes);
      return SynchronousFuture(null);
    } else {
      return importJsonRaw(jsonBytes);
    }
  }

  Future<void> tImportJson(List<Map<String, dynamic>> json) {
    if (syncTest) {
      importJsonSync(json);
      return SynchronousFuture(null);
    } else {
      return importJson(json);
    }
  }

  Future<int> tGetSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) {
    if (syncTest) {
      return SynchronousFuture(getSizeSync(
        includeIndexes: includeIndexes,
        includeLinks: includeLinks,
      ));
    } else {
      return getSize(
        includeIndexes: includeIndexes,
        includeLinks: includeLinks,
      );
    }
  }
}

extension QueryBuilderExecute<OBJ, R>
    on QueryBuilder<OBJ, R, QQueryOperations> {
  Future<R?> tFindFirst() {
    if (syncTest) {
      return SynchronousFuture(findFirstSync());
    } else {
      return findFirst();
    }
  }

  Future<List<R>> tFindAll() {
    if (syncTest) {
      return SynchronousFuture(findAllSync());
    } else {
      return findAll();
    }
  }

  Future<int> tCount() {
    if (syncTest) {
      return SynchronousFuture(countSync());
    } else {
      return count();
    }
  }

  Future<bool> tDeleteFirst() {
    if (syncTest) {
      return SynchronousFuture(deleteFirstSync());
    } else {
      return deleteFirst();
    }
  }

  Future<int> tDeleteAll() {
    if (syncTest) {
      return SynchronousFuture(deleteAllSync());
    } else {
      return deleteAll();
    }
  }
}

/// Extension for Queries
/// Same as [QueryBuilderExecute], but for [Query] instead of [QueryBuilder].
extension QueryExecute<R> on Query<R> {
  Future<R?> tFindFirst() {
    if (syncTest) {
      return SynchronousFuture(findFirstSync());
    } else {
      return findFirst();
    }
  }

  Future<List<R>> tFindAll() {
    if (syncTest) {
      return SynchronousFuture(findAllSync());
    } else {
      return findAll();
    }
  }

  Future<int> tCount() {
    if (syncTest) {
      return SynchronousFuture(countSync());
    } else {
      return count();
    }
  }

  Future<bool> tDeleteFirst() {
    if (syncTest) {
      return SynchronousFuture(deleteFirstSync());
    } else {
      return deleteFirst();
    }
  }

  Future<int> tDeleteAll() {
    if (syncTest) {
      return SynchronousFuture(deleteAllSync());
    } else {
      return deleteAll();
    }
  }

  Future<M> tExportJsonRaw<M>(M Function(Uint8List) callback) {
    if (syncTest) {
      return SynchronousFuture(exportJsonRawSync(callback));
    } else {
      return exportJsonRaw(callback);
    }
  }

  Future<List<Map<String, dynamic>>> tExportJson() {
    if (syncTest) {
      return SynchronousFuture(exportJsonSync());
    } else {
      return exportJson();
    }
  }
}

/// Extension for QueryBuilders
extension QueryExecuteAggregation<OBJ, T extends num>
    on QueryBuilder<OBJ, T?, QQueryOperations> {
  Future<T?> tMin() {
    if (syncTest) {
      return SynchronousFuture(minSync());
    } else {
      return min();
    }
  }

  Future<T?> tMax() {
    if (syncTest) {
      return SynchronousFuture(maxSync());
    } else {
      return max();
    }
  }

  Future<double> tAverage() {
    if (syncTest) {
      return SynchronousFuture(averageSync());
    } else {
      return average();
    }
  }

  Future<T> tSum() {
    if (syncTest) {
      return SynchronousFuture(sumSync());
    } else {
      return sum();
    }
  }
}

/// Extension for QueryBuilders
extension QueryExecuteDateAggregation<OBJ>
    on QueryBuilder<OBJ, DateTime?, QQueryOperations> {
  Future<DateTime?> tMin() {
    if (syncTest) {
      return SynchronousFuture(minSync());
    } else {
      return min();
    }
  }

  Future<DateTime?> tMax() {
    if (syncTest) {
      return SynchronousFuture(maxSync());
    } else {
      return max();
    }
  }
}

extension TIsarLinkBase<OBJ> on IsarLinkBase<OBJ> {
  Future<void> tLoad() {
    if (syncTest) {
      loadSync();
      return SynchronousFuture(null);
    } else {
      return load();
    }
  }

  Future<void> tSave() {
    if (syncTest) {
      saveSync();
      return SynchronousFuture(null);
    } else {
      return save();
    }
  }

  Future<void> tReset() {
    if (syncTest) {
      resetSync();
      return SynchronousFuture(null);
    } else {
      return reset();
    }
  }
}

extension TIsarLinks<OBJ> on IsarLinks<OBJ> {
  Future<void> tLoad({bool overrideChanges = false}) {
    if (syncTest) {
      loadSync(overrideChanges: overrideChanges);
      return SynchronousFuture(null);
    } else {
      return load(overrideChanges: overrideChanges);
    }
  }

  Future<void> tUpdate({
    List<OBJ> link = const [],
    List<OBJ> unlink = const [],
  }) {
    if (syncTest) {
      updateSync(link: link, unlink: unlink);
      return SynchronousFuture(null);
    } else {
      return update(link: link, unlink: unlink);
    }
  }

  Future<int> tCount() => filter().tCount();
}
