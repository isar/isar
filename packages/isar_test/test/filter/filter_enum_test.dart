import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';

part 'enum_test.g.dart';

@Collection()
class EnumModel {
  EnumModel(this.strField);

  Id? id;

  StringEnum? strField;

  IntEnum? intField;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is EnumModel &&
      other.strField == strField &&
      intField == other.intField;
}

enum StringEnum with IsarEnum<String> {
  myEnum1,
  myEnum2,
  anotherOne,
  eeNuuum;

  @override
  String get value => name;
}

enum IntEnum with IsarEnum<int> {
  myEnum1,
  myEnum2,
  anotherOne,
  eeNuuum;

  @override
  int get value => index;
}

void main() {
  group('Enum filter', () {
    late Isar isar;
    late IsarCollection<EnumModel> col;
    In

    late EnumModel objMin;
    late EnumModel obj1;
    late EnumModel obj2;
    late EnumModel obj3;
    late EnumModel objMax;

    setUp(() async {
      isar = await openTempIsar([ByteModelSchema]);
      col = isar.byteModels;

      objMin = ByteModel(0);
      obj1 = ByteModel(1);
      obj2 = ByteModel(123);
      obj3 = ByteModel(1);
      objMax = ByteModel(255);

      await isar.writeTxn(() async {
        await col.putAll([objMin, obj1, obj2, obj3, objMax]);
      });
    });
  });
}
