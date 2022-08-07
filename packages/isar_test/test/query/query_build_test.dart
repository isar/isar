import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'query_build_test.g.dart';

@Collection()
class Model {
  Model(this.name, this.index);

  Id id = Isar.autoIncrement;

  @Index()
  final int index;

  final String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          index == other.index &&
          name == other.name;
}

void main() {
  group('Query build', () {
    late Isar isar;

    late Model obj0;
    late Model obj1;
    late Model obj2;
    late Model obj3;
    late Model obj4;
    late Model obj5;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      obj0 = Model('obj0', 0);
      obj1 = Model('obj1', 1);
      obj2 = Model('obj2', 2);
      obj3 = Model('obj3', 3);
      obj4 = Model('obj4', 4);
      obj5 = Model('obj5', 5);

      await isar.tWriteTxn(
        () => isar.models.tPutAll([obj0, obj1, obj2, obj3, obj4, obj5]),
      );
    });

    tearDown(() => isar.close(deleteFromDisk: true));
    ;

    isarTest('Build and query', () async {
      final query1 = isar.models
          .where()
          .indexGreaterThan(2)
          .filter()
          .nameContains('5')
          .or()
          .nameContains('3')
          .build();

      await qEqualSet(
        query1.tFindAll(),
        [obj3, obj5],
      );

      final query2 = isar.models.where().build();

      await qEqualSet(
        query2.tFindAll(),
        [obj0, obj1, obj2, obj3, obj4, obj5],
      );

      final query3 = isar.models.where().sortByNameDesc().build();

      await qEqual(
        query3.tFindAll(),
        [obj5, obj4, obj3, obj2, obj1, obj0],
      );

      final query4 = isar.models.where().sortByIndex().build();

      await qEqual(
        query4.tFindAll(),
        [obj0, obj1, obj2, obj3, obj4, obj5],
      );
    });

    isarTest('Build and reuse query', () async {
      final query1 = isar.models
          .where()
          .indexLessThan(4)
          .sortByIndexDesc()
          .thenByIndexDesc()
          .thenByIndexDesc()
          .build();

      await qEqualSet(
        query1.tFindAll(),
        [obj3, obj2, obj1, obj0],
      );

      await qEqualSet(
        query1.tFindAll(),
        [obj3, obj2, obj1, obj0],
      );

      await qEqualSet(
        query1.tFindAll(),
        [obj3, obj2, obj1, obj0],
      );

      await qEqualSet(
        query1.tFindAll(),
        [obj3, obj2, obj1, obj0],
      );

      final query2 =
          isar.models.where().indexEqualTo(3).or().indexEqualTo(1).build();
      final query3 = isar.models.where().build();
      final query4 =
          isar.models.filter().nameContains('4').or().nameContains('0').build();

      await qEqualSet(
        query2.tFindAll(),
        [obj1, obj3],
      );

      await qEqualSet(
        query3.tFindAll(),
        [obj0, obj1, obj2, obj3, obj4, obj5],
      );

      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
      await qEqualSet(query4.tFindAll(), [obj0, obj4]);
      await qEqualSet(query2.tFindAll(), [obj1, obj3]);
      await qEqualSet(query3.tFindAll(), [obj0, obj1, obj2, obj3, obj4, obj5]);
      await qEqualSet(query3.tFindAll(), [obj0, obj1, obj2, obj3, obj4, obj5]);
      await qEqualSet(query2.tFindAll(), [obj1, obj3]);
      await qEqualSet(query2.tFindAll(), [obj1, obj3]);
      await qEqualSet(query2.tFindAll(), [obj1, obj3]);
      await qEqualSet(query2.tFindAll(), [obj1, obj3]);
      await qEqualSet(query4.tFindAll(), [obj0, obj4]);
      await qEqualSet(query4.tFindAll(), [obj0, obj4]);
      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
      await qEqualSet(query4.tFindAll(), [obj0, obj4]);
      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
      await qEqualSet(query3.tFindAll(), [obj0, obj1, obj2, obj3, obj4, obj5]);
      await qEqualSet(query2.tFindAll(), [obj1, obj3]);
      await qEqualSet(query4.tFindAll(), [obj0, obj4]);
      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
      await qEqualSet(query1.tFindAll(), [obj3, obj2, obj1, obj0]);
    });
  });
}
