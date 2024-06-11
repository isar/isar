import 'package:isar/isar.dart';
import 'package:isar_v3_db_generator/collections/collection_a.dart';
import 'package:isar_v3_db_generator/seeders/collection_a_seeder.dart';

Future<void> main(List<String> arguments) async {
  await Isar.initializeIsarCore(download: true);

  final isar = await Isar.open(
    [CollectionASchema],
    directory: ".",
    name: "isar_v3_db",
  );

  await isar.writeTxn(() async {
    await isar.clear();
  });

  await seedCollectionA(isar);

  await isar.close();
}
