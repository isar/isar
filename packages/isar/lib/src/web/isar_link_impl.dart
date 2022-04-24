import 'package:isar/src/common/isar_link_common.dart';
import 'package:isar/src/web/bindings.dart';

import 'isar_collection_impl.dart';
import 'isar_web.dart';

mixin IsarLinkBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  IsarCollectionImpl get sourceCollection =>
      super.sourceCollection as IsarCollectionImpl;

  @override
  IsarCollectionImpl<OBJ> get targetCollection =>
      super.targetCollection as IsarCollectionImpl<OBJ>;

  @override
  late final getId = targetCollection.schema.getId;

  late final backlinkLinkName =
      sourceCollection.schema.backlinkLinkNames[linkName];

  late final link = backlinkLinkName != null
      ? targetCollection.native.getLink(backlinkLinkName!)
      : sourceCollection.native.getLink(linkName);

  @override
  Future<void> updateIdsInternal(
      List<int> linkIds, List<int> unlinkIds, bool reset) {
    final containingId = requireAttached();
    final backlink = backlinkLinkName != null;

    return targetCollection.isar.getTxn(true, (txn) async {
      if (reset) {
        await link.clear(txn, containingId, backlink).wait();
      }
      return await link
          .update(txn, backlink, containingId, linkIds, unlinkIds)
          .wait();
    });
  }

  @override
  void updateIdsInternalSync(
          List<int> linkIds, List<int> unlinkIds, bool reset) =>
      unsupportedOnWeb();
}

class IsarLinkImpl<OBJ> extends IsarLinkCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}

class IsarLinksImpl<OBJ> extends IsarLinksCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}
