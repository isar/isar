import 'dart:io';
import 'dart:isolate';

import 'package:isar/isar.dart';
import 'package:isar_v3_db_generator/collections/collection_a.dart';
import 'package:isar_v3_db_generator/collections/collection_b.dart';
import 'package:isar_v3_db_generator/seeders/collection_a_seeder.dart';
import 'package:isar_v3_db_generator/seeders/collection_b_seeder.dart';

Future<void> main(List<String> arguments) async {
  await Isar.initializeIsarCore(download: true);

  final isar = await openIsar();

  await isar.writeTxn(() async {
    await isar.clear();
  });

  await Future.wait([
    compute((isar) async {
      print('Seeding collection A');
      await seedCollectionA(isar);
      print('Done seeding collection A');
    }),
    compute((isar) async {
      print('Seeding collection B');
      await seedCollectionB(isar);
      print('Done seeding collection B');
    })
  ]);

  await isar.close();
}

Future<Isar> openIsar() {
  return Isar.open(
    [CollectionASchema, CollectionBSchema],
    directory: File(Platform.script.path).parent.parent.path,
    name: "isar_v3_db",
    maxSizeMiB: 2048,
  );
}

Future<void> compute(Future<void> Function(Isar) computation) async {
  await Isolate.run(() async {
    final isar = await openIsar();

    await computation(isar);

    await isar.close();
  });
}
