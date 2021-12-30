// @dart = 2.8
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_test/utils/common.dart';
import 'package:path_provider/path_provider.dart';
import 'all_tests.dart' as tests;
import 'package:flutter_test/flutter_test.dart';

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
      final dir = await getTemporaryDirectory();
      testTempPath = dir.path;
    });
    tearDownAll(() {
      completer.complete(allTestsSuccessful);
    });

    tests.run();
  });
}
