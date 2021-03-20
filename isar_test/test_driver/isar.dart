// @dart = 2.8
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:isar_test/isar_test_context.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar_test/all_test.dart' as tests;
import 'package:test/test.dart';

void main() {
  final completer = Completer<String>();
  enableFlutterDriverExtension(handler: (_) => completer.future);

  final context = IntegrationContext(false);
  final encryptionContext = IntegrationContext(true);

  tearDownAll(() {
    final result = context.success && encryptionContext.success;
    completer.complete(result.toString());
  });

  group('driver', () {
    tests.run(context);
    tests.run(encryptionContext);
  });

  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Running Isar tests'),
        ),
      ),
    ),
  );
}

class IntegrationContext extends IsarTestContext {
  IntegrationContext(bool encryption) : super(encryption);

  @override
  Future<String> getTempPath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }
}
