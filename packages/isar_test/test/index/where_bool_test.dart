import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'where_bool_test.g.dart';

@collection
class BoolModel {
  BoolModel(this.field);

  Id? id;

  @Index()
  bool? field;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is BoolModel && other.id == id && other.field == field;
  }
}

void main() {
  group('Where bool', () {
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
      await qEqual(col.where().fieldEqualTo(true), [objTrue]);
      await qEqual(
        col.where().fieldEqualTo(false),
        [objFalse, objFalse2],
      );
      await qEqual(col.where().fieldEqualTo(null), [objNull]);
    });

    isarTest('.notEqualTo()', () async {
      await qEqual(
        col.where().fieldNotEqualTo(true),
        [objNull, objFalse, objFalse2],
      );
      await qEqual(
        col.where().fieldNotEqualTo(false),
        [objNull, objTrue],
      );
      await qEqual(
        col.where().fieldNotEqualTo(null),
        [objFalse, objFalse2, objTrue],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(col.where().fieldIsNull(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqual(
        col.where().fieldIsNotNull(),
        [objFalse, objFalse2, objTrue],
      );
    });
  });
}
