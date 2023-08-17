@TestOn('vm')
library;

import 'dart:isolate';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'isolate_test.g.dart';

@collection
class TestModel {
  @Id()
  late int id;

  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is TestModel && other.id == id && other.value == value;
  }
}

final TestModel _obj1 = TestModel()
  ..id = 1
  ..value = 'Model 1';
final TestModel _obj2 = TestModel()
  ..id = 2
  ..value = 'Model 2';
final TestModel _obj3 = TestModel()
  ..id = 3
  ..value = 'Model 3';

void main() {
  isarTest('Isolate test', () async {
    final name = getRandomName();
    final isar = await openTempIsar([TestModelSchema], name: name);

    isar.write((isar) {
      isar.testModels.putAll([_obj1, _obj2]);
    });

    await Isolate.run(() async {
      await prepareTest();

      final isar = Isar.get(schemas: [TestModelSchema], name: name);

      final current = isar.testModels.where().findAll();
      assert(
        current[0] == _obj1 && current[1] == _obj2,
        'Did not find objects',
      );

      isar.write((isar) {
        isar.testModels.delete(2);
        isar.testModels.put(_obj3);
      });

      assert(!isar.close(), 'Instance was closed incorrectly');
    });

    expect(isar.testModels.where().findAll(), [_obj1, _obj3]);
    expect(isar.close(deleteFromDisk: true), true);
  });
}
