import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'enum_test.g.dart';

enum TestEnum {
  option1(1, 1, 1, 'test1'),
  option2(2, 2, 2, 'test2'),
  option3(3, 3, 3, 'test3');

  const TestEnum(
    this.byteVal,
    this.shortVal,
    this.intVal,
    this.stringVal,
  );

  final byte byteVal;
  final short shortVal;
  final int intVal;
  final String stringVal;
}

@collection
class EnumModel {
  EnumModel(
    this.id,
    this.ordinalEnum,
    this.nameEnum,
    this.byteEnum,
    this.shortEnum,
    this.intEnum,
    this.stringEnum,
  );

  EnumModel.test(TestEnum value)
      : id = Isar.autoIncrement,
        ordinalEnum = value,
        nameEnum = value,
        byteEnum = value,
        shortEnum = value,
        intEnum = value,
        stringEnum = value;

  static final model1 = EnumModel.test(TestEnum.option1);
  static final model2 = EnumModel.test(TestEnum.option2);
  static final model3 = EnumModel.test(TestEnum.option3);

  final Id id;

  @enumerated
  final TestEnum ordinalEnum;

  @Enumerated(EnumType.name)
  final TestEnum nameEnum;

  @Enumerated(EnumType.value, 'byteVal')
  final TestEnum byteEnum;

  @Enumerated(EnumType.value, 'shortVal')
  final TestEnum shortEnum;

  @Enumerated(EnumType.value, 'intVal')
  final TestEnum intEnum;

  @Enumerated(EnumType.value, 'stringVal')
  final TestEnum stringEnum;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is EnumModel &&
      other.ordinalEnum == ordinalEnum &&
      other.nameEnum == nameEnum &&
      other.byteEnum == byteEnum &&
      other.shortEnum == shortEnum &&
      other.intEnum == intEnum &&
      other.stringEnum == stringEnum;

  @override
  String toString() {
    return '''EnumModel{ordinalEnum: $ordinalEnum, nameEnum: $nameEnum, byteEnum: $byteEnum, shortEnum: $shortEnum, intEnum: $intEnum, stringEnum: $stringEnum}''';
  }
}

void main() {
  group('Enum', () {
    isarTest('Verify property types', () {});

    isarTest('.get() / .put()', () async {
      final isar = await openTempIsar([EnumModelSchema]);
      await isar.tWriteTxn(() async {
        await isar.enumModels
            .tPutAll([EnumModel.model1, EnumModel.model2, EnumModel.model3]);
      });

      await qEqual(
        isar.enumModels.where(),
        [EnumModel.model1, EnumModel.model2, EnumModel.model3],
      );
    });

    isarTest('DateTime Enum', () {});

    isarTest('Added value', () {});

    isarTest('Removed value', () {});

    isarTest('.exportJson()', () {});

    isarTest('.importJson()', () {});
  });
}
