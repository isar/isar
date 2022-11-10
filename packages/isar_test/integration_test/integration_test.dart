// ignore_for_file: avoid_print

import 'package:isar_test/isar_test.dart';
import 'package:path_provider/path_provider.dart';

import 'all_tests.dart' as tests;

void main() async {
  final dir = await getTemporaryDirectory();
  testTempPath = dir.path;
  tests.main();
}
