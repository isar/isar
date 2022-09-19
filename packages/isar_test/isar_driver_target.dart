// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_test/isar_test.dart';
import 'package:path_provider/path_provider.dart';

import 'all_tests.dart' as tests;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final completer = Completer<List<String>>();
  executeTests(completer);

  testWidgets('Isar', (WidgetTester tester) async {
    await tester.pumpWidget(Container());
    final errors = await completer.future;
    for (final err in errors) {
      print(err);
    }
    expect(errors.isEmpty, true);
  });
}

void executeTests(Completer<List<String>> completer) {
  group('Integration test', () {
    setUpAll(() async {
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        testTempPath = dir.path;
      }
    });
    tearDownAll(() {
      final result = testCount == 0 ? ['No tests were executed'] : testErrors;
      completer.complete(result);
    });

    tests.main();
  });
}
