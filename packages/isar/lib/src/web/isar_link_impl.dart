import '../common/isar_link_common.dart';
import 'bindings.dart';

import 'isar_collection_impl.dart';
import 'isar_web.dart';

mixin IsarLinkBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  IsarCollectionImpl<dynamic> get sourceCollection =>
      super.sourceCollection as IsarCollectionImpl;

  @override
  IsarCollectionImpl<OBJ> get targetCollection =>
      super.targetCollection as IsarCollectionImpl<OBJ>;

  @override
  late final int? Function(object) getId = targetCollection.schema.getId;

  late final String? backlinkLinkName =
      sourceCollection.schema.backlinkLinkNames[linkName];

  late final IsarLinkJs link = backlinkLinkName != null
      ? targetCollection.native.getLink(backlinkLinkName!)
      : sourceCollection.native.getLink(linkName);

  @override
  Future<void> updateNative(
      List<int> linkIds, List<int> unlinkIds, bool reset) {
    final int containingId = requireAttached();
    final bool backlink = backlinkLinkName != null;

    return targetCollection.isar.getTxn(true, (IsarTxnJs txn) async {
      if (reset) {
        await link.clear(txn, containingId, backlink).wait<dynamic>();
      }
      return link
          .update(txn, backlink, containingId, linkIds, unlinkIds)
          .wait();
    });
  }

  @override
  void updateNativeSync(List<int> linkIds, List<int> unlinkIds, bool reset) =>
      unsupportedOnWeb();
}

class IsarLinkImpl<OBJ> extends IsarLinkCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}

class IsarLinksImpl<OBJ> extends IsarLinksCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}
