import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_link_self_test.g.dart';

@collection
class Model {
  Model(this.name);

  Id id = Isar.autoIncrement;

  final String name;

  final selfLink = IsarLink<Model>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  String toString() {
    return 'Model{id: $id, name: $name}';
  }
}

void main() {
  group('Filter self link', () {
    late Isar isar;

    late Model obj1;
    late Model obj2;
    late Model obj3;
    late Model obj4;
    late Model obj5;
    late Model obj6;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      obj1 = Model('obj 1');
      obj2 = Model('obj 2');
      obj3 = Model('obj 3');
      obj4 = Model('obj 4');
      obj5 = Model('obj 5');
      obj6 = Model('obj 6');

      await isar.tWriteTxn(
        () => isar.models.tPutAll([obj1, obj2, obj3, obj4, obj5, obj6]),
      );

      obj1.selfLink.value = obj2;
      obj2.selfLink.value = obj3;
      obj3.selfLink.value = obj4;
      obj4.selfLink.value = obj5;
      obj5.selfLink.value = obj1;
      obj6.selfLink.value = obj6;

      await isar.tWriteTxn(
        () => Future.wait([
          obj1.selfLink.tSave(),
          obj2.selfLink.tSave(),
          obj3.selfLink.tSave(),
          obj4.selfLink.tSave(),
          obj5.selfLink.tSave(),
          obj6.selfLink.tSave(),
        ]),
      );
    });

    isarTest('.selfLink()', () async {
      await qEqualSet(
        isar.models.filter().selfLink((q) => q.nameStartsWith('obj')),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.models.filter().selfLink((q) => q.nameEqualTo('obj 1')),
        [obj5],
      );

      await qEqualSet(
        isar.models.filter().selfLink((q) => q.nameEqualTo('obj 2')),
        [obj1],
      );

      await qEqualSet(
        isar.models.filter().selfLink((q) => q.nameEqualTo('obj 3')),
        [obj2],
      );

      await qEqualSet(
        isar.models.filter().selfLink((q) => q.nameEqualTo('obj 4')),
        [obj3],
      );

      await qEqualSet(
        isar.models.filter().selfLink((q) => q.nameEqualTo('obj 5')),
        [obj4],
      );

      await qEqualSet(
        isar.models.filter().selfLink((q) => q.nameEqualTo('obj 6')),
        [obj6],
      );

      await qEqualSet(
        isar.models.filter().selfLink((q) => q.nameEqualTo('non existing')),
        [],
      );
    });

    isarTest('Nested .selfLink()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .selfLink((q) => q.selfLink((q) => q.nameStartsWith('obj'))),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLink((q) => q.selfLink((q) => q.nameStartsWith('obj 1'))),
        [obj4],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLink((q) => q.selfLink((q) => q.nameStartsWith('obj 2'))),
        [obj5],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLink((q) => q.selfLink((q) => q.nameStartsWith('obj 3'))),
        [obj1],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLink((q) => q.selfLink((q) => q.nameStartsWith('obj 4'))),
        [obj2],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLink((q) => q.selfLink((q) => q.nameStartsWith('obj 5'))),
        [obj3],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLink((q) => q.selfLink((q) => q.nameStartsWith('obj 6'))),
        [obj6],
      );

      await qEqualSet(
        isar.models.filter().selfLink(
              (q) => q.selfLink((q) => q.nameStartsWith('non existing')),
            ),
        [],
      );
    });
  });
}
