import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'isar.g.dart';
import 'models/link_model.dart';

void main() {
  group('CRUD', () {
    late Isar isar;
    late IsarCollection<LinkModel> linkModels;
    late IsarCollection<LinkModel2> linkModel2s;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      linkModels = isar.linkModels;
      linkModel2s = isar.linkModel2s;
    });

    test('add self link', () async {
      final linkedModel = LinkModel.name('linked');
      await isar.writeTxn((isar) async {
        await linkModels.put(linkedModel);
      });

      final model = LinkModel.name('model');
      model.selfLink.value = linkedModel;
      await isar.writeTxn((isar) async {
        await linkModels.put(model);
        await model.selfLink.save();
      });

      model.selfLink.value = null;
      await model.selfLink.load();
      expect(model.selfLink.value, LinkModel.name('linked'));

      await linkedModel.selfLinkBacklink.load();
      expect(linkedModel.selfLinkBacklink, {LinkModel.name('model')});
    });

    test('add other link', () async {
      final linkedModel = LinkModel2.name('linked');
      await isar.writeTxn((isar) async {
        await linkModel2s.put(linkedModel);
      });

      final model = LinkModel.name('model');
      model.otherLink.value = linkedModel;
      await isar.writeTxn((isar) async {
        await linkModels.put(model);
        await model.otherLink.save();
      });

      model.otherLink.value = null;
      await model.otherLink.load();
      expect(model.otherLink.value, LinkModel2.name('linked'));

      await linkedModel.linkBacklinks.load();
      expect(linkedModel.linkBacklinks, {LinkModel.name('model')});
    });

    test('add self links', () async {
      final linkedModel1 = LinkModel.name('linked1');
      final linkedModel2 = LinkModel.name('linked2');
      await isar.writeTxn((isar) async {
        await linkModels.put(linkedModel1);
        await linkModels.put(linkedModel2);
      });

      final model = LinkModel.name('model');
      model.selfLinks.add(linkedModel1);
      model.selfLinks.add(linkedModel2);
      await isar.writeTxn((isar) async {
        await linkModels.put(model);
        await model.selfLinks.saveChanges();
      });

      model.selfLinks.clear();
      await model.selfLinks.load();
      expect(model.selfLinks,
          {LinkModel.name('linked1'), LinkModel.name('linked2')});

      await linkedModel1.selfLinksBacklink.load();
      expect(linkedModel1.selfLinksBacklink, {LinkModel.name('model')});
      await linkedModel2.selfLinksBacklink.load();
      expect(linkedModel2.selfLinksBacklink, {LinkModel.name('model')});
    });

    test('add other links', () async {
      final linkedModel1 = LinkModel2.name('linked1');
      final linkedModel2 = LinkModel2.name('linked2');
      await isar.writeTxn((isar) async {
        await linkModel2s.put(linkedModel1);
        await linkModel2s.put(linkedModel2);
      });

      final model = LinkModel.name('model');
      model.otherLinks.add(linkedModel1);
      model.otherLinks.add(linkedModel2);
      await isar.writeTxn((isar) async {
        await linkModels.put(model);
        await model.otherLinks.saveChanges();
      });

      model.otherLinks.clear();
      await model.otherLinks.load();
      expect(model.otherLinks,
          {LinkModel2.name('linked1'), LinkModel2.name('linked2')});

      await linkedModel1.linksBacklinks.load();
      expect(linkedModel1.linksBacklinks, {LinkModel.name('model')});
      await linkedModel2.linksBacklinks.load();
      expect(linkedModel2.linksBacklinks, {LinkModel.name('model')});
    });
  });
}
