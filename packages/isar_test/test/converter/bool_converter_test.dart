/*import 'package:collection/collection.dart' show IterableExtension;
import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'bool_converter_test.g.dart';

@Collection()
class BoolModel {
  BoolModel({
    required this.boolEnum,
    required this.maybeBoolEnum,
    required this.indexedBoolEnum,
  });

  Id id = Isar.autoIncrement;

  @MyBoolEnumTypeConverter()
  final MyBoolEnum boolEnum;

  @NullableMyBoolEnumTypeConverter()
  final MyBoolEnum? maybeBoolEnum;

  @Index()
  @MyBoolEnumTypeConverter()
  final MyBoolEnum indexedBoolEnum;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoolModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          boolEnum == other.boolEnum &&
          maybeBoolEnum == other.maybeBoolEnum &&
          indexedBoolEnum == other.indexedBoolEnum;

  @override
  String toString() {
    return 'BoolModel{id: $id, boolEnum: $boolEnum, maybeBoolEnum: '
        '$maybeBoolEnum, indexedBoolEnum: $indexedBoolEnum}';
  }
}

@Collection(inheritance: true)
class ChildBoolModel extends BoolModel {
  ChildBoolModel({
    required super.boolEnum,
    required super.maybeBoolEnum,
    required super.indexedBoolEnum,
    required this.doubleNegatedBool,
  });

  @BoolNegatorTypeConverter()
  final bool doubleNegatedBool;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildBoolModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          boolEnum == other.boolEnum &&
          maybeBoolEnum == other.maybeBoolEnum &&
          indexedBoolEnum == other.indexedBoolEnum &&
          doubleNegatedBool == other.doubleNegatedBool;
}

enum MyBoolEnum {
  yes(true),
  no(false);

  const MyBoolEnum(this.value);

  final bool value;
}

class MyBoolEnumTypeConverter extends TypeConverter<MyBoolEnum, bool> {
  const MyBoolEnumTypeConverter();

  @override
  MyBoolEnum fromIsar(bool value) {
    return MyBoolEnum.values.firstWhere((element) => element.value == value);
  }

  @override
  bool toIsar(MyBoolEnum element) => element.value;
}

class NullableMyBoolEnumTypeConverter
    extends TypeConverter<MyBoolEnum?, bool?> {
  const NullableMyBoolEnumTypeConverter();

  @override
  MyBoolEnum? fromIsar(bool? value) {
    return MyBoolEnum.values.firstWhereOrNull(
      (element) => element.value == value,
    );
  }

  @override
  bool? toIsar(MyBoolEnum? element) => element?.value;
}

class BoolNegatorTypeConverter extends TypeConverter<bool, bool> {
  const BoolNegatorTypeConverter();

  @override
  bool fromIsar(bool value) => !value;

  @override
  bool toIsar(bool value) => !value;
}

void main() {
  group('Bool converter', () {
    late Isar isar;

    late BoolModel obj0;
    late BoolModel obj1;
    late BoolModel obj2;
    late ChildBoolModel childObj0;
    late ChildBoolModel childObj1;
    late ChildBoolModel childObj2;

    setUp(() async {
      isar = await openTempIsar([BoolModelSchema, ChildBoolModelSchema]);

      obj0 = BoolModel(
        boolEnum: MyBoolEnum.no,
        maybeBoolEnum: null,
        indexedBoolEnum: MyBoolEnum.no,
      );
      obj1 = BoolModel(
        boolEnum: MyBoolEnum.yes,
        maybeBoolEnum: MyBoolEnum.yes,
        indexedBoolEnum: MyBoolEnum.no,
      );
      obj2 = BoolModel(
        boolEnum: MyBoolEnum.yes,
        maybeBoolEnum: null,
        indexedBoolEnum: MyBoolEnum.yes,
      );
      childObj0 = ChildBoolModel(
        boolEnum: MyBoolEnum.yes,
        maybeBoolEnum: null,
        indexedBoolEnum: MyBoolEnum.yes,
        doubleNegatedBool: true,
      );
      childObj1 = ChildBoolModel(
        boolEnum: MyBoolEnum.yes,
        maybeBoolEnum: MyBoolEnum.yes,
        indexedBoolEnum: MyBoolEnum.yes,
        doubleNegatedBool: false,
      );
      childObj2 = ChildBoolModel(
        boolEnum: MyBoolEnum.no,
        maybeBoolEnum: null,
        indexedBoolEnum: MyBoolEnum.no,
        doubleNegatedBool: false,
      );

      await isar.tWriteTxn(
        () => Future.wait([
          isar.boolModels.tPutAll([obj0, obj1, obj2]),
          isar.childBoolModels.tPutAll([childObj0, childObj1, childObj2]),
        ]),
      );
    });

    isarTest('Query by filters', () async {
      await qEqual(
        isar.boolModels.filter().boolEnumEqualTo(MyBoolEnum.yes).tFindAll(),
        [obj1, obj2],
      );

      await qEqual(
        isar.boolModels
            .filter()
            .boolEnumEqualTo(MyBoolEnum.no)
            .and()
            .boolEnumEqualTo(MyBoolEnum.yes)
            .tFindAll(),
        [],
      );

      await qEqual(
        isar.boolModels
            .filter()
            .maybeBoolEnumEqualTo(MyBoolEnum.yes)
            .tFindAll(),
        [obj1],
      );

      await qEqual(
        isar.boolModels.filter().maybeBoolEnumIsNull().tFindAll(),
        [obj0, obj2],
      );

      await qEqual(
        isar.boolModels.filter().not().maybeBoolEnumIsNull().tFindAll(),
        [obj1],
      );

      await qEqual(
        isar.boolModels
            .filter()
            .boolEnumEqualTo(MyBoolEnum.no)
            .or()
            .maybeBoolEnumIsNull()
            .tFindAll(),
        [obj0, obj2],
      );
    });

    isarTest('Sort', () async {
      await qEqual(
        isar.boolModels.where().sortByBoolEnumDesc().tFindAll(),
        [obj1, obj2, obj0],
      );

      await qEqual(
        isar.boolModels.where().sortByMaybeBoolEnum().tFindAll(),
        [obj0, obj2, obj1],
      );

      await qEqual(
        isar.boolModels
            .where()
            .sortByIndexedBoolEnum()
            .thenByBoolEnumDesc()
            .tFindAll(),
        [obj1, obj0, obj2],
      );
    });

    isarTest('Query by index', () async {
      await qEqual(
        isar.boolModels
            .where()
            .indexedBoolEnumEqualTo(MyBoolEnum.no)
            .tFindAll(),
        [obj0, obj1],
      );

      await qEqual(
        isar.boolModels.where().anyIndexedBoolEnum().tFindAll(),
        [obj0, obj1, obj2],
      );

      await qEqual(
        isar.boolModels
            .where(sort: Sort.asc)
            .indexedBoolEnumEqualTo(MyBoolEnum.yes)
            .or()
            .indexedBoolEnumNotEqualTo(MyBoolEnum.yes)
            .indexedBoolEnumProperty()
            .tFindAll(),
        [MyBoolEnum.yes, MyBoolEnum.no, MyBoolEnum.no],
      );
    });

    isarTest('Query child by filters', () async {
      await qEqual(
        isar.childBoolModels.filter().boolEnumEqualTo(MyBoolEnum.no).tFindAll(),
        [childObj2],
      );

      await qEqual(
        isar.childBoolModels
            .filter()
            .boolEnumEqualTo(MyBoolEnum.yes)
            .tFindAll(),
        [childObj0, childObj1],
      );

      await qEqual(
        isar.childBoolModels.filter().maybeBoolEnumIsNull().tFindAll(),
        [childObj0, childObj2],
      );
    });

    isarTest('Query child by index', () async {
      await qEqual(
        isar.childBoolModels
            .where()
            .indexedBoolEnumEqualTo(MyBoolEnum.yes)
            .tFindAll(),
        [childObj0, childObj1],
      );

      await qEqual(
        isar.childBoolModels
            .where()
            .indexedBoolEnumEqualTo(MyBoolEnum.no)
            .or()
            .indexedBoolEnumNotEqualTo(MyBoolEnum.yes)
            .tFindAll(),
        [childObj2],
      );
    });

    isarTest('Query by double negated bool', () async {
      await qEqual(
        isar.childBoolModels.filter().doubleNegatedBoolEqualTo(true).tFindAll(),
        [childObj0],
      );

      await qEqual(
        isar.childBoolModels
            .filter()
            .doubleNegatedBoolEqualTo(false)
            .tFindAll(),
        [childObj1, childObj2],
      );

      await qEqual(
        isar.childBoolModels
            .filter()
            .not()
            .doubleNegatedBoolEqualTo(false)
            .tFindAll(),
        [childObj0],
      );
    });

    isarTest('Sort by boolEnum', () async {
      await qEqual(
        isar.boolModels.where().sortByBoolEnum().tFindAll(),
        [obj0, obj1, obj2],
      );

      await qEqual(
        isar.boolModels.where().sortByBoolEnumDesc().tFindAll(),
        [obj1, obj2, obj0],
      );

      await qEqual(
        isar.childBoolModels.where().sortByBoolEnumDesc().tFindAll(),
        [childObj0, childObj1, childObj2],
      );
    });

    isarTest('Sort by mayBoolEnum', () async {
      await qEqual(
        isar.boolModels.where().sortByMaybeBoolEnum().tFindAll(),
        [obj0, obj2, obj1],
      );

      await qEqual(
        isar.boolModels.where().sortByMaybeBoolEnumDesc().tFindAll(),
        [obj1, obj0, obj2],
      );
    });
  });
}
*/
