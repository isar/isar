import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/collection_generator.dart';
import 'package:source_gen_test/source_gen_test.dart';

Future<void> main() async {
  initializeBuildLogTracking();
  for (final file in Directory('test/successes').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    final reader = await initializeLibraryReaderForDirectory(
      file.dirName,
      file.name,
    );
    testAnnotatedElements<Collection>(
      reader,
      IsarCollectionGenerator(),
    );
  }
}
