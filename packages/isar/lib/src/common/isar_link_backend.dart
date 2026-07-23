import 'package:isar/isar.dart';

/// Internal backend-neutral dispatch used by generated link objects.
abstract interface class IsarLinkBackend {
  Future<void> updateLinkBackend<OBJ>({
    required IsarCollection<OBJ> targetCollection,
    required String linkName,
    required Id sourceId,
    required Iterable<OBJ> link,
    required Iterable<OBJ> unlink,
    required bool reset,
  });

  void updateLinkBackendSync<OBJ>({
    required IsarCollection<OBJ> targetCollection,
    required String linkName,
    required Id sourceId,
    required Iterable<OBJ> link,
    required Iterable<OBJ> unlink,
    required bool reset,
  });
}
