// @dart = 2.8
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_test/isar_test_context.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar_test/all_test.dart' as tests;
import 'package:flutter_test/flutter_test.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final completer = Completer<bool>();
  executeTests(completer);

  testWidgets('Isar', (WidgetTester tester) async {
    final result = await completer.future;
    expect(result, true);
  });
}

void executeTests(Completer<bool> completer) {
  final context = IntegrationContext(false);
  final encryptionContext = IntegrationContext(true);

  group('Integration test', () {
    tearDownAll(() {
      final result = context.success && encryptionContext.success;
      completer.complete(result);
    });

    tests.run(context);
    tests.run(encryptionContext);
  });
}

class IntegrationContext extends IsarTestContext {
  IntegrationContext(bool encryption) : super(encryption);

  @override
  Future<String> getTempPath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }
}
