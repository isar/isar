import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'link_test.g.dart';

@Collection()
class LinkModelA {
  int? id;

  late String name;

  final selfLink = IsarLink<LinkModelA>();

  final otherLink = IsarLink<LinkModelB>();

  var selfLinks = IsarLinks<LinkModelA>();

  final otherLinks = IsarLinks<LinkModelB>();

  @Backlink(to: 'selfLink')
  final selfLinkBacklink = IsarLinks<LinkModelA>();

  @Backlink(to: 'selfLinks')
  final selfLinksBacklink = IsarLinks<LinkModelA>();

  LinkModelA();

  LinkModelA.name(this.name);

  @override
  String toString() {
    return 'LinkModelA($id, $name)';
  }

  @override
  bool operator ==(Object other) {
    return other is LinkModelA && id == other.id && other.name == name;
  }
}

@Collection()
class LinkModelB {
  int? id;

  late String name;

  @Backlink(to: 'otherLink')
  final linkBacklinks = IsarLinks<LinkModelA>();

  @Backlink(to: 'otherLinks')
  var linksBacklinks = IsarLinks<LinkModelA>();

  LinkModelB();

  LinkModelB.name(this.name);

  @override
  String toString() {
    return 'LinkModelB($id, $name)';
  }

  @override
  bool operator ==(Object other) {
    return other is LinkModelB && id == other.id && other.name == name;
  }
}

void main() {
  testSyncAsync(tests);
}

void tests() {
  group('Links', () {
    late Isar isar;
    late IsarCollection<LinkModelA> linksA;
    late IsarCollection<LinkModelB> linksB;

    late LinkModelA objA1;
    late LinkModelA objA2;
    late LinkModelA objA3;

    late LinkModelB objB1;
    //late LinkModelB objB2;
    //late LinkModelB objB3;

    setUp(() async {
      isar = await openTempIsar([LinkModelASchema, LinkModelBSchema]);
      linksA = isar.linkModelAs;
      linksB = isar.linkModelBs;

      objA1 = LinkModelA.name('modelA1');
      objA2 = LinkModelA.name('modelA2');
      objA3 = LinkModelA.name('modelA3');

      objB1 = LinkModelB.name('modelB1');
      //objB2 = LinkModelB.name('modelB2');
      //objB3 = LinkModelB.name('modelB3');
    });

    tearDown(() async {
      await isar.close();
    });

    group('self link', () {
      isarTest('new obj new target', () async {
        objA1.selfLink.value = objA2;
        objA3.selfLink.value = objA3;
        await isar.tWriteTxn(() async {
          objA1.id = Isar.autoIncrement;
          await linksA.tPutAll([objA1, objA3], saveLinks: true);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, objA2);

        final newA3 = await linksA.tGet(objA3.id!);
        await newA3!.selfLink.tLoad();
        expect(newA3.selfLink.value, objA3);
      });

      isarTest('new obj existing target', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA2);
        });

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1, saveLinks: true);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, objA2);
      });

      isarTest('existing obj new target', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1);
        });

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1, saveLinks: true);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, objA2);
      });

      isarTest('delete source', () async {
        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() async {
          objA1.id = Isar.autoIncrement;
          await linksA.tPut(objA1, saveLinks: true);
        });

        await isar.tWriteTxn(() async {
          await linksA.tDelete(objA1.id!);
        });

        final newA2 = await linksA.tGet(objA2.id!);
        await newA2!.selfLinkBacklink.tLoad();
        expect(newA2.selfLinkBacklink, <dynamic>[]);
      });

      isarTest('delete target', () async {
        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() async {
          objA1.id = Isar.autoIncrement;
          await linksA.tPut(objA1, saveLinks: true);
        });

        await isar.tWriteTxn(() async {
          await linksA.tDelete(objA2.id!);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, null);
      });

      isarTest('.load() / .save()', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1);
        });

        objA1.selfLink.value = objA2;
        await isar.tWriteTxn(() async {
          await objA1.selfLink.tSave();
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLink.tLoad();
        expect(newA1.selfLink.value, objA2);

        objA1.selfLink.value = null;
        await isar.tWriteTxn(() async {
          await objA1.selfLink.tSave();
        });

        await newA1.selfLink.tLoad();
        expect(newA1.selfLink.value, null);
      });
    });

    group('other link', () {
      isarTest('new obj new target', () async {
        objA1.otherLink.value = objB1;
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1, saveLinks: true);
        });

        await isar.tWriteTxn(() async {
          await linksB.tDelete(objB1.id!);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.otherLink.tLoad();
        expect(newA1.otherLink.value, null);
      });

      isarTest('new obj existing target', () async {
        await isar.tWriteTxn(() async {
          await linksB.tPut(objB1);
        });

        objA1.otherLink.value = objB1;
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1, saveLinks: true);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.otherLink.tLoad();
        expect(newA1.otherLink.value, objB1);
      });

      isarTest('existing obj added new', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1);
        });

        objA1.otherLink.value = objB1;
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1, saveLinks: true);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.otherLink.tLoad();
        expect(newA1.otherLink.value, objB1);
      });

      isarTest('.load() / .save()', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1);
        });

        objA1.otherLink.value = objB1;
        await isar.tWriteTxn(() async {
          await objA1.otherLink.tSave();
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.otherLink.tLoad();
        expect(newA1.otherLink.value, objB1);

        objA1.otherLink.value = null;
        await isar.tWriteTxn(() async {
          await objA1.otherLink.tSave();
        });

        await newA1.otherLink.tLoad();
        expect(newA1.otherLink.value, null);
      });
    });

    group('self links', () {
      isarTest('new obj', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPut(objA3);
        });
        objA1.selfLinks.add(objA2);
        objA1.selfLinks.add(objA3);

        await isar.tWriteTxn(() async {
          objA1.id = Isar.autoIncrement;
          await linksA.tPut(objA1, saveLinks: true);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLinks.tLoad();
        expect(newA1.selfLinks.length, 2);
        expect(newA1.selfLinks, {objA2, objA3});
      });

      isarTest('existing obj', () async {
        await isar.tWriteTxn(() async {
          await linksA.tPutAll([objA1, objA3]);
        });
        objA1.selfLinks.add(objA2);
        objA1.selfLinks.add(objA3);

        await isar.tWriteTxn(() async {
          await linksA.tPut(objA1, saveLinks: true);
        });

        final newA1 = await linksA.tGet(objA1.id!);
        await newA1!.selfLinks.tLoad();
        expect(newA1.selfLinks.length, 2);
        expect(newA1.selfLinks, {objA2, objA3});
      });
    });
  });
}
