import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';

part 'filter_link_test.g.dart';

@Collection()
class LinkModelA {
  LinkModelA(this.name);
  int? id;

  late String name;

  final IsarLinks<LinkModelA> selfLinks = IsarLinks<LinkModelA>();

  final IsarLinks<LinkModelB> links = IsarLinks<LinkModelB>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is LinkModelA && id == other.id && other.name == name;
  }
}

@Collection()
class LinkModelB {
  LinkModelB(this.name);
  int? id;

  late String name;

  @Backlink(to: 'links')
  final IsarLinks<LinkModelA> backlink = IsarLinks<LinkModelA>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is LinkModelB && id == other.id && other.name == name;
  }
}

void main() {
  group('Groups', () {
    late Isar isar;
    late IsarCollection<LinkModelA> colA;
    late IsarCollection<LinkModelB> colB;

    late LinkModelA objA1;
    late LinkModelA objA2;
    late LinkModelA objA3;
    late LinkModelB objB1;
    late LinkModelB objB2;

    setUp(() async {
      isar = await openTempIsar([LinkModelASchema, LinkModelBSchema]);
      colA = isar.linkModelAs;
      colB = isar.linkModelBs;

      objA1 = LinkModelA('model a1');
      objA2 = LinkModelA('model a2');
      objA3 = LinkModelA('model a3');
      objB1 = LinkModelB('model b1');
      objB2 = LinkModelB('model b2');

      await isar.writeTxn(() async {
        await colA.putAll([objA1, objA2, objA3]);
        await colB.putAll([objB1, objB2]);
      });

      objA1.selfLinks.addAll([objA1, objA2, objA3]);
      objA2.selfLinks.addAll([objA1, objA3]);
      objA1.links.addAll([objB1]);
      objA2.links.addAll([objB2]);
      objA3.links.addAll([objB1, objB2]);

      await isar.writeTxn(() async {
        await colA.putAll([objA1, objA2, objA3]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('Single self link', () async {
      /*print(objA1.id);
      print(objA2.id);
      print(objA3.id);
      print(objB1.id);
      print(objB2.id);
      //final sl = colA.getSync(1)!.selfLinks;
      //sl.loadSync(overrideChanges: true);
      //print(sl);

      await qEqualSet(
        colA.where().filter().selfLinks((q) => q.nameContains('a1')).tFindAll(),
        {objA1, objA2},
      );*/
    });

    /*isarTest('Single self link without results', () async {
      await qEqualSet(
        colA
            .where()
            .filter()
            .not()
            .selfLinks((q) => q.nameContains('a4'))
            .findAll(),
        {objA1, objA2, objA3},
      );
    });

    isarTest('Self link and filter', () async {
      final models = await getModels();
      await linkSelfLinks(models);

      await qEqualSet(
        linksA
            .where()
            .filter()
            .selfLinks((q) => q.nameEqualTo('modelA_2'))
            .and()
            .nameEqualTo('modelA_1')
            .findAll(),
        {LinkModelA.name('modelA_1')},
      );
    });

    isarTest('Self backlink', () async {
      final models = await getModels();
      await linkSelfLinks(models);

      await qEqualSet(
        linksA
            .where()
            .filter()
            .selfLinksBacklink((q) => q.nameEqualTo('modelA_3'))
            .findAll(),
        {LinkModelA.name('modelA_1')},
      );

      await qEqualSet(
        linksA
            .where()
            .filter()
            .selfLinksBacklink(
                (q) => q.nameEqualTo('modelA_3').or().nameEndsWith('2'))
            .findAll(),
        {LinkModelA.name('modelA_1'), LinkModelA.name('modelA_2')},
      );
    });

    isarTest('Single other link', () async {
      final models = await getModels();
      final models2 = await getModels2();
      await linkOtherLinks(models, models2);

      await qEqualSet(
        linksA
            .where()
            .filter()
            .otherLinks((q) => q.nameEqualTo('modelB_2'))
            .findAll(),
        {
          LinkModelA.name('modelA_1'),
          LinkModelA.name('modelA_2'),
        },
      );
    });

    isarTest('Other link and filter', () async {
      final models = await getModels();
      final models2 = await getModels2();
      await linkOtherLinks(models, models2);

      await qEqualSet(
        linksA
            .where()
            .filter()
            .otherLinks((q) => q.nameEqualTo('modelB_2'))
            .and()
            .nameEqualTo('modelA_1')
            .findAll(),
        {LinkModelA.name('modelA_1')},
      );
    });

    isarTest('Other backlink', () async {
      final models = await getModels();
      final models2 = await getModels2();
      await linkOtherLinks(models, models2);

      await qEqualSet(
        linksB
            .where()
            .filter()
            .linksBacklinks((q) => q.nameEqualTo('modelA_3'))
            .findAll(),
        {LinkModelB.name('modelB_1')},
      );

      await qEqualSet(
        linksB
            .where()
            .filter()
            .linksBacklinks(
                (q) => q.nameEqualTo('modelA_3').or().nameEndsWith('2'))
            .findAll(),
        {LinkModelB.name('modelB_1'), LinkModelB.name('modelB_2')},
      );
    });*/
  });
}
