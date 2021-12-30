import 'package:isar/isar.dart';
import 'package:isar_test/utils/common.dart';
import 'package:isar_test/utils/open.dart';

import 'package:test/test.dart';

import 'package:isar_test/link_model.dart';

void main() {
  group('Links', () {
    late Isar isar;
    late IsarCollection<LinkModelA> linksA;
    late IsarCollection<LinkModelB> linksB;

    setUp(() async {
      isar = await openTempIsar([LinkModelASchema, LinkModelBSchema]);
      linksA = isar.linkModelAs;
      linksB = isar.linkModelBs;
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('add self link', () async {
      final linkedModel = LinkModelA.name('linked');
      await isar.writeTxn((isar) async {
        linkedModel.id = await linksA.put(linkedModel);
      });

      final model = LinkModelA.name('model');
      model.selfLink.value = linkedModel;
      await isar.writeTxn((isar) async {
        model.id = await linksA.put(model);
        await model.selfLink.save();
      });

      model.selfLink.value = null;
      await model.selfLink.load();
      expect(model.selfLink.value, LinkModelA.name('linked'));

      await linkedModel.selfLinkBacklink.load();
      expect(linkedModel.selfLinkBacklink, {LinkModelA.name('model')});
    });

    isarTest('add other link', () async {
      final linkedModel = LinkModelB.name('linked');
      linkedModel.id = 5;
      await isar.writeTxn((isar) async {
        linkedModel.id = await linksB.put(linkedModel);
      });

      final model = LinkModelA.name('model');
      model.otherLink.value = linkedModel;
      await isar.writeTxn((isar) async {
        model.id = await linksA.put(model);
        await model.otherLink.save();
      });

      model.otherLink.value = null;
      await model.otherLink.load();
      expect(model.otherLink.value, LinkModelB.name('linked'));

      await linkedModel.linkBacklinks.load();
      expect(linkedModel.linkBacklinks, {LinkModelA.name('model')});
    });

    isarTest('add self links', () async {
      final linkedModel1 = LinkModelA.name('linked1');
      final linkedModel2 = LinkModelA.name('linked2');
      await isar.writeTxn((isar) async {
        linkedModel1.id = await linksA.put(linkedModel1);
        linkedModel2.id = await linksA.put(linkedModel2);
      });

      final model = LinkModelA.name('model');
      model.selfLinks.add(linkedModel1);
      model.selfLinks.add(linkedModel2);
      await isar.writeTxn((isar) async {
        model.id = await linksA.put(model);
        await model.selfLinks.saveChanges();
      });

      /*model.selfLinks.clear();
      await model.selfLinks.load();
      expect(model.selfLinks,
          {LinkModelA.name('linked1'), LinkModelA.name('linked2')});*/

      await linkedModel1.selfLinksBacklink.load();
      expect(linkedModel1.selfLinksBacklink, {LinkModelA.name('model')});
      await linkedModel2.selfLinksBacklink.load();
      expect(linkedModel2.selfLinksBacklink, {LinkModelA.name('model')});
    });

    isarTest('add other links', () async {
      final linkedModel1 = LinkModelB.name('linked1');
      final linkedModel2 = LinkModelB.name('linked2');
      await isar.writeTxn((isar) async {
        linkedModel1.id = await linksB.put(linkedModel1);
        linkedModel2.id = await linksB.put(linkedModel2);
      });

      final model = LinkModelA.name('model');
      model.otherLinks.add(linkedModel1);
      model.otherLinks.add(linkedModel2);
      await isar.writeTxn((isar) async {
        model.id = await linksA.put(model);
        await model.otherLinks.saveChanges();
      });

      model.otherLinks.clear();
      await model.otherLinks.load();
      expect(model.otherLinks,
          {LinkModelB.name('linked1'), LinkModelB.name('linked2')});

      await linkedModel1.linksBacklinks.load();
      expect(linkedModel1.linksBacklinks, {LinkModelA.name('model')});
      await linkedModel2.linksBacklinks.load();
      expect(linkedModel2.linksBacklinks, {LinkModelA.name('model')});
    });
  });
}
