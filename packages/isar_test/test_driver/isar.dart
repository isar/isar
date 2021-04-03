// @dart = 2.8
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import '../test/common.dart';
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
  //final context = IntegrationContext(false);
  //final encryptionContext = IntegrationContext(true);

  group('Integration test', () {
    setUpAll(() async {
      final dir = await getTemporaryDirectory();
      testTempPath = dir.path;
    });
    tearDownAll(() {
      final result = allTestsSuccessful;
      //context.success && encryptionContext.success;
      completer.complete(result);
    });

    group('unencrypted', () {
      setUpAll(() async {
        testEncryption = false;
      });
      tests.run();
    });

    group('encrypted', () {
      setUpAll(() async {
        testEncryption = true;
      });
      tests.run();
    });
  });
}
