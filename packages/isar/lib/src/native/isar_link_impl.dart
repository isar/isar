import 'dart:ffi';

import 'package:isar/src/common/isar_link_common.dart';

import 'isar_collection_impl.dart';
import 'isar_core.dart';

mixin IsarLinkBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  IsarCollectionImpl get sourceCollection =>
      super.sourceCollection as IsarCollectionImpl;

  @override
  IsarCollectionImpl<OBJ> get targetCollection =>
      super.targetCollection as IsarCollectionImpl<OBJ>;

  late final linkIndex = sourceCollection.schema.linkIdOrErr(linkName);

  @override
  late final getId = targetCollection.schema.getId;

  @override
  Future<void> updateIdsInternal(
      List<int> linkIds, List<int> unlinkIds, bool reset) {
    final containingId = requireAttached();
    return targetCollection.isar.getTxn(true, (txn) {
      final count = linkIds.length + unlinkIds.length;
      final idsPtr = txn.alloc<Int64>(count);
      final ids = idsPtr.asTypedList(count);

      ids.setAll(0, linkIds);
      ids.setAll(linkIds.length, unlinkIds);

      IC.isar_link_update_all(sourceCollection.ptr, txn.ptr, linkIndex,
          containingId, idsPtr, linkIds.length, unlinkIds.length, reset);
      return txn.wait();
    });
  }

  @override
  void updateIdsInternalSync(
      List<int> linkIds, List<int> unlinkIds, bool reset) {
    final containingId = requireAttached();
    targetCollection.isar.getTxnSync(true, (txn) {
      if (reset) {
        nCall(IC.isar_link_unlink_all(
            sourceCollection.ptr, txn.ptr, linkIndex, containingId));
      }

      for (var linkId in linkIds) {
        nCall(IC.isar_link(
            sourceCollection.ptr, txn.ptr, linkIndex, containingId, linkId));
      }
      for (var unlinkId in unlinkIds) {
        nCall(IC.isar_link_unlink(
            sourceCollection.ptr, txn.ptr, linkIndex, containingId, unlinkId));
      }
    });
  }
}

class IsarLinkImpl<OBJ> extends IsarLinkCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}

class IsarLinksImpl<OBJ> extends IsarLinksCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}
