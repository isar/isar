import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'backlink_test.g.dart';

@collection
class LinkModelA {
  LinkModelA(this.name);

  Id? id;

  final String name;

  final links = IsarLinks<LinkModelB>();

  final selfLinks = IsarLinks<LinkModelA>();

  @Backlink(to: 'selfLinks')
  final selfBacklinks = IsarLinks<LinkModelA>();

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

  @Backlink(to: 'links')
  final backlinks = IsarLinks<LinkModelA>();

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
    late LinkModelA a3;
    late LinkModelB b1;
    late LinkModelB b2;
    late LinkModelB b3;

    setUp(() async {
      isar = await openTempIsar([LinkModelASchema, LinkModelBSchema]);

      a1 = LinkModelA('modelA1');
      a2 = LinkModelA('modelA2');
      a3 = LinkModelA('modelA3');
      b1 = LinkModelB('modelB1');
      b2 = LinkModelB('modelB2');
      b3 = LinkModelB('modelB3');

      await isar.writeTxn(() async {
        await isar.linkModelAs.putAll([a1, a2, a3]);
        await isar.linkModelBs.putAll([b1, b2, b3]);
      });
    });

    test('otherlinks', () async {
      await isar.tWriteTxn(() async {
        a1.links.addAll([b1, b2, b3]);
        await a1.links.tSave();

        a2.links.addAll([b1, b2]);
        await a2.links.tSave();
      });

      await b1.backlinks.tLoad();
      expect(b1.backlinks, {a1, a2});
      await b2.backlinks.tLoad();
      expect(b2.backlinks, {a1, a2});
      await b3.backlinks.tLoad();
      expect(b3.backlinks, {a1});

      await isar.tWriteTxn(() => isar.linkModelBs.tDelete(b2.id!));

      await a1.links.tLoad();
      expect(a1.links, {b1, b3});
      await a2.links.tLoad();
      expect(a2.links, {b1});

      await isar.tWriteTxn(() => isar.linkModelAs.tDelete(a1.id!));

      await b1.backlinks.tLoad();
      expect(b1.backlinks, {a2});
      await b2.backlinks.tLoad();
      expect(b2.backlinks, <LinkModelA>{});
      await b3.backlinks.tLoad();
      expect(b3.backlinks, <LinkModelA>{});

      await a1.links.tLoad();
      expect(a1.links, <LinkModelB>{});
    });

    test('selflinks', () async {
      a1.selfLinks.addAll([a1, a2, a3]);
      a2.selfLinks.addAll([a2, a3]);
      await isar.tWriteTxn(() async {
        await a1.selfLinks.tSave();
        await a2.selfLinks.tSave();
      });

      await a1.selfBacklinks.tLoad();
      expect(a1.selfBacklinks, {a1});
      await a2.selfBacklinks.tLoad();
      expect(a2.selfBacklinks, {a1, a2});
      await a3.selfBacklinks.tLoad();
      expect(a3.selfBacklinks, {a1, a2});

      await isar.tWriteTxn(() => isar.linkModelAs.tDelete(a2.id!));

      await a1.selfBacklinks.tLoad();
      expect(a1.selfBacklinks, {a1});
      await a2.selfBacklinks.tLoad();
      expect(a2.selfBacklinks, <LinkModelA>{});
      await a3.selfBacklinks.tLoad();
      expect(a3.selfBacklinks, {a1});
    });
  });
}
