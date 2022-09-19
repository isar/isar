import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_bool_test.g.dart';

@collection
class BoolModel {
  BoolModel(this.field);

  Id? id;

  bool? field;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is BoolModel && other.id == id && other.field == field;
  }
}

void main() {
  group('Bool filter', () {
    late Isar isar;
    late IsarCollection<BoolModel> col;

    late BoolModel objNull;
    late BoolModel objFalse;
    late BoolModel objTrue;
    late BoolModel objFalse2;

    setUp(() async {
      isar = await openTempIsar([BoolModelSchema]);
      col = isar.boolModels;

      objNull = BoolModel(null);
      objFalse = BoolModel(false);
      objTrue = BoolModel(true);
      objFalse2 = BoolModel(false);

      await isar.writeTxn(() async {
        await col.putAll([objNull, objFalse, objTrue, objFalse2]);
      });
    });

    isarTest('.equalTo()', () async {
      await qEqual(col.filter().fieldEqualTo(true), [objTrue]);
      await qEqualSet(
        col.filter().fieldEqualTo(false),
        [objFalse, objFalse2],
      );
      await qEqual(col.filter().fieldEqualTo(null), [objNull]);
    });

    isarTest('.isNull()', () async {
      await qEqualSet(col.where().filter().fieldIsNull(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqualSet(
        col.where().filter().fieldIsNotNull(),
        [objFalse, objTrue, objFalse2],
      );
    });
  });
}
