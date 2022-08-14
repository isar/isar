import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'offset_limit_test.g.dart';

@Collection()
class Model {
  Model(this.value);

  final Id id = Isar.autoIncrement;

  final String value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Model && other.id == id && other.value == value;
}

void main() {
  group('Offset Limit', () {
    late Isar isar;
    late IsarCollection<Model> col;

    late List<Model> objects;
    late Model objA;
    late Model objA2;
    late Model objB;
    late Model objC;
    late Model objC2;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
      col = isar.models;

      objA = Model('A');
      objA2 = Model('A');
      objB = Model('B');
      objC = Model('C');
      objC2 = Model('C');
      objects = [objB, objA, objC, objA2, objC2];

      await isar.writeTxn(() async {
        await col.putAll(objects);
      });
    });

    isarTest('0 offset', () async {
      final result = col.where().offset(0);
      await qEqual(result, objects);
    });

    isarTest('big offset', () async {
      final result = col.where().offset(99);
      await qEqual(result, []);
    });

    isarTest('offset', () async {
      final result = col.where().offset(2);
      await qEqual(result, objects.sublist(2, 5));
    });

    isarTest('0 limit', () async {
      final result = col.where().limit(0);
      await qEqual(result, []);
    });

    isarTest('big limit', () async {
      final result = col.where().limit(999999);
      await qEqual(result, objects);
    });

    isarTest('limit', () async {
      final result = col.where().limit(3);
      await qEqual(result, objects.sublist(0, 3));
    });

    isarTest('offset and limit', () async {
      final result = col.where().offset(3).limit(1);
      await qEqual(result, objects.sublist(3, 4));
    });

    isarTest('offset and big limit', () async {
      final result = col.where().offset(3).limit(1000);
      await qEqual(result, objects.sublist(3));
    });

    isarTest('big offset and big limit', () async {
      final result = col.where().offset(300).limit(5);
      await qEqual(result, []);
    });
  });
}
