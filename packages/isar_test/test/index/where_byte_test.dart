import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'where_byte_test.g.dart';

@collection
class ByteModel {
  ByteModel(this.field);

  Id? id;

  @Index()
  byte field;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is ByteModel && other.id == id && other.field == field;
  }
}

void main() {
  group('Where byte', () {
    late Isar isar;
    late IsarCollection<ByteModel> col;

    late ByteModel objMin;
    late ByteModel obj1;
    late ByteModel obj2;
    late ByteModel obj3;
    late ByteModel objMax;

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

    isarTest('.equalTo()', () async {
      await qEqual(col.where().fieldEqualTo(0), [objMin]);
      await qEqual(col.where().fieldEqualTo(1), [obj1, obj3]);
    });

    isarTest('.notEqualTo()', () async {
      await qEqual(
        col.where().fieldNotEqualTo(0),
        [obj1, obj3, obj2, objMax],
      );
      await qEqual(
        col.where().fieldNotEqualTo(1),
        [objMin, obj2, objMax],
      );
    });

    isarTest('.greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(0),
        [obj1, obj3, obj2, objMax],
      );
      await qEqual(
        col.where().fieldGreaterThan(0, include: true),
        [objMin, obj1, obj3, obj2, objMax],
      );
      await qEqual(col.where().fieldGreaterThan(255), []);
      await qEqual(
        col.where().fieldGreaterThan(255, include: true),
        [objMax],
      );
    });

    isarTest('.lessThan()', () async {
      await qEqual(
        col.where().fieldLessThan(255),
        [objMin, obj1, obj3, obj2],
      );
      await qEqual(
        col.where().fieldLessThan(255, include: true),
        [objMin, obj1, obj3, obj2, objMax],
      );
      await qEqual(col.where().fieldLessThan(0), []);
      await qEqual(
        col.where().fieldLessThan(0, include: true),
        [objMin],
      );
    });

    isarTest('.between()', () async {
      await qEqual(
        col.where().fieldBetween(0, 255),
        [objMin, obj1, obj3, obj2, objMax],
      );
      await qEqual(
        col.where().fieldBetween(0, 255, includeLower: false),
        [obj1, obj3, obj2, objMax],
      );
      await qEqual(
        col.where().fieldBetween(0, 255, includeUpper: false),
        [objMin, obj1, obj3, obj2],
      );
      await qEqual(col.where().fieldBetween(255, 0), []);
      await qEqual(col.where().fieldBetween(100, 110), []);
    });
  });
}
