@TestOn('vm')
import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'package:isar/isar.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'isolate_test.g.dart';

@Collection()
class TestModel {
  int? id;

  String? value;

  @override
  bool operator ==(other) {
    return other is TestModel && other.id == id && other.value == value;
  }
}

final _obj1 = TestModel()
  ..id = 1
  ..value = 'Model 1';
final _obj2 = TestModel()
  ..id = 2
  ..value = 'Model 2';
final _obj3 = TestModel()
  ..id = 3
  ..value = 'Model 3';

Future<bool> _isolateFunc(String name) async {
  registerBinaries();
  final isar = Isar.openSync(
    name: name,
    schemas: [TestModelSchema],
    directory: '////',
  );

  final current = isar.testModels.where().findAllSync();
  assert(current[0] == _obj1 && current[1] == _obj2);

  isar.writeTxnSync((isar) {
    isar.testModels.deleteSync(2);
    isar.testModels.putSync(_obj3);
  });

  assert(!(await isar.close()));

  return true;
}

void main() {
  testSyncAsync(tests);
}

void tests() {
  isarTest('Isolate test', () async {
    final isar = await openTempIsar([TestModelSchema]);

    await isar.tWriteTxn((isar) async {
      await isar.testModels.tPutAll([_obj1, _obj2]);
    });

    final result = await compute(_isolateFunc, isar.name);
    expect(result, true);

    qEqual(isar.testModels.where().tFindAll(), [_obj1, _obj3]);

    expect(await isar.close(), true);
  });
}
