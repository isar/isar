// ignore_for_file: avoid_print

import 'dart:io';

import 'package:isar_test/src/rust_target.dart';
import 'package:path/path.dart' as path;

void main() {
  print('Building Isar Core');
  final rootDir = path.dirname(path.dirname(Directory.current.path));
  final rustResult = Process.runSync(
    'cargo',
    ['build', '--target', getRustTarget()],
    runInShell: true,
    workingDirectory: rootDir,
  );
  if (rustResult.exitCode != 0) {
    throw Exception('Cargo build failed: ${rustResult.stderr}');
  }

  /*print('Building Isar Web');
  final webDir = path.join(rootDir, 'packages', 'isar_web');
  final npmResult = Process.runSync(
    'npm',
    ['run', 'build'],
    runInShell: true,
    workingDirectory: webDir,
  );
  print(webDir);
  if (npmResult.exitCode != 0) {
    throw Exception('Npm build failed: ${npmResult.stderr}');
  }

  print('Packing Isar Web');
  final webpackResult = Process.runSync(
    'npx',
    ['webpack', '--mode', 'development'],
    runInShell: true,
    workingDirectory: webDir,
  );
  if (webpackResult.exitCode != 0) {
    throw Exception('Webpack build failed: ${npmResult.stderr}');
  }

  print('Writing Isar Web in the test dir');
  final isarWebSrc =
      File(path.join(webDir, 'dist', 'index.js')).readAsStringSync();
  final escaped = isarWebSrc.replaceAll(r'$', r'\$');
  File('lib/src/isar_web_src.dart').writeAsStringSync(
    '// ignore_for_file: unnecessary_string_escapes\n'
    "const isarWebSrc = '''\n$escaped''';",
  );*/
}
