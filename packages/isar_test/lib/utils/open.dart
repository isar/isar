import 'package:isar/isar.dart';
import 'package:isar_test/utils/common.dart';

Future<Isar> openTempIsar(List<CollectionSchema<dynamic>> collections) async {
  registerBinaries();

  return Isar.open(
    collections: collections,
    name: getRandomName(),
    directory: testTempPath!,
  );
}
