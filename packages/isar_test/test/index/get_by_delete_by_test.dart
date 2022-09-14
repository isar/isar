import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'get_by_delete_by_test.g.dart';

@collection
class Model {
  Model({required this.id, required this.guid, required this.content});
  final Id? id;

  @Index(unique: true, type: IndexType.value)
  final String guid;

  @Index(unique: true, composite: [CompositeIndex('guid')])
  final String content;

  @override
  String toString() {
    return '{id: $id, guid: $guid, content: $content}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is Model &&
        other.id == id &&
        other.guid == guid &&
        other.content == content;
  }
}

void main() {
  group('IndexGet', () {
    late Isar isar;
    late IsarCollection<Model> col;

    late Model obj1;
    late Model obj2;
    late Model obj3;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
      col = isar.models;

      obj1 = Model(id: 1, guid: 'AAA-001', content: 'A');
      obj2 = Model(id: 2, guid: 'BBB-002', content: 'B');
      obj3 = Model(id: 3, guid: 'CCC-003', content: 'C');

      await isar.writeTxn(() async {
        await col.putAll([obj1, obj2, obj3]);
      });
    });

    isarTest('getBy', () async {
      expect(await col.getByGuid(obj1.guid), obj1);
      expect(await col.getByGuid(obj2.guid), obj2);
      expect(await col.getByGuid(obj3.guid), obj3);
      expect(await col.getByGuid('SOMETHING'), null);

      expect(await col.getByContentGuid('A', obj1.guid), obj1);
      expect(await col.getByContentGuid('B', obj1.guid), null);
    });

    isarTest('getAllBy', () async {
      expect(
        await col.getAllByGuid([obj3.guid, 'SOMETHING', obj1.guid]),
        [obj3, null, obj1],
      );

      expect(
        await col.getAllByContentGuid(
          ['C', 'X', 'A'],
          [obj3.guid, 'SOMETHING', obj1.guid],
        ),
        [obj3, null, obj1],
      );
    });

    isarTestVm('getBySync', () {
      expect(col.getByGuidSync(obj1.guid), obj1);
      expect(col.getByGuidSync(obj2.guid), obj2);
      expect(col.getByGuidSync(obj3.guid), obj3);
      expect(col.getByGuidSync('SOMETHING'), null);

      expect(col.getByContentGuidSync('A', obj1.guid), obj1);
      expect(col.getByContentGuidSync('B', obj1.guid), null);
    });

    isarTestVm('getAllBySync', () {
      expect(col.getAllByGuidSync([obj3.guid, obj1.guid]), [obj3, obj1]);

      expect(
        col.getAllByContentGuidSync(
          ['C', 'X', 'A'],
          [obj3.guid, 'SOMETHING', obj1.guid],
        ),
        [obj3, null, obj1],
      );
    });

    isarTest('deleteBy', () async {
      await isar.writeTxn(() async {
        expect(await col.deleteByGuid(obj1.guid), true);
        expect(await col.deleteByGuid('SOMETHING'), false);
      });
      await qEqual(col.where(), [obj2, obj3]);

      await isar.writeTxn(() async {
        expect(await col.deleteByContentGuid('B', obj2.guid), true);
        expect(await col.deleteByContentGuid('D', obj3.guid), false);
      });
      await qEqual(col.where(), [obj3]);
    });

    isarTest('deleteAllBy', () async {
      await isar.writeTxn(() async {
        expect(await col.deleteAllByGuid([obj3.guid, obj1.guid, 'AAA']), 2);
      });
      await qEqual(col.where(), [obj2]);
    });

    isarTest('deleteAllBy composite', () async {
      await isar.writeTxn(() async {
        expect(
          await col.deleteAllByContentGuid(
            ['C', 'A', 'D'],
            [obj3.guid, obj1.guid, obj2.guid],
          ),
          2,
        );
      });
      await qEqual(col.where(), [obj2]);
    });

    isarTestVm('deleteBySync', () {
      isar.writeTxnSync(() {
        expect(col.deleteByGuidSync(obj1.guid), true);
        expect(col.deleteByGuidSync('SOMETHING'), false);
      });
      expect(col.where().findAllSync(), [obj2, obj3]);

      isar.writeTxnSync(() {
        expect(col.deleteByContentGuidSync('B', obj2.guid), true);
        expect(col.deleteByContentGuidSync('D', obj3.guid), false);
      });
      expect(col.where().findAllSync(), [obj3]);
    });

    isarTestVm('deleteAllBySync', () {
      isar.writeTxnSync(() {
        expect(col.deleteAllByGuidSync([obj3.guid, obj1.guid, 'AAA']), 2);
      });
      expect(col.where().findAllSync(), [obj2]);
    });

    isarTestVm('deleteAllBySync composite', () {
      isar.writeTxnSync(() {
        expect(
          col.deleteAllByContentGuidSync(
            ['C', 'A', 'D'],
            [obj3.guid, obj1.guid, obj2.guid],
          ),
          2,
        );
      });
      expect(col.where().findAllSync(), [obj2]);
    });
  });
}
