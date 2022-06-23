import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'all_tests.dart' as tests;

import 'test/util/common.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final completer = Completer<bool>();
  executeTests(completer);

  testWidgets('Isar', (WidgetTester tester) async {
    await tester.pumpWidget(Container());
    final result = await completer.future;
    expect(result, true);
  });
}

void executeTests(Completer<bool> completer) {
  group('Integration test', () {
    setUpAll(() async {
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        testTempPath = dir.path;
      }
    });
    tearDownAll(() {
      completer.complete(testCount != 0 && allTestsSuccessful);
    });

    //tests.main();
  });
}
