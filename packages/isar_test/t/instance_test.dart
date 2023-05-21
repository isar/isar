import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'instance_test.g.dart';

@collection
class Model {
  Id? id;

  @Index()
  String? value;

  @override
  String toString() {
    return '{id: $id, value: $value}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is Model && other.id == id && other.value == value;
  }
}

void main() {
  group('Instance test', () {
    isarTest('persists auto increment', () async {
      var isar = await openTempIsar([ModelSchema]);
      final isarName = isar.name;

      final obj1 = Model()..value = 'M1';
      await isar.tWriteTxn(() async {
        await isar.models.tPut(obj1);
      });
      expect(obj1.id, 1);
      expect(await isar.models.tGet(obj1.id!), obj1);

      expect(await isar.close(), true);
      isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
      );

      final obj2 = Model()..value = 'M2';
      final obj3 = Model()
        ..value = 'M3'
        ..id = 20;
      await isar.tWriteTxn(() async {
        await isar.models.tPutAll([obj2, obj3]);
      });
      expect(obj2.id, 2);
      expect(obj3.id, 20);
      expect(await isar.models.tGet(obj2.id!), obj2);
      expect(await isar.models.tGet(obj3.id!), obj3);

      expect(await isar.close(), true);
      isar = await openTempIsar([ModelSchema], name: isarName);

      final obj4 = Model()..value = 'M4';
      await isar.tWriteTxn(() async {
        await isar.models.tPut(obj4);
      });
      expect(obj4.id, 21);
      await qEqual(isar.models.where(), [obj1, obj2, obj3, obj4]);
    });

    isarTest('Prevents usage of closed collection', () async {
      final isar = await openTempIsar([ModelSchema]);

      expect(await isar.close(deleteFromDisk: true), true);

      await expectLater(
        () => isar.models.tGet(1),
        throwsIsarError('already been closed'),
      );
    });
  });
}
