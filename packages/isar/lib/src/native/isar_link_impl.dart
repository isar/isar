// ignore_for_file: public_member_api_docs

import 'dart:ffi';

import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_link_base_impl.dart';
import 'package:isar/src/common/isar_link_common.dart';
import 'package:isar/src/common/isar_links_common.dart';
import 'package:isar/src/dart_engine/engine.dart';
import 'package:isar/src/native/isar_collection_impl.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/txn.dart';

mixin IsarLinkBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  late final int linkId = sourceCollection.schema.link(linkName).id;

  @override
  late final getId = targetCollection.schema.getId;

  @override
  Future<void> update({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  }) {
    final linkList = link.toList();
    final unlinkList = unlink.toList();

    final containingId = requireAttached();
    if (sourceCollection is DartEngineCollection<dynamic>) {
      final source = sourceCollection as DartEngineCollection<dynamic>;
      return source.isar.getTxn(true, (EngineTransaction txn) async {
        source.isar.updateLink(
          txn,
          source.name,
          linkName,
          containingId,
          add: linkList.map(requireGetId),
          remove: unlinkList.map(requireGetId),
          reset: reset,
        );
      });
    }

    final source = sourceCollection as IsarCollectionImpl<dynamic>;
    final target = targetCollection as IsarCollectionImpl<OBJ>;
    return target.isar.getTxn(true, (Txn txn) {
      final count = linkList.length + unlinkList.length;
      final idsPtr = txn.alloc<Int64>(count);
      final ids = idsPtr.asTypedList(count);

      for (var i = 0; i < linkList.length; i++) {
        ids[i] = requireGetId(linkList[i]);
      }
      for (var i = 0; i < unlinkList.length; i++) {
        ids[linkList.length + i] = requireGetId(unlinkList[i]);
      }

      IC.isar_link_update_all(
        source.ptr,
        txn.ptr,
        linkId,
        containingId,
        idsPtr,
        linkList.length,
        unlinkList.length,
        reset,
      );
      return txn.wait();
    });
  }

  @override
  void updateSync({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  }) {
    final containingId = requireAttached();
    if (sourceCollection is DartEngineCollection<dynamic>) {
      final source = sourceCollection as DartEngineCollection<dynamic>;
      final target = targetCollection as DartEngineCollection<OBJ>;
      source.isar.getTxnSync(true, (EngineTransaction txn) {
        final add = <Id>[];
        for (final object in link) {
          var id = getId(object);
          if (id == Isar.autoIncrement) {
            id = target.putSync(object, saveLinks: false);
          }
          add.add(id);
        }
        source.isar.updateLink(
          txn,
          source.name,
          linkName,
          containingId,
          add: add,
          remove: unlink.map(requireGetId),
          reset: reset,
        );
      });
      return;
    }

    final source = sourceCollection as IsarCollectionImpl<dynamic>;
    final target = targetCollection as IsarCollectionImpl<OBJ>;
    target.isar.getTxnSync(true, (Txn txn) {
      if (reset) {
        nCall(
          IC.isar_link_unlink_all(
            source.ptr,
            txn.ptr,
            linkId,
            containingId,
          ),
        );
      }

      for (final object in link) {
        var id = getId(object);
        if (id == Isar.autoIncrement) {
          id = target.putByIndexSyncInternal(
            txn: txn,
            object: object,
          );
        }

        nCall(
          IC.isar_link(
            source.ptr,
            txn.ptr,
            linkId,
            containingId,
            id,
          ),
        );
      }
      for (final object in unlink) {
        final unlinkId = requireGetId(object);
        nCall(
          IC.isar_link_unlink(
            source.ptr,
            txn.ptr,
            linkId,
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
