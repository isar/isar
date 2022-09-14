import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_links_self_test.g.dart';

@collection
class Model {
  Model(this.name);

  Id id = Isar.autoIncrement;

  final String name;

  final selfLinks = IsarLinks<Model>();

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
  group('Filter self links', () {
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

      obj1.selfLinks.add(obj1);
      obj2.selfLinks.addAll([obj1, obj2]);
      obj3.selfLinks.addAll([obj1, obj2, obj3]);
      obj4.selfLinks.addAll([obj4, obj5, obj1]);
      obj5.selfLinks.add(obj6);
      obj6.selfLinks.addAll([obj2, obj6]);

      await isar.tWriteTxn(
        () => Future.wait([
          obj1.selfLinks.tSave(),
          obj2.selfLinks.tSave(),
          obj3.selfLinks.tSave(),
          obj4.selfLinks.tSave(),
          obj5.selfLinks.tSave(),
          obj6.selfLinks.tSave(),
        ]),
      );
    });

    isarTest('.selfLinks()', () async {
      await qEqualSet(
        isar.models.filter().selfLinks((q) => q.nameStartsWith('obj')),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.models.filter().selfLinks((q) => q.nameEqualTo('obj 1')),
        [obj1, obj2, obj3, obj4],
      );

      await qEqualSet(
        isar.models.filter().selfLinks((q) => q.nameEqualTo('obj 2')),
        [obj2, obj3, obj6],
      );

      await qEqualSet(
        isar.models.filter().selfLinks((q) => q.nameEqualTo('obj 3')),
        [obj3],
      );

      await qEqualSet(
        isar.models.filter().selfLinks((q) => q.nameEqualTo('obj 4')),
        [obj4],
      );

      await qEqualSet(
        isar.models.filter().selfLinks((q) => q.nameEqualTo('obj 5')),
        [obj4],
      );

      await qEqualSet(
        isar.models.filter().selfLinks((q) => q.nameEqualTo('obj 6')),
        [obj5, obj6],
      );

      await qEqualSet(
        isar.models.filter().selfLinks((q) => q.nameEqualTo('non existing')),
        [],
      );
    });

    isarTest('Nested .selfLinks()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .selfLinks((q) => q.selfLinks((q) => q.nameStartsWith('obj'))),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLinks((q) => q.selfLinks((q) => q.nameEqualTo('obj 1'))),
        [obj1, obj2, obj3, obj4, obj6],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLinks((q) => q.selfLinks((q) => q.nameEqualTo('obj 2'))),
        [obj2, obj3, obj5, obj6],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLinks((q) => q.selfLinks((q) => q.nameEqualTo('obj 3'))),
        [obj3],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLinks((q) => q.selfLinks((q) => q.nameEqualTo('obj 4'))),
        [obj4],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLinks((q) => q.selfLinks((q) => q.nameEqualTo('obj 5'))),
        [obj4],
      );

      await qEqualSet(
        isar.models
            .filter()
            .selfLinks((q) => q.selfLinks((q) => q.nameEqualTo('obj 6'))),
        [obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.models.filter().selfLinks(
              (q) => q.selfLinks((q) => q.nameEqualTo('non existing')),
            ),
        [],
      );
    });
  });
}
