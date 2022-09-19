import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'link_test.g.dart';

@collection
class LinkModelA {
  LinkModelA();

  LinkModelA.name(this.name);

  Id? id;

  late String name;

  final selfLink = IsarLink<LinkModelA>();

  final otherLink = IsarLink<LinkModelB>();

  final selfLinks = IsarLinks<LinkModelA>();

  final otherLinks = IsarLinks<LinkModelB>();

  @Backlink(to: 'selfLink')
  final selfLinkBacklink = IsarLinks<LinkModelA>();

  @Backlink(to: 'selfLinks')
  final selfLinksBacklink = IsarLinks<LinkModelA>();

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
  LinkModelB();

  LinkModelB.name(this.name);

  Id? id;

  late String name;

  @Backlink(to: 'otherLink')
  final linkBacklinks = IsarLinks<LinkModelA>();

  @Backlink(to: 'otherLinks')
  IsarLinks<LinkModelA> linksBacklinks = IsarLinks<LinkModelA>();

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
  group('Links', () {
    late Isar isar;
    late IsarCollection<LinkModelA> linksA;
    late IsarCollection<LinkModelB> linksB;

    late LinkModelA objA1;
    late LinkModelA objA2;
    late LinkModelA objA3;

    late LinkModelB objB1;
    late LinkModelB objB2;
    late LinkModelB objB3;

    setUp(() async {
      isar = await openTempIsar([LinkModelASchema, LinkModelBSchema]);
      linksA = isar.linkModelAs;
      linksB = isar.linkModelBs;

      objA1 = LinkModelA.name('modelA1');
      objA2 = LinkModelA.name('modelA2');
      objA3 = LinkModelA.name('modelA3');

      objB1 = LinkModelB.name('modelB1');
      objB2 = LinkModelB.name('modelB2');
      objB3 = LinkModelB.name('modelB3');
    });

    group('self link', () {
      isarTest('save link manually', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2]));

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, objA2);
      });

      isarTest('multiple save', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2]));

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() async {
          await Future.wait([
            for (int i = 0; i < 100; i++) objA1.selfLink.tSave(),
          ]);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, objA2);
      });

      isarTest('.load() / .save()', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2]));

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, objA2);

        objA1.selfLink.value = null;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());
        await newA1.selfLink.tLoad();
        expect(newA1.selfLink.value, null);
      });

      isarTest('delete source', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2]));

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());
        await isar.tWriteTxn(() => linksA.tDelete(objA1.id!));

        final newA2 = await linksA.tGet(objA2.id!);
        await newA2!.selfLinkBacklink.tLoad();
        expect(newA2.selfLinkBacklink, const <LinkModelA>[]);
      });

      isarTest('delete target', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2]));

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());
        await isar.tWriteTxn(() => linksA.tDelete(objA2.id!));

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, null);
      });

      isarTest('delete with same obj link', () async {
        await isar.tWriteTxn(() => linksA.tPut(objA1));

        objA1.selfLink.value = objA1;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());
        await isar.tWriteTxn(() => linksA.tDelete(objA1.id!));

        final newA1 = await linksA.tGet(objA1.id!);
        expect(newA1, null);
      });

      isarTest('reset loaded link', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2]));

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, objA2);

        await isar.tWriteTxn(() => objA1.selfLink.tReset());

        final newestA1 = await linksA.tGet(objA1.id!);
        await newestA1!.selfLink.tLoad();
        expect(newestA1.selfLink.value, null);
      });

      isarTest('reset unloaded link', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2]));

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await isar.tWriteTxn(() => newA1!.selfLink.tReset());

        final newestA1 = await linksA.tGet(objA1.id!);
        await newestA1!.selfLink.tLoad();
        expect(newestA1.selfLink.value, null);
      });

      isarTest('multiple updates', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2]));

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());
        objA1.selfLink.value = null;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());
        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());
        await isar.tWriteTxn(() => objA1.selfLink.tReset());
        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, objA2);
      });

      isarTest('nested links', () async {
        await isar.tWriteTxn(() => linksA.tPut(objA1));

        objA1.selfLink.value = objA1;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        await newA1.selfLink.value?.selfLink.tLoad();
        await newA1.selfLink.value?.selfLink.value?.selfLink.tLoad();

        expect(newA1, objA1);
        expect(newA1.selfLink.value, objA1);
        expect(newA1.selfLink.value?.selfLink.value, objA1);
        expect(newA1.selfLink.value?.selfLink.value?.selfLink.value, objA1);
      });

      isarTest('backlink', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2]));

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() => objA1.selfLink.tSave());

        final newA2 = await linksA.tGet(objA2.id!);
        await newA2!.selfLinkBacklink.tLoad();
        expect(newA2.selfLinkBacklink, [objA1]);

        newA2.selfLink.value = newA2;
        await isar.tWriteTxn(newA2.selfLink.tSave);

        final newestA2 = await linksA.tGet(objA2.id!);
        await newestA2!.selfLinkBacklink.tLoad();
        expect(newestA2.selfLinkBacklink, {objA1, objA2});
      });
    });

    group('other link', () {
      isarTest('save link', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1);
          await linksB.tPut(objB1);
        });

        objA1.otherLink.value = objB1;
        await isar.tWriteTxn(() => objA1.otherLink.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.otherLink.tLoad();
        expect(newA1.otherLink.value, objB1);
      });

      isarTest('.load() / .save()', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1);
          await linksB.tPut(objB1);
        });

        objA1.otherLink.value = objB1;
        await isar.tWriteTxn(() => objA1.otherLink.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.otherLink.tLoad();
        expect(newA1.otherLink.value, objB1);

        objA1.otherLink.value = null;
        await isar.tWriteTxn(() => objA1.otherLink.tSave());

        await newA1.otherLink.tLoad();
        expect(newA1.otherLink.value, null);
      });

      isarTest('backlink', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1);
          await linksB.tPut(objB1);
        });

        objA1.otherLink.value = objB1;
        await isar.tWriteTxn(() => objA1.otherLink.tSave());

        final newB2 = await linksB.tGet(objB1.id!);
        await newB2!.linkBacklinks.tLoad();

        expect(newB2.linkBacklinks, [objA1]);
      });
    });

    group('self links', () {
      isarTest('save link', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2, objA3]));

        objA1.selfLinks.addAll([objA2, objA3]);

        await isar.tWriteTxn(() => objA1.selfLinks.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLinks.tLoad();
        expect(newA1.selfLinks, {objA2, objA3});
      });

      isarTest('save link in unsaved object', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA2, objA3]));

        objA1.selfLinks.addAll([objA2, objA3]);

        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1);
          await objA1.selfLinks.tSave();
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLinks.tLoad();
        expect(newA1.selfLinks, {objA2, objA3});
      });

      isarTest('delete source', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2, objA3]));

        objA1.selfLinks.addAll([objA2, objA3]);
        await isar.tWriteTxn(() => objA1.selfLinks.tSave());

        final newA2 = await linksA.tGet(objA2.id!);
        final newA3 = await linksA.tGet(objA3.id!);
        await Future.wait([
          newA2!.selfLinksBacklink.tLoad(),
          newA3!.selfLinksBacklink.tLoad(),
        ]);

        expect(newA2.selfLinksBacklink, [objA1]);
        expect(newA3.selfLinksBacklink, [objA1]);

        await isar.tWriteTxn(() => linksA.tDelete(objA1.id!));

        final newestA2 = await linksA.tGet(objA2.id!);
        final newestA3 = await linksA.tGet(objA3.id!);
        await Future.wait([
          newestA2!.selfLinksBacklink.tLoad(),
          newestA3!.selfLinksBacklink.tLoad(),
        ]);

        expect(newestA2.selfLinksBacklink, const <LinkModelA>[]);
        expect(newestA3.selfLinksBacklink, const <LinkModelA>[]);
      });

      isarTest('delete target', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2, objA3]));

        objA1.selfLinks.addAll([objA2, objA3]);
        await isar.tWriteTxn(() => objA1.selfLinks.tSave());
        await isar.tWriteTxn(() => linksA.tDelete(objA2.id!));

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLinks.tLoad();
        expect(newA1.selfLinks, [objA3]);
      });

      isarTest('delete with same obj links', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2, objA3]));

        objA1.selfLinks.addAll([objA1, objA2, objA3]);
        await isar.tWriteTxn(() => objA1.selfLinks.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        final newA2 = await linksA.tGet(objA2.id!);
        final newA3 = await linksA.tGet(objA3.id!);

        await Future.wait([
          newA1!.selfLinksBacklink.tLoad(),
          newA2!.selfLinksBacklink.tLoad(),
          newA3!.selfLinksBacklink.tLoad(),
        ]);

        expect(newA1.selfLinksBacklink, [objA1]);
        expect(newA2.selfLinksBacklink, [objA1]);
        expect(newA3.selfLinksBacklink, [objA1]);

        await isar.tWriteTxn(() => linksA.tDelete(objA1.id!));

        final newestA1 = await linksA.tGet(objA1.id!);
        expect(newestA1, null);

        final newestA2 = await linksA.tGet(objA2.id!);
        final newestA3 = await linksA.tGet(objA3.id!);

        await Future.wait([
          newestA2!.selfLinksBacklink.tLoad(),
          newestA3!.selfLinksBacklink.tLoad(),
        ]);

        expect(newestA2.selfLinksBacklink, const <LinkModelA>[]);
        expect(newestA3.selfLinksBacklink, const <LinkModelA>[]);
      });

      isarTest('duplicate links', () async {
        await isar.tWriteTxn(() => linksA.tPutAll([objA1, objA2, objA3]));

        objA1.selfLinks.addAll([objA2, objA2, objA2, objA3]);
        await isar.tWriteTxn(() => objA1.selfLinks.tSave());

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLinks.tLoad();
        expect(newA1.selfLinks, {objA2, objA3});

        final newA2 = await linksA.tGet(objA2.id!);
        await newA2!.selfLinksBacklink.tLoad();
        expect(newA2.selfLinksBacklink, [objA1]);
      });
    });

    group('multiple links', () {
      isarTest('.load() / .save()', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPutAll([objA1, objA2, objA3]);
          await linksB.tPutAll([objB1, objB2, objB3]);
        });

        objA1.selfLink.value = objA2;
        objA1.selfLinks.addAll([objA2, objA3]);
        objA1.otherLink.value = objB1;
        objA1.otherLinks.addAll([objB1, objB2, objB3]);

        objA2.selfLink.value = objA3;
        objA2.selfLinks.addAll([objA3, objA1]);
        objA2.otherLink.value = objB2;
        objA2.otherLinks.addAll([objB1, objB2, objB3]);

        objA3.selfLink.value = objA1;
        objA3.selfLinks.addAll([objA1, objA2]);
        objA3.otherLink.value = objB3;
        objA3.otherLinks.addAll([objB1, objB2, objB3]);

        await isar.tWriteTxn(() async {
          await Future.wait([
            objA1.selfLink.tSave(),
            objA1.selfLinks.tSave(),
            objA1.otherLink.tSave(),
            objA1.otherLinks.tSave(),
            objA2.selfLink.tSave(),
            objA2.selfLinks.tSave(),
            objA2.otherLink.tSave(),
            objA2.otherLinks.tSave(),
            objA3.selfLink.tSave(),
            objA3.selfLinks.tSave(),
            objA3.otherLink.tSave(),
            objA3.otherLinks.tSave(),
          ]);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        final newA2 = await linksA.tGet(objA2.id!);
        final newA3 = await linksA.tGet(objA3.id!);
        final newB1 = await linksB.tGet(objB1.id!);
        final newB2 = await linksB.tGet(objB2.id!);
        final newB3 = await linksB.tGet(objB3.id!);

        await Future.wait([
          newA1!.selfLink.tLoad(),
          newA1.selfLinks.tLoad(),
          newA1.otherLink.tLoad(),
          newA1.otherLinks.tLoad(),
          newA2!.selfLink.tLoad(),
          newA2.selfLinks.tLoad(),
          newA2.otherLink.tLoad(),
          newA2.otherLinks.tLoad(),
          newA3!.selfLink.tLoad(),
          newA3.selfLinks.tLoad(),
          newA3.otherLink.tLoad(),
          newA3.otherLinks.tLoad(),
          newB1!.linkBacklinks.tLoad(),
          newB1.linksBacklinks.tLoad(),
          newB2!.linkBacklinks.tLoad(),
          newB2.linksBacklinks.tLoad(),
          newB3!.linkBacklinks.tLoad(),
          newB3.linksBacklinks.tLoad(),
        ]);

        expect(newA1.selfLink.value, objA2);
        expect(newA1.selfLinks, {objA2, objA3});
        expect(newA1.otherLink.value, objB1);
        expect(newA1.otherLinks, {objB1, objB2, objB3});

        expect(newA2.selfLink.value, objA3);
        expect(newA2.selfLinks, {objA3, objA1});
        expect(newA2.otherLink.value, objB2);
        expect(newA2.otherLinks, {objB1, objB2, objB3});

        expect(newA3.selfLink.value, objA1);
        expect(newA3.selfLinks, {objA1, objA2});
        expect(newA3.otherLink.value, objB3);
        expect(newA3.otherLinks, {objB1, objB2, objB3});

        expect(newB1.linkBacklinks, [objA1]);
        expect(newB1.linksBacklinks, {objA1, objA2, objA3});

        expect(newB2.linkBacklinks, [objA2]);
        expect(newB2.linksBacklinks, {objA1, objA2, objA3});

        expect(newB3.linkBacklinks, [objA3]);
        expect(newB3.linksBacklinks, {objA1, objA2, objA3});
      });
    });
  });
}
