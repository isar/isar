import 'package:child_package1/child_package1.dart';
import 'package:child_package2/child_package2.dart';
import 'package:isar/isar.dart';
import 'package:root_package/root_model1.dart';
import 'package:root_package/root_model2.dart';
import 'package:test/test.dart';

void main() {
  group('Test multi', () {
    late Isar isar;

    setUp(() async {
      registerBinaries();

      isar = await openTempIsar([
        ChildModel1Schema,
        ChildModel2Schema,
        ChildModel3Schema,
        ChildModel4Schema,
        RootModel1Schema,
        RootModel2Schema
      ]);
    });

    tearDown(() async {
      await isar.close();
    });

    test('RootModel1', () async {
      await isar
          .writeTxn((isar) => isar.rootModel1s.put(RootModel1()..name = 'rm1'));

      expect(
        await isar.rootModel1s.where().findFirst(),
        RootModel1()..name = 'rm1',
      );
    });

    test('RootModel2', () async {
      await isar
          .writeTxn((isar) => isar.rootModel2s.put(RootModel2()..name = 'rm2'));

      expect(
        await isar.rootModel2s.where().findFirst(),
        RootModel2()..name = 'rm2',
      );
    });

    test('ChildModel1', () async {
      await isar.writeTxn(
          (isar) => isar.childModel1s.put(ChildModel1()..name = 'cm1'));

      expect(
        await isar.childModel1s.where().findFirst(),
        ChildModel1()..name = 'cm1',
      );
    });

    test('ChildModel2', () async {
      await isar.writeTxn(
          (isar) => isar.childModel2s.put(ChildModel2()..name = 'cm2'));

      expect(
        await isar.childModel2s.where().findFirst(),
        ChildModel2()..name = 'cm2',
      );
    });

    test('ChildModel3', () async {
      await isar.writeTxn(
          (isar) => isar.childModel3s.put(ChildModel3()..name = 'cm3'));

      expect(
        await isar.childModel3s.where().findFirst(),
        ChildModel3()..name = 'cm3',
      );
    });

    test('ChildModel4', () async {
      await isar.writeTxn(
          (isar) => isar.childModel4s.put(ChildModel4()..name = 'cm4'));

      expect(
        await isar.childModel4s.where().findFirst(),
        ChildModel4()..name = 'cm4',
      );
    });
  });
}
