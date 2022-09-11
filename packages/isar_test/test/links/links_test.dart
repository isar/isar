import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'links_test.g.dart';

@collection
class LinkModelA {
  LinkModelA(this.name);

  Id? id;

  final String name;

  final links = IsarLinks<LinkModelB>();

  @override
  String toString() {
    return 'LinkModelA($id, $name)';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is LinkModelA && id == other.id && other.name == name;
  }
}

@collection
class LinkModelB {
  LinkModelB(this.name);

  Id? id;

  final String name;

  @override
  String toString() {
    return 'LinkModelB($id, $name)';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is LinkModelB && id == other.id && other.name == name;
  }
}

void main() {
  group('Link', () {
    late Isar isar;
    late LinkModelA a1;
    late LinkModelA a2;
    late LinkModelB b1;
    late LinkModelB b2;

    setUp(() async {
      isar = await openTempIsar([LinkModelASchema, LinkModelBSchema]);

      a1 = LinkModelA('modelA1');
      a2 = LinkModelA('modelA2');
      b1 = LinkModelB('modelB1');
      b2 = LinkModelB('modelB2');
    });

    isarTest('.tSave() / .load() manually', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPutAll([b1, b2]);
      });

      a1.links.addAll([b1, b2]);
      await isar.tWriteTxn(a1.links.tSave);

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.links.tLoad();
      expect(newA1.links, {b1, b2});

      newA1.links.remove(b1);
      await isar.tWriteTxn(newA1.links.tSave);

      await a1.links.tLoad();
      expect(a1.links, {b2});
    });

    isarTest('.load() preserves changes', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPutAll([b1, b2]);
      });

      a1.links.add(b2);
      await isar.tWriteTxn(a1.links.tSave);

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      expect(newA1!.links.add(b1), true);
      expect(newA1.links.remove(b2), true);
      await newA1.links.tLoad();
      expect(newA1.links, {b1});

      expect(newA1.links.remove(b1), true);
      expect(newA1.links.add(b2), true);
      await newA1.links.tLoad();
      expect(a1.links, {b2});
    });

    isarTest('.load(overrideChanges: true)', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPutAll([b1, b2]);
      });

      a1.links.add(b2);
      await isar.tWriteTxn(a1.links.tSave);

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      expect(newA1!.links.add(b1), true);
      expect(newA1.links.remove(b2), true);
      await newA1.links.tLoad(overrideChanges: true);
      expect(newA1.links, {b2});
    });

    isarTestSync('save automatic', () {
      isar.writeTxnSync(() => isar.linkModelBs.putAllSync([b1, b2]));

      a1.links.addAll([b1, b2]);
      expect(a1.links.isChanged, true);
      isar.writeTxnSync(() => isar.linkModelAs.putSync(a1));
      expect(a1.links.isChanged, false);

      final newA1 = isar.linkModelAs.getSync(a1.id!);
      newA1!.links.loadSync();
      expect(newA1.links, {b1, b2});

      newA1.links.remove(b1);
      expect(newA1.links.isChanged, true);
      isar.writeTxnSync(() => isar.linkModelAs.putSync(newA1));
      expect(newA1.links.isChanged, false);

      a1.links.loadSync();
      expect(a1.links, {b2});
    });

    isarTestSync('create target', () {
      a1.links.addAll({b1, b2});
      isar.writeTxnSync(() => isar.linkModelAs.putSync(a1));

      final newA1 = isar.linkModelAs.getSync(a1.id!);
      newA1!.links.loadSync();
      expect(newA1.links, {b1, b2});
    });

    isarTestSync('load automatic', () {
      a1.links.addAll([b1, b2]);
      a2.links.add(b2);
      isar.writeTxnSync(() => isar.linkModelAs.putAllSync([a1, a2]));

      final newA1 = isar.linkModelAs.getSync(a1.id!);
      newA1!.links.remove(b1);
      expect(newA1.links, {b2});

      final newA2 = isar.linkModelAs.getSync(a2.id!);
      newA2!.links.add(b1);
      expect(newA2.links, {b1, b2});
    });

    isarTest('.add() new target', () async {
      await isar.tWriteTxn(() => isar.linkModelAs.tPut(a1));

      expect(a1.links.add(b1), true);
      expect(a1.links.add(b1), false);
      expect(a2.links.add(b2), true);
      expect(a2.links.add(b2), false);

      await isar.tWriteTxn(() async {
        await isar.linkModelBs.tPutAll([b1, b2]);
        await isar.linkModelAs.tPut(a2, saveLinks: false);
        await a1.links.tSave();
        await a2.links.tSave();
      });

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.links.tLoad();
      expect(newA1.links, {b1});

      final newA2 = await isar.linkModelAs.tGet(a2.id!);
      await newA2!.links.tLoad();
      expect(newA2.links, {b2});
    });

    isarTest('.add() existing target', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPutAll([b1, b2]);
      });

      expect(a1.links.add(b1), true);
      final newB1 = await isar.linkModelBs.tGet(b1.id!);
      expect(a1.links.add(newB1!), false);

      expect(a2.links.add(b2), true);
      final newB2 = await isar.linkModelBs.tGet(b2.id!);
      expect(a2.links.add(newB2!), true);

      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a2, saveLinks: false);
        await a1.links.tSave();
        await a2.links.tSave();
      });

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.links.tLoad();
      expect(newA1.links, {b1});

      final newA2 = await isar.linkModelAs.tGet(a2.id!);
      await newA2!.links.tLoad();
      expect(newA2.links, {b2});
    });

    isarTest('.add() after .remove()', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
      });

      expect(a1.links.remove(b1), true);
      expect(a2.links.remove(b2), true);

      expect(a1.links.add(b1), true);
      expect(a2.links.add(b2), true);

      await isar.tWriteTxn(() async {
        await isar.linkModelBs.tPutAll([b1, b2]);
        await isar.linkModelAs.tPut(a2, saveLinks: false);
        await a1.links.tSave();
        await a2.links.tSave();
      });

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.links.tLoad();
      expect(newA1.links, {b1});

      final newA2 = await isar.linkModelAs.tGet(a2.id!);
      await newA2!.links.tLoad();
      expect(newA2.links, {b2});
    });

    isarTest('.remove() new target', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
      });

      expect(a1.links.remove(b1), true);
      expect(a1.links.remove(b1), false);
      expect(a2.links.remove(b2), true);
      expect(a2.links.remove(b2), false);

      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a2);
        await isar.linkModelBs.tPutAll([b1, b2]);

        final newA1 = await isar.linkModelAs.tGet(a1.id!);
        newA1!.links.addAll([b1, b2]);
        await newA1.links.tSave();

        final newA2 = await isar.linkModelAs.tGet(a2.id!);
        newA2!.links.addAll([b1, b2]);
        await newA2.links.tSave();

        await a1.links.tSave();
        await a2.links.tSave();
      });

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.links.tLoad();
      expect(newA1.links, {b2});

      final newA2 = await isar.linkModelAs.tGet(a2.id!);
      await newA2!.links.tLoad();
      expect(newA2.links, {b1});
    });

    isarTest('.remove() existing target', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPutAll([b1, b2]);

        a1.links.addAll([b1, b2]);
        await a1.links.tSave();
      });

      expect(a1.links.remove(b1), true);
      final newB1 = await isar.linkModelBs.tGet(b1.id!);
      expect(a1.links.remove(newB1), false);

      expect(a2.links.remove(b2), true);
      final newB2 = await isar.linkModelBs.tGet(b2.id!);
      expect(a2.links.remove(newB2), true);

      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a2);

        final newA2 = await isar.linkModelAs.tGet(a2.id!);
        newA2!.links.addAll([b1, b2]);
        await newA2.links.tSave();

        await a1.links.tSave();
        await a2.links.tSave();
      });

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.links.tLoad();
      expect(newA1.links, {b2});

      final newA2 = await isar.linkModelAs.tGet(a2.id!);
      await newA2!.links.tLoad();
      expect(newA2.links, {b1});
    });

    isarTest('.remove() without .add()', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPutAll([b1, b2]);

        a1.links.addAll([b1, b2]);
        await a1.links.tSave();
      });

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      final newB1 = await isar.linkModelBs.tGet(b1.id!);
      await newA1!.links.tLoad();
      expect(newA1.links.remove(newB1), true);

      await isar.tWriteTxn(() async {
        await a1.links.tSave();
      });

      await a1.links.tLoad();
      expect(newA1.links, {b2});
    });

    isarTest('.remove() after .add()', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
      });

      a1.links.addAll([b1, b2]);
      a2.links.addAll([b1, b2]);
      expect(a1.links.remove(b1), true);
      expect(a1.links.remove(b1), false);
      expect(a2.links.remove(b2), true);
      expect(a2.links.remove(b2), false);

      await isar.tWriteTxn(() async {
        await isar.linkModelBs.tPutAll([b1, b2]);
        await isar.linkModelAs.tPut(a2, saveLinks: false);
        await a1.links.tSave();
        await a2.links.tSave();
      });

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.links.tLoad();
      expect(newA1.links, {b2});

      final newA2 = await isar.linkModelAs.tGet(a2.id!);
      await newA2!.links.tLoad();
      expect(newA2.links, {b1});
    });

    isarTest('.contains() / .lookup() new target', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
      });

      a1.links.add(b1);
      a2.links.add(b2);

      expect(a1.links.contains(b1), false);
      expect(a1.links.lookup(b1), null);
      expect(a1.links.contains(b2), false);
      expect(a1.links.lookup(b2), null);
    });

    isarTest('.contains() / .lookup() existing target', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPutAll([b1, b2]);
      });

      a1.links.add(b1);
      a2.links.add(b2);

      final newB1 = await isar.linkModelBs.tGet(b1.id!);
      expect(a1.links.contains(newB1), true);
      expect(identical(a1.links.lookup(newB1), b1), true);

      expect(a1.links.contains(b2), false);
      expect(a1.links.lookup(b2), null);
    });

    isarTestSync('.contains() / .lookup() loads automatically', () {
      isar.writeTxnSync(() {
        a1.links.add(b2);
        isar.linkModelAs.putSync(a1);
      });

      {
        final newA1 = isar.linkModelAs.getSync(a1.id!);
        expect(newA1!.links.contains(b1), false);
      }
      {
        final newA1 = isar.linkModelAs.getSync(a1.id!);
        expect(newA1!.links.lookup(b1), null);
      }
      {
        final newA1 = isar.linkModelAs.getSync(a1.id!);
        expect(newA1!.links.contains(b2), true);
      }
      {
        final newA1 = isar.linkModelAs.getSync(a1.id!);
        expect(newA1!.links.lookup(b2), b2);
      }
    });

    isarTest('.filter()', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPutAll([b1, b2]);

        a1.links.addAll([b1, b2]);
        await a1.links.tSave();
      });

      await qEqualSet(a1.links.filter(), [b1, b2]);
      await qEqual(a1.links.filter().sortByNameDesc(), [b2, b1]);
      await qEqualSet(a1.links.filter().idEqualTo(b2.id), [b2]);
      await qEqualSet(a1.links.filter().idEqualTo(5), []);
    });

    isarTest('.reset()', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPutAll([a1, a2]);
        await isar.linkModelBs.tPutAll([b1, b2]);
      });

      a1.links.addAll([b1, b2]);
      a2.links.add(b2);
      await isar.tWriteTxn(() async {
        await a1.links.tSave();
        await a2.links.tSave();
      });

      await isar.tWriteTxn(a1.links.tReset);

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.links.tLoad();

      final newA2 = await isar.linkModelAs.tGet(a2.id!);
      await newA2!.links.tLoad();

      expect(a1.links, isEmpty);
      expect(newA1.links, isEmpty);
      expect(a2.links, {b2});
      expect(newA2.links, {b2});
    });

    isarTest('.toSet() .contains() .lookup() throw if not attached', () async {
      a2.links.addAll([b1, b2]);

      expect(() => a2.links.toSet(), throwsIsarError('managed by Isar'));
      expect(() => a2.links.contains(null), throwsIsarError('managed by Isar'));
      expect(() => a2.links.lookup(null), throwsIsarError('managed by Isar'));
    });

    isarTest('.iterator .length .toSet() new target', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
      });

      a1.links.addAll([b1, b2]);
      a2.links.addAll([b1, b2]);

      expect(a1.links.iterator.moveNext(), false);
      expect(a1.links.length, 0);
      expect(a1.links.toSet(), <LinkModelB>{});

      expect(a2.links.iterator.moveNext(), false);
      expect(a2.links.length, 0);
    });

    isarTest('.iterator .length .toSet() existing target', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPutAll([b1, b2]);
      });

      a1.links.addAll([b1, b2]);
      a2.links.addAll([b1, b2]);

      expect(a1.links.iterator.moveNext(), true);
      expect(a1.links.length, 2);
      expect(a1.links.toSet(), {b1, b2});

      expect(a2.links.iterator.moveNext(), false);
      expect(a2.links.length, 0);
    });

    isarTestSync('.iterator .length .toSet() load automatically', () async {
      isar.writeTxnSync(() {
        a1.links.addAll([b1, b2]);
        isar.linkModelAs.putSync(a1);
      });

      {
        final newA1 = isar.linkModelAs.getSync(a1.id!);
        final results = <LinkModelB>[];
        final iterator = newA1!.links.iterator;
        while (iterator.moveNext()) {
          results.add(iterator.current);
        }
        expect(results, {b1, b2});
      }

      {
        final newA1 = isar.linkModelAs.getSync(a1.id!);
        expect(newA1!.links.length, 2);
      }

      {
        final newA1 = isar.linkModelAs.getSync(a1.id!);
        expect(newA1!.links.toSet(), {b1, b2});
      }
    });
  });
}
