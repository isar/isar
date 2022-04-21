import 'package:isar/src/common/isar_link_common.dart';
import 'package:isar/src/web/bindings.dart';

import 'isar_collection_impl.dart';
import 'isar_web.dart';

mixin IsarLinkBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  IsarCollectionImpl<OBJ> get sourceCollection =>
      super.sourceCollection as IsarCollectionImpl<OBJ>;

  @override
  late final IsarCollectionImpl<OBJ> targetCollection = sourceCollection.schema
          .linkColOrErr(sourceCollection.isar, linkName, false)
      as IsarCollectionImpl<OBJ>;

  @override
  late final getId = targetCollection.schema.getId;

  late final IsarLinkJs link = sourceCollection.native.getLink(linkName);

  late final isBacklink =
      sourceCollection.schema.backlinkSourceCollections.containsKey(linkName);

  @override
  Future<void> updateIdsInternal(
      List<int> linkIds, List<int> unlinkIds, bool reset) {
    final containingId = requireAttached();

    return targetCollection.isar.getTxn(true, (txn) {
      return link
          .update(txn, containingId, linkIds, linkIds, isBacklink)
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
