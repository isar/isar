import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;
import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'collection_a.dart';
import 'collection_b.dart';

void main() {
  group('v3 to v4 migration', () {
    late final Isar isar;

    late final List<CollectionA> collectionAObjects;
    late final List<CollectionB> collectionBObjects;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      await prepareTest();
      final databaseFile = await _importV3IsarDatabase();

      // await Future.delayed(const Duration(seconds: 10));

      isar = await openTempIsar(
        [CollectionASchema, CollectionBSchema],
        directory: databaseFile.parent.path,
        name: path.basenameWithoutExtension(databaseFile.path),
        closeAutomatically: false,
        maxSizeMiB: 4096,
      );

      collectionAObjects = generateCollectionAObjects();
      collectionBObjects = generateCollectionBObjects();
    });

    isarTest(
      'Integrity check should pass',
      sqlite: false,
      web: false,
      () {
        isar.verify();
      },
    );

    isarTest(
      'Every CollectionA object should have the same value as the v3 database',
      sqlite: false,
      web: false,
      () async {
        final databaseObjects = await isar.collectionAs.where().findAllAsync();

        expect(databaseObjects.length, collectionAObjects.length);
        expect(databaseObjects, collectionAObjects);
      },
    );

    isarTest(
      'Every CollectionB object should have the same value as the v3 database',
      sqlite: false,
      web: false,
      () async {
        final databaseObjects = await isar.collectionBs.where().findAllAsync();

        expect(databaseObjects.length, collectionBObjects.length);
        expect(databaseObjects, collectionBObjects);
      },
    );
  });
}

Future<File> _importV3IsarDatabase() async {
  final bytes = await rootBundle.load('assets/isar_v3_db.isar');
  final file = File(path.join(testTempPath!, 'isar_v3_db.isar'));
  await file.writeAsBytes(bytes.buffer.asUint8List());

  return file;
}
