import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:isar_test/isar.g.dart';
import 'package:isar_test/link_model.dart';
import 'package:test/test.dart';

void main() {
  group('Groups', () {
    late Isar isar;
    late IsarCollection<LinkModelA> linksA;
    late IsarCollection<LinkModelB> linksB;

    setUp(() async {
      isar = await openTempIsar();
      linksA = isar.linkModelAs;
      linksB = isar.linkModelBs;
    });

    tearDown(() async {
      await isar.close();
    });

    Future<List<LinkModelA>> getModels() async {
      final models = [
        LinkModelA.name('modelA_1'),
        LinkModelA.name('modelA_2'),
        LinkModelA.name('modelA_3'),
      ];
      await isar.writeTxn((isar) => linksA.putAll(models));
      return models;
    }

    Future<List<LinkModelB>> getModels2() async {
      final models = [
        LinkModelB.name('modelB_1'),
        LinkModelB.name('modelB_2'),
        LinkModelB.name('modelB_3'),
      ];
      await isar.writeTxn((isar) => linksB.putAll(models));
      return models;
    }

    Future linkSelfLinks(List<LinkModelA> models) {
      return isar.writeTxn((isar) async {
        final firstLinks = models[0].selfLinks;
        firstLinks.add(models[0]);
        firstLinks.add(models[1]);
        firstLinks.add(models[2]);
        await firstLinks.saveChanges();

        final secondLinks = models[1].selfLinks;
        secondLinks.add(models[0]);
        secondLinks.add(models[1]);
        await secondLinks.saveChanges();

        final thirdLinks = models[2].selfLinks;
        thirdLinks.add(models[0]);
        await thirdLinks.saveChanges();
      });
    }

    Future linkOtherLinks(List<LinkModelA> models, List<LinkModelB> models2) {
      return isar.writeTxn((isar) async {
        final firstLinks = models[0].otherLinks;
        firstLinks.add(models2[0]);
        firstLinks.add(models2[1]);
        firstLinks.add(models2[2]);
        await firstLinks.saveChanges();

        final secondLinks = models[1].otherLinks;
        secondLinks.add(models2[0]);
        secondLinks.add(models2[1]);
        await secondLinks.saveChanges();

        final thirdLinks = models[2].otherLinks;
        thirdLinks.add(models2[0]);
        await thirdLinks.saveChanges();
      });
    }

    isarTest('Single self link', () async {
      final models = await getModels();
      await linkSelfLinks(models);

      await qEqualSet(
        linksA
            .where()
            .filter()
            .selfLinks((q) => q.nameEqualTo('modelA_2'))
            .findAll(),
        {
          LinkModelA.name('modelA_1'),
          LinkModelA.name('modelA_2'),
        },
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

    /////
    ///
    ///

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
    });
  });
}
