// ignore_for_file: public_member_api_docs

import 'package:isar/src/common/isar_link_common.dart';
import 'package:isar/src/web/bindings.dart';

import 'package:isar/src/web/isar_collection_impl.dart';
import 'package:isar/src/web/isar_web.dart';

mixin IsarLinkBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  IsarCollectionImpl<dynamic> get sourceCollection =>
      super.sourceCollection as IsarCollectionImpl;

  @override
  IsarCollectionImpl<OBJ> get targetCollection =>
      super.targetCollection as IsarCollectionImpl<OBJ>;

  @override
  late final int? Function(OBJ) getId = targetCollection.schema.getId;

  late final String? backlinkLinkName =
      sourceCollection.schema.backlinkLinkNames[linkName];

  late final IsarLinkJs jsLink = backlinkLinkName != null
      ? targetCollection.native.getLink(backlinkLinkName!)
      : sourceCollection.native.getLink(linkName);

  @override
  Future<void> update({
    List<OBJ> link = const [],
    List<OBJ> unlink = const [],
    bool reset = false,
  }) {
    final containingId = requireAttached();
    final backlink = backlinkLinkName != null;

    final linkIds = List.filled(link.length, 0);
    for (var i = 0; i < link.length; i++) {
      linkIds[i] = requireGetId(link[i]);
    }

    final unlinkIds = List.filled(unlink.length, 0);
    for (var i = 0; i < unlink.length; i++) {
      unlinkIds[i] = requireGetId(unlink[i]);
    }

    return targetCollection.isar.getTxn(true, (IsarTxnJs txn) async {
      if (reset) {
        await jsLink.clear(txn, containingId, backlink).wait<dynamic>();
      }
      return jsLink
          .update(txn, backlink, containingId, linkIds, unlinkIds)
          .wait();
    });
  }

  @override
  void updateSync({
    List<OBJ> link = const [],
    List<OBJ> unlink = const [],
    bool reset = false,
  }) =>
      unsupportedOnWeb();
}

class IsarLinkImpl<OBJ> extends IsarLinkCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}

class IsarLinksImpl<OBJ> extends IsarLinksCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}
