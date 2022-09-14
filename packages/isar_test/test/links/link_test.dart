import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'link_test.g.dart';

@collection
class LinkModelA {
  LinkModelA(this.name);

  Id? id;

  final String name;

  final link = IsarLink<LinkModelB>();

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

    isarTest('.isAttached .isLoaded .isChanged', () async {
      void verify(bool attached, bool loaded, bool changed) {
        expect(a1.link.isAttached, attached);
        expect(a1.link.isLoaded, loaded);
        expect(a1.link.isChanged, changed);
      }

      verify(false, false, false);

      a1.link.value = b1;
      verify(false, true, true);

      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1, saveLinks: false);
        await isar.linkModelBs.tPut(b1);
      });
      verify(true, true, true);

      a1.link.value = b1;
      await isar.tWriteTxn(() => a1.link.tSave());
      verify(true, true, false);
    });

    isarTest('.save() / .load() manually', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPut(a1);
        await isar.linkModelBs.tPut(b1);
      });

      a1.link.value = b1;
      await isar.tWriteTxn(a1.link.tSave);

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.link.tLoad();
      expect(newA1.link.value, b1);

      newA1.link.value = null;
      await isar.tWriteTxn(newA1.link.tSave);

      await a1.link.tLoad();
      expect(a1.link.value, isNull);
    });

    isarTestSync('save automatic', () {
      isar.writeTxnSync(() => isar.linkModelBs.putSync(b1));

      a1.link.value = b1;
      isar.writeTxnSync(() => isar.linkModelAs.putSync(a1));

      final newA1 = isar.linkModelAs.getSync(a1.id!);
      newA1!.link.loadSync();
      expect(newA1.link.value, b1);

      newA1.link.value = null;
      isar.writeTxnSync(() => isar.linkModelAs.putSync(newA1));

      a1.link.loadSync();
      expect(a1.link.value, isNull);
    });

    isarTestSync('create target', () {
      a1.link.value = b1;
      isar.writeTxnSync(() => isar.linkModelAs.putSync(a1));

      final newA1 = isar.linkModelAs.getSync(a1.id!);
      newA1!.link.loadSync();
      expect(newA1.link.value, b1);
    });

    isarTestSync('load automatic', () {
      a1.link.value = b1;
      a2.link.value = b2;
      isar.writeTxnSync(() => isar.linkModelAs.putAllSync([a1, a2]));

      final newA1 = isar.linkModelAs.getSync(a1.id!);
      expect(newA1!.link.value, b1);

      final newA2 = isar.linkModelAs.getSync(a2.id!);
      expect(newA2!.link.value, b2);
    });

    isarTest('reset', () async {
      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPutAll([a1, a2]);
        await isar.linkModelBs.tPutAll([b1, b2]);
      });

      a1.link.value = b1;
      a2.link.value = b2;
      await isar.tWriteTxn(() async {
        await a1.link.tSave();
        await a2.link.tSave();
      });

      await isar.tWriteTxn(() => a2.link.tReset());

      final newA1 = await isar.linkModelAs.tGet(a1.id!);
      await newA1!.link.tLoad();

      final newA2 = await isar.linkModelAs.tGet(a2.id!);
      await newA2!.link.tLoad();

      expect(a1.link.value, b1);
      expect(newA1.link.value, b1);
      expect(a2.link.value, null);
      expect(newA2.link.value, null);
    });
  });
}
