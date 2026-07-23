// ignore_for_file: public_member_api_docs

import 'package:isar/src/common/isar_link_base_impl.dart';
import 'package:isar/src/common/isar_link_backend.dart';
import 'package:isar/src/common/isar_link_common.dart';
import 'package:isar/src/common/isar_links_common.dart';

mixin IsarLinkBaseMixin<OBJ> on IsarLinkBaseImpl<OBJ> {
  @override
  late final getId = targetCollection.schema.getId;

  @override
  Future<void> update({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  }) =>
      (sourceCollection as IsarLinkBackend).updateLinkBackend(
        targetCollection: targetCollection,
        linkName: linkName,
        sourceId: requireAttached(),
        link: link,
        unlink: unlink,
        reset: reset,
      );

  @override
  void updateSync({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  }) =>
      (sourceCollection as IsarLinkBackend).updateLinkBackendSync(
        targetCollection: targetCollection,
        linkName: linkName,
        sourceId: requireAttached(),
        link: link,
        unlink: unlink,
        reset: reset,
      );
}

class IsarLinkImpl<OBJ> extends IsarLinkCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}

class IsarLinksImpl<OBJ> extends IsarLinksCommon<OBJ>
    with IsarLinkBaseMixin<OBJ> {}
