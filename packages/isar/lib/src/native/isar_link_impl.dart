import 'dart:ffi';
import 'dart:typed_data';

import '../common/isar_link_common.dart';

import 'isar_collection_impl.dart';
import 'isar_core.dart';
import 'isar_impl.dart';

mixin IsarLinkBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  IsarCollectionImpl<dynamic> get sourceCollection =>
      super.sourceCollection as IsarCollectionImpl;

  @override
  IsarCollectionImpl<OBJ> get targetCollection =>
      super.targetCollection as IsarCollectionImpl<OBJ>;

  late final int linkIndex = sourceCollection.schema.linkIdOrErr(linkName);

  @override
  late final int? Function(object) getId = targetCollection.schema.getId;

  @override
  Future<void> updateNative(
      List<int> linkIds, List<int> unlinkIds, bool reset) {
    final int containingId = requireAttached();
    return targetCollection.isar.getTxn(true, (Txn txn) {
      final int count = linkIds.length + unlinkIds.length;
      final Pointer<Int64> idsPtr = txn.alloc<Int64>(count);
      final Int64List ids = idsPtr.asTypedList(count);

      ids.setAll(0, linkIds);
      ids.setAll(linkIds.length, unlinkIds);

      IC.isar_link_update_all(sourceCollection.ptr, txn.ptr, linkIndex,
          containingId, idsPtr, linkIds.length, unlinkIds.length, reset);
      return txn.wait();
    });
  }

  @override
  void updateNativeSync(List<int> linkIds, List<int> unlinkIds, bool reset) {
    final int containingId = requireAttached();
    targetCollection.isar.getTxnSync(true, (SyncTxn txn) {
      if (reset) {
        nCall(IC.isar_link_unlink_all(
            sourceCollection.ptr, txn.ptr, linkIndex, containingId));
      }

      for (final int linkId in linkIds) {
        nCall(IC.isar_link(
            sourceCollection.ptr, txn.ptr, linkIndex, containingId, linkId));
      }
      for (final int unlinkId in unlinkIds) {
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
