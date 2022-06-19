import 'package:isar/isar.dart';
import 'package:test/test.dart';
import 'dart:typed_data';

import 'common.dart';
import 'sync_future.dart';

var _testSync = false;

void testSyncAsync(Function test) {
  if (kIsWeb) {
    test();
  } else {
    group('sync', () {
      setUp(() {
        _testSync = true;
      });
      test();
    });

    group('async', () {
      setUp(() {
        _testSync = false;
      });
      test();
    });
  }
}

Future<Isar> tOpen({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  String name = Isar.defaultName,
  bool relaxedDurability = true,
}) {
  if (_testSync) {
    final isar = Isar.openSync(
      schemas: schemas,
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
    );
    return SynchronousFuture(isar);
  } else {
    return Isar.open(
      schemas: schemas,
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
    );
  }
}

extension TIsar on Isar {
  Future<T> tTxn<T>(Future<T> Function() callback) {
    if (_testSync) {
      return Future.value(txnSync(callback));
    } else {
      return txn(callback);
    }
  }

  Future<T> tWriteTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    if (_testSync) {
      return writeTxnSync(callback, silent: silent);
    } else {
      return writeTxn(callback, silent: silent);
    }
  }
}

extension TIsarCollection<OBJ> on IsarCollection<OBJ> {
  Future<OBJ?> tGet(int id) {
    if (_testSync) {
      return SynchronousFuture(getSync(id));
    } else {
      return get(id);
    }
  }

  Future<List<OBJ?>> tGetAll(List<int> ids) {
    if (_testSync) {
      return SynchronousFuture(getAllSync(ids));
    } else {
      return getAll(ids);
    }
  }

  Future<int> tPut(OBJ object) {
    if (_testSync) {
      return SynchronousFuture(putSync(object));
    } else {
      return put(object);
    }
  }

  Future<List<int>> tPutAll(List<OBJ> objects) {
    if (_testSync) {
      return SynchronousFuture(putAllSync(objects));
    } else {
      return putAll(objects);
    }
  }

  Future<bool> tDelete(int id) {
    if (_testSync) {
      return SynchronousFuture(deleteSync(id));
    } else {
      return delete(id);
    }
  }

  Future<int> tDeleteAll(List<int> ids) {
    if (_testSync) {
      return SynchronousFuture(deleteAllSync(ids));
    } else {
      return deleteAll(ids);
    }
  }

  Future<void> tClear() {
    if (_testSync) {
      clearSync();
      return SynchronousFuture(null);
    } else {
      return clear();
    }
  }

  Future<void> tImportJsonRaw(Uint8List jsonBytes) {
    if (_testSync) {
      importJsonRawSync(jsonBytes);
      return SynchronousFuture(null);
    } else {
      return importJsonRaw(jsonBytes);
    }
  }

  Future<void> tImportJson(List<Map<String, dynamic>> json) {
    if (_testSync) {
      importJsonSync(json);
      return SynchronousFuture(null);
    } else {
      return importJson(json);
    }
  }
}

extension QueryBuilderExecute<OBJ, R>
    on QueryBuilder<OBJ, R, QQueryOperations> {
  Future<R?> tFindFirst() {
    if (_testSync) {
      return SynchronousFuture(findFirstSync());
    } else {
      return findFirst();
    }
  }

  Future<List<R>> tFindAll() {
    if (_testSync) {
      return SynchronousFuture(findAllSync());
    } else {
      return findAll();
    }
  }

  Future<int> tCount() {
    if (_testSync) {
      return SynchronousFuture(countSync());
    } else {
      return count();
    }
  }

  Future<bool> tDeleteFirst() {
    if (_testSync) {
      return SynchronousFuture(deleteFirstSync());
    } else {
      return deleteFirst();
    }
  }

  Future<int> tDeleteAll() {
    if (_testSync) {
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
    if (_testSync) {
      return SynchronousFuture(findFirstSync());
    } else {
      return findFirst();
    }
  }

  Future<List<R>> tFindAll() {
    if (_testSync) {
      return SynchronousFuture(findAllSync());
    } else {
      return findAll();
    }
  }

  Future<int> tCount() {
    if (_testSync) {
      return SynchronousFuture(countSync());
    } else {
      return count();
    }
  }

  Future<bool> tDeleteFirst() {
    if (_testSync) {
      return SynchronousFuture(deleteFirstSync());
    } else {
      return deleteFirst();
    }
  }

  Future<int> tDeleteAll() {
    if (_testSync) {
      return SynchronousFuture(deleteAllSync());
    } else {
      return deleteAll();
    }
  }
}

/// Extension for QueryBuilders
extension QueryExecuteAggregation<OBJ, T extends num>
    on QueryBuilder<OBJ, T?, QQueryOperations> {
  Future<T?> tMin() {
    if (_testSync) {
      return SynchronousFuture(minSync());
    } else {
      return min();
    }
  }

  Future<T?> tMax() {
    if (_testSync) {
      return SynchronousFuture(maxSync());
    } else {
      return max();
    }
  }

  Future<double> tAverage() {
    if (_testSync) {
      return SynchronousFuture(averageSync());
    } else {
      return average();
    }
  }

  Future<T> tSum() {
    if (_testSync) {
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
    if (_testSync) {
      return SynchronousFuture(minSync());
    } else {
      return min();
    }
  }

  Future<DateTime?> tMax() {
    if (_testSync) {
      return SynchronousFuture(maxSync());
    } else {
      return max();
    }
  }
}

extension TIsarLinkBase<OBJ> on IsarLinkBase<OBJ> {
  Future<void> tLoad() {
    if (_testSync) {
      loadSync();
      return SynchronousFuture(null);
    } else {
      return load();
    }
  }

  Future<void> tSave() {
    if (_testSync) {
      saveSync();
      return SynchronousFuture(null);
    } else {
      return save();
    }
  }

  Future<void> tReset() {
    if (_testSync) {
      resetSync();
      return SynchronousFuture(null);
    } else {
      return reset();
    }
  }
}

extension TIsarLinks<OBJ> on IsarLinks<OBJ> {
  Future<void> tUpdate(
      {List<OBJ> link = const [], List<OBJ> unlink = const []}) {
    if (_testSync) {
      updateSync(link: link, unlink: unlink);
      return SynchronousFuture(null);
    } else {
      return update(link: link, unlink: unlink);
    }
  }

  Future<int> tCount() => filter().tCount();
}
