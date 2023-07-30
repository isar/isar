import 'dart:math';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_id_test.g.dart';

@collection
class IdModel {
  IdModel();

  int id = Random().nextInt(99999);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is IdModel && other.id == id;
  }
}

void main() {
  group('Id filter', () {
    late Isar isar;
    late IsarCollection<int, IdModel> col;

    late IdModel obj0;
    late IdModel obj1;
    late IdModel obj2;
    late IdModel obj3;

    setUp(() async {
      isar = await openTempIsar([IdModelSchema]);
      col = isar.idModels;

      obj0 = IdModel()..id = 0;
      obj2 = IdModel()..id = 2;
      obj3 = IdModel()..id = 3;
      obj1 = IdModel()..id = 1;

      isar.write((isar) {
        isar.idModels.putAll([obj0, obj2, obj3, obj1]);
      });
    });

    isarTest('.equalTo()', () {
      expect(col.where().idEqualTo(2).findAll(), [obj2]);
      expect(col.where().idEqualTo(5).findAll(), isEmpty);
    });

    isarTest('.greaterThan()', () {
      expect(col.where().idGreaterThan(2).findAll(), [obj3]);
      expect(col.where().idGreaterThan(3).findAll(), isEmpty);
    });

    isarTest('.greaterThanOrEqualTo()', () {
      expect(col.where().idGreaterThanOrEqualTo(2).findAll(), [obj2, obj3]);
    });

    isarTest('.lessThan()', () {
      expect(col.where().idLessThan(1).findAll(), [obj0]);
      expect(col.where().idLessThan(0).findAll(), isEmpty);
    });

    isarTest('.lessThanOrEqualTo()', () {
      expect(col.where().idLessThanOrEqualTo(1).findAll(), [obj0, obj1]);
    });

    isarTest('.between()', () {
      expect(col.where().idBetween(1, 3).findAll(), [obj1, obj2, obj3]);
      expect(col.where().idBetween(5, 6).findAll(), isEmpty);
    });
  });
}
