import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'link_test.g.dart';

@Collection()
class LinkModelA {
  LinkModelA(this.name);

  Id? id;

  final String name;

  final links = IsarLinks<LinkModelB>();

  final selfLinks = IsarLinks<LinkModelA>();

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

@Collection()
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
  group('Link filter', () {
    late Isar isar;
    late LinkModelA a1;
    late LinkModelA a2;
    late LinkModelA a3;
    late LinkModelB b1;
    late LinkModelB b2;
    late LinkModelB b3;

    Future<void> _setup() async {
      isar = await openTempIsar([LinkModelASchema, LinkModelBSchema]);

      a1 = LinkModelA('modelA1');
      a2 = LinkModelA('modelA2');
      a3 = LinkModelA('modelA3');
      b1 = LinkModelB('modelB1');
      b2 = LinkModelB('modelB2');
      b3 = LinkModelB('modelB3');

      await isar.tWriteTxn(() async {
        await isar.linkModelAs.tPutAll([a1, a2, a3]);
        await isar.linkModelBs.tPutAll([b1, b2, b3]);
      });
    }

    group('Other', () {
      setUp(_setup);

      tearDown(() => isar.close());

      isarTest('single', () async {
        a1.links.addAll([b1, b3]);
        a2.links.addAll([b2, b3]);
        a3.links.addAll([b1]);

        await isar.tWriteTxn(() async {
          await a1.links.tSave();
          await a2.links.tSave();
          await a3.links.tSave();
        });

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .links((q) => q.idEqualTo(b1.id))
              .tFindAll(),
          [a1, a3],
        );

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .links((q) => q.not().nameContains('1'))
              .tFindAll(),
          [a1, a2],
        );

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .links((q) => q.idGreaterThan(5))
              .tFindAll(),
          [],
        );
      });

      isarTest('multiple', () async {
        a1.links.addAll([b1, b3]);
        a2.links.addAll([b2, b3]);
        a3.links.addAll([b1]);

        await isar.tWriteTxn(() async {
          await a1.links.tSave();
          await a2.links.tSave();
          await a3.links.tSave();
        });

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .links((q) => q.idEqualTo(b1.id))
              .links((q) => q.idEqualTo(b3.id))
              .tFindAll(),
          [a1],
        );

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .links((q) => q.nameContains('2'))
              .or()
              .links((q) => q.nameContains('3'))
              .tFindAll(),
          [a1, a2],
        );
      });

      isarTest('empty', () async {
        a1.links.addAll([b1]);

        await isar.tWriteTxn(() async {
          await a1.links.tSave();
        });

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .links((q) => q.idEqualTo(b1.id))
              .tFindAll(),
          [a1],
        );

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .links((q) => q.idGreaterThan(5))
              .tFindAll(),
          [],
        );
      });
    });

    group('Self', () {
      setUp(_setup);

      tearDown(() => isar.close());

      isarTest('single', () async {
        a1.selfLinks.addAll([a1, a2, a3]);
        a2.selfLinks.addAll([a2, a3]);
        a3.selfLinks.addAll([a2]);

        await isar.tWriteTxn(() async {
          await a1.selfLinks.tSave();
          await a2.selfLinks.tSave();
          await a3.selfLinks.tSave();
        });

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .selfLinks((q) => q.idEqualTo(a1.id))
              .tFindAll(),
          [a1],
        );

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .selfLinks((q) => q.not().nameContains('2'))
              .tFindAll(),
          [a1, a2],
        );

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .links((q) => q.idGreaterThan(5))
              .tFindAll(),
          [],
        );
      });

      isarTest('multiple', () async {
        a1.selfLinks.addAll([a1, a2, a3]);
        a2.selfLinks.addAll([a2, a3]);
        a3.selfLinks.addAll([a2]);

        await isar.tWriteTxn(() async {
          await a1.selfLinks.tSave();
          await a2.selfLinks.tSave();
          await a3.selfLinks.tSave();
        });

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .selfLinks((q) => q.idEqualTo(a1.id))
              .selfLinks((q) => q.idEqualTo(a3.id))
              .tFindAll(),
          [a1],
        );

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .selfLinks((q) => q.nameContains('2'))
              .or()
              .selfLinks((q) => q.nameContains('1'))
              .tFindAll(),
          [a1, a2, a3],
        );
      });

      isarTest('empty', () async {
        a1.selfLinks.addAll([a2]);

        await isar.tWriteTxn(() async {
          await a1.selfLinks.tSave();
        });

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .selfLinks((q) => q.idEqualTo(a2.id))
              .tFindAll(),
          [a1],
        );

        await qEqualSet(
          isar.linkModelAs
              .where()
              .filter()
              .selfLinks((q) => q.idGreaterThan(5))
              .tFindAll(),
          [],
        );
      });
    });

    group('Backlink', () {
      setUp(_setup);

      tearDown(() => isar.close());

      isarTest('single', () async {
        a1.links.addAll([b1, b3]);
        a2.links.addAll([b3]);
        a3.links.addAll([b1, b2]);

        await isar.tWriteTxn(() async {
          await a1.links.tSave();
          await a2.links.tSave();
          await a3.links.tSave();
        });

        await qEqualSet(
          isar.linkModelBs
              .where()
              .filter()
              .backlinks((q) => q.idEqualTo(a1.id))
              .tFindAll(),
          [b1, b3],
        );

        await qEqualSet(
          isar.linkModelBs
              .where()
              .filter()
              .backlinks((q) => q.not().nameContains('3'))
              .tFindAll(),
          [b1, b3],
        );

        await qEqualSet(
          isar.linkModelBs
              .where()
              .filter()
              .backlinks((q) => q.idGreaterThan(5))
              .tFindAll(),
          [],
        );
      });

      isarTest('multiple', () async {
        a1.links.addAll([b1, b3]);
        a2.links.addAll([b3]);
        a3.links.addAll([b1, b2]);

        await isar.tWriteTxn(() async {
          await a1.links.tSave();
          await a2.links.tSave();
          await a3.links.tSave();
        });

        await qEqualSet(
          isar.linkModelBs
              .where()
              .filter()
              .backlinks((q) => q.idEqualTo(a1.id))
              .backlinks((q) => q.idEqualTo(a3.id))
              .tFindAll(),
          [b1],
        );

        await qEqualSet(
          isar.linkModelBs
              .where()
              .filter()
              .backlinks((q) => q.nameContains('2'))
              .or()
              .backlinks((q) => q.nameContains('1'))
              .tFindAll(),
          [b1, b3],
        );
      });

      isarTest('empty', () async {
        a1.links.addAll([b1]);

        await isar.tWriteTxn(() async {
          await a1.links.tSave();
        });

        await qEqualSet(
          isar.linkModelBs
              .where()
              .filter()
              .backlinks((q) => q.idEqualTo(a1.id))
              .tFindAll(),
          [b1],
        );

        await qEqualSet(
          isar.linkModelBs
              .where()
              .filter()
              .backlinks((q) => q.idGreaterThan(5))
              .tFindAll(),
          [],
        );
      });
    });
  });
}
