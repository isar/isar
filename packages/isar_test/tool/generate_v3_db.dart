// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as path;

/// Script used to generate the v3 database file and move it into the
/// `assets` folder.
Future<void> main() async {
  print('Starting v3 database file generation');
  await Process.run('dart', [getGeneratorPath()]);
  print('Done generating v3 database file');

  print('Copying v3 database file');
  final file = getSourceFile();
  if (!file.existsSync()) {
    throw Exception('Failed to generate v3 database file');
  }

  file.copySync(getDestinationFile().path);
  print('Done copying v3 database file');
}

String getGeneratorPath() {
  final currentScript = File(Platform.script.path);

  return path.join(
    currentScript.parent.path,
    'isar_v3_db_generator/bin/isar_v3_db_generator.dart',
  );
}

File getSourceFile() {
  final currentScript = File(Platform.script.path);

  return File(
    path.join(
      currentScript.parent.path,
      'isar_v3_db_generator/isar_v3_db.isar',
    ),
  );
}

File getDestinationFile() {
  final currentScript = File(Platform.script.path);

  return File(
    path.join(
      currentScript.parent.parent.path,
      'assets/isar_v3_db.isar',
    ),
  );
}
