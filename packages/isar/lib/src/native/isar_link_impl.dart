// ignore_for_file: public_member_api_docs

import 'dart:ffi';

import 'package:isar/src/common/isar_link_common.dart';

import 'package:isar/src/native/isar_collection_impl.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_impl.dart';

mixin IsarLinkBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  IsarCollectionImpl<dynamic> get sourceCollection =>
      super.sourceCollection as IsarCollectionImpl;

  @override
  IsarCollectionImpl<OBJ> get targetCollection =>
      super.targetCollection as IsarCollectionImpl<OBJ>;

  late final int linkIndex = sourceCollection.schema.linkIdOrErr(linkName);

  @override
  late final getId = targetCollection.schema.getId;

  @override
  Future<void> update({
    List<OBJ> link = const [],
    List<OBJ> unlink = const [],
    bool reset = false,
  }) {
    final containingId = requireAttached();
    return targetCollection.isar.getTxn(true, (Txn txn) {
      final count = link.length + unlink.length;
      final idsPtr = txn.alloc<Int64>(count);
      final ids = idsPtr.asTypedList(count);

      for (var i = 0; i < link.length; i++) {
        ids[i] = requireGetId(link[i]);
      }
      for (var i = 0; i < unlink.length; i++) {
        ids[link.length + i] = requireGetId(unlink[i]);
      }

      IC.isar_link_update_all(
        sourceCollection.ptr,
        txn.ptr,
        linkIndex,
        containingId,
        idsPtr,
        link.length,
        unlink.length,
        reset,
      );
      return txn.wait();
    });
  }

  @override
  void updateSync({
    List<OBJ> link = const [],
    List<OBJ> unlink = const [],
    bool reset = false,
  }) {
    final containingId = requireAttached();
    targetCollection.isar.getTxnSync(true, (SyncTxn txn) {
      if (reset) {
        nCall(
          IC.isar_link_unlink_all(
            sourceCollection.ptr,
            txn.ptr,
            linkIndex,
            containingId,
          ),
        );
      }

      for (final object in link) {
        final id = getId(object) ??
            targetCollection.putByIndexSyncInternal(
              txn: txn,
              object: object,
            );

        nCall(
          IC.isar_link(
            sourceCollection.ptr,
            txn.ptr,
            linkIndex,
            containingId,
            id,
          ),
        );
      }
      for (final object in unlink) {
        final unlinkId = requireGetId(object);
        nCall(
          IC.isar_link_unlink(
            sourceCollection.ptr,
            txn.ptr,
            linkIndex,
            containingId,
            unlinkId,
          ),
        );
      }
    });
  }
}

class IsarLinkImpl<OBJ> extends IsarLinkCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}

class IsarLinksImpl<OBJ> extends IsarLinksCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}
