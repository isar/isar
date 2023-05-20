import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'inheritance_test.g.dart';

abstract class BaseModel {
  BaseModel({
    required this.name,
    required this.nickname,
  });

  Id identifier = Isar.autoIncrement;

  @Index()
  int get nameHash => name.hashCode;

  final String name;

  final String nickname;

  // ignore:unused_field
  final float _privateProperty = 0;

  @Ignore()
  final short ignoredProperty = 42;

  final link = IsarLink<InheritingModel>();
}

@collection
class InheritingModel extends BaseModel {
  InheritingModel({
    required super.name,
    required super.nickname,
    required this.age,
  });

  final int age;

  @override
  String toString() {
    return 'InheritingModel{name: $name, nameHash: $nameHash, nickname: '
        '$nickname, age: $age}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InheritingModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          nameHash == other.nameHash &&
          nickname == other.nickname &&
          age == other.age;
}

@Collection(inheritance: false)
class NonInheritingModel extends BaseModel {
  NonInheritingModel({
    required this.age,
    required this.nickname,
  }) : super(name: '', nickname: nickname);

  Id id = Isar.autoIncrement;

  final int age;

  @override
  // ignore:overridden_fields
  final String nickname;

  @override
  String toString() {
    return 'NonInheritingModel{id: $id, age: $age, nickname: $nickname}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NonInheritingModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          age == other.age &&
          nickname == other.nickname;
}

void main() {
  group('Inheritance', () {
    late Isar isar;

    late InheritingModel inheritingObj0;
    late InheritingModel inheritingObj1;
    late InheritingModel inheritingObj2;
    late InheritingModel inheritingObj3;
    late InheritingModel inheritingObj4;
    late InheritingModel inheritingObj5;

    late NonInheritingModel nonInheritingObj0;
    late NonInheritingModel nonInheritingObj1;
    late NonInheritingModel nonInheritingObj2;

    setUp(() async {
      isar = await openTempIsar([
        InheritingModelSchema,
        NonInheritingModelSchema,
      ]);

      inheritingObj0 = InheritingModel(
        name: 'inheriting obj0',
        nickname: 'obj0',
        age: 42,
      );
      inheritingObj1 = InheritingModel(
        name: 'inheriting obj1',
        nickname: 'obj1',
        age: 2,
      );
      inheritingObj2 = InheritingModel(
        name: 'inheriting obj2',
        nickname: 'obj2',
        age: 22,
      );
      inheritingObj3 = InheritingModel(
        name: 'inheriting obj3',
        nickname: 'obj3',
        age: 54,
      );
      inheritingObj4 = InheritingModel(
        name: 'inheriting obj4',
        nickname: 'obj4',
        age: 24,
      );
      inheritingObj5 = InheritingModel(
        name: 'inheriting obj5',
        nickname: 'obj5',
        age: 31,
      );

      nonInheritingObj0 = NonInheritingModel(age: 22, nickname: 'non-obj0');
      nonInheritingObj1 = NonInheritingModel(age: 56, nickname: 'non-obj1');
      nonInheritingObj2 = NonInheritingModel(age: 65, nickname: 'non-obj2');

      await isar.tWriteTxn(() async {
        await isar.inheritingModels.tPutAll([
          inheritingObj0,
          inheritingObj1,
          inheritingObj2,
          inheritingObj3,
          inheritingObj4,
          inheritingObj5,
        ]);
        await isar.nonInheritingModels.tPutAll([
          nonInheritingObj0,
          nonInheritingObj1,
          nonInheritingObj2,
        ]);
      });

      inheritingObj0.link.value = inheritingObj1;
      inheritingObj2.link.value = inheritingObj0;
      inheritingObj5.link.value = inheritingObj3;

      await isar.tWriteTxn(() async {
        await inheritingObj0.link.tSave();
        await inheritingObj2.link.tSave();
        await inheritingObj5.link.tSave();
      });
    });

    /*test('Validate inheritance model properties', () {
      expect(InheritingModelSchema.idName, 'identifier');
      expect(InheritingModelSchema.propertyIds.containsKey('nameHash'), true);
      expect(InheritingModelSchema.propertyIds.containsKey('name'), true);
      expect(InheritingModelSchema.propertyIds.containsKey('nickname'), true);
      expect(InheritingModelSchema.propertyIds.containsKey('age'), true);
      expect(
        InheritingModelSchema.propertyIds.containsKey('_privateProperty'),
        false,
      );
      expect(
        InheritingModelSchema.propertyIds.containsKey('ignoredProperty'),
        false,
      );
      expect(InheritingModelSchema.linkIds.containsKey('link'), true);
      expect(InheritingModelSchema.indexIds.containsKey('nameHash'), true);
    });

    test('Validation non inheritance model properties', () {
      expect(NonInheritingModelSchema.idName, 'id');
      expect(
        NonInheritingModelSchema.propertyIds.containsKey('nameHash'),
        false,
      );
      expect(NonInheritingModelSchema.propertyIds.containsKey('name'), false);
      expect(
        NonInheritingModelSchema.propertyIds.containsKey('nickname'),
        true,
      );
      expect(NonInheritingModelSchema.propertyIds.containsKey('age'), true);
      expect(
        NonInheritingModelSchema.propertyIds.containsKey('_privateProperty'),
        false,
      );
      expect(
        NonInheritingModelSchema.propertyIds.containsKey('ignoredProperty'),
        false,
      );
      expect(NonInheritingModelSchema.linkIds.containsKey('link'), false);
      expect(NonInheritingModelSchema.indexIds.containsKey('nameHash'), false);
    });*/

    isarTest('Query model with inheritance', () async {
      await qEqualSet(
        isar.inheritingModels.filter().nameContains('1').or().nameContains('4'),
        {inheritingObj1, inheritingObj4},
      );

      await qEqualSet(
        isar.inheritingModels
            .filter()
            .nicknameContains('3')
            .or()
            .nicknameContains('0'),
        {inheritingObj3, inheritingObj0},
      );

      await qEqualSet(
        isar.inheritingModels.filter().ageLessThan(40),
        {inheritingObj1, inheritingObj2, inheritingObj4, inheritingObj5},
      );

      await qEqualSet(
        isar.inheritingModels
            .filter()
            .link((q) => q.nameEqualTo(inheritingObj3.name)),
        {inheritingObj5},
      );

      await qEqualSet(
        isar.inheritingModels
            .filter()
            .link((q) => q.nameEqualTo(inheritingObj4.name)),
        {},
      );
    });

    isarTest('Query model with inherited index', () async {
      await qEqualSet(
        isar.inheritingModels
            .where()
            .nameHashEqualTo(inheritingObj1.name.hashCode)
            .or()
            .nameHashEqualTo(inheritingObj0.name.hashCode),
        {inheritingObj1, inheritingObj0},
      );

      await qEqualSet(
        isar.inheritingModels
            .where()
            .nameHashNotEqualTo(inheritingObj1.nameHash)
            .nameHashProperty(),
        {
          inheritingObj0.nameHash,
          inheritingObj2.nameHash,
          inheritingObj3.nameHash,
          inheritingObj4.nameHash,
          inheritingObj5.nameHash,
        },
      );

      await qEqualSet(
        isar.inheritingModels.where().anyNameHash(),
        {
          inheritingObj0,
          inheritingObj1,
          inheritingObj2,
          inheritingObj3,
          inheritingObj4,
          inheritingObj5,
        },
      );
    });

    isarTest('Query model without inheritance', () async {
      await qEqualSet(
        isar.nonInheritingModels.filter().ageBetween(30, 60),
        {nonInheritingObj1},
      );

      await qEqualSet(
        isar.nonInheritingModels
            .filter()
            .nicknameContains('obj1')
            .or()
            .nicknameContains('obj0'),
        {nonInheritingObj1, nonInheritingObj0},
      );

      await qEqualSet(
        isar.nonInheritingModels.filter().idGreaterThan(1),
        {nonInheritingObj1, nonInheritingObj2},
      );
    });
  });
}
