import 'package:isar/isar.dart';
import 'package:isar/src/dart_engine/engine.dart';

Future<Isar> openIsar({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
}) async {
  return DartEngineIsar(name, schemas);
}

Isar openIsarSync({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
}) {
  throw UnsupportedError('Synchronous Isar.open is not supported on web.');
}
