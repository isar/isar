// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_test/isar_test.dart';
import 'package:path_provider/path_provider.dart';

import 'all_tests.dart' as tests;

void main() async {
  final dir = await getTemporaryDirectory();
  testTempPath = dir.path;
  tests.main();
}
