import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'where_bool_test.g.dart';

@Collection()
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
      await qEqual(col.where().fieldEqualTo(true).tFindAll(), [objTrue]);
      await qEqual(
        col.where().fieldEqualTo(false).tFindAll(),
        [objFalse, objFalse2],
      );
      await qEqual(col.where().fieldEqualTo(null).tFindAll(), [objNull]);
    });

    isarTest('.notEqualTo()', () async {
      await qEqual(
        col.where().fieldNotEqualTo(true).tFindAll(),
        [objNull, objFalse, objFalse2],
      );
      await qEqual(
        col.where().fieldNotEqualTo(false).tFindAll(),
        [objNull, objTrue],
      );
      await qEqual(
        col.where().fieldNotEqualTo(null).tFindAll(),
        [objFalse, objFalse2, objTrue],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(col.where().fieldIsNull().tFindAll(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqual(
        col.where().fieldIsNotNull().findAll(),
        [objFalse, objFalse2, objTrue],
      );
    });
  });
}
