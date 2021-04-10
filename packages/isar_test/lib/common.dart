// ignore_for_file: implementation_imports
import 'dart:io';
import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'package:isar/src/isar_native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:isar_test/isar.g.dart' as gen;

import 'dart:math';

import 'package:test/test.dart';

Future qEqualSet<T>(Future<Iterable<T>> actual, Iterable<T> target) async {
  expect((await actual).toSet(), target.toSet());
}

Future qEqual<T>(Future<Iterable<T>> actual, List<T> target) async {
  final results = (await actual).toList();
  qEqualSync(results, target);
}

Future qEqualSync<T>(List<T> actual, List<T> target) async {
  if (actual is List<double?>) {
    for (var i = 0; i < actual.length; i++) {
      final result = (actual[i] as double) - (target[i] as double);
      expect(result.abs() < 0.01, true);
    }
  } else if (actual is List<List<double?>?>) {
    for (var i = 0; i < actual.length; i++) {
      qEqualSync((actual[i] as List), (target[i] as List));
    }
  } else {
    expect(actual, target);
  }
}

var allTestsSuccessful = true;

@isTest
void isarTest(String name, dynamic Function() body) {
  test(name, () async {
    try {
      await body();
    } catch (e) {
      allTestsSuccessful = false;
      rethrow;
    }
  });
}

var testEncryption = false;
String? testTempPath;

void registerBinaries() {
  if (testTempPath == null) {
    final dartToolDir = path.join(Directory.current.path, '.dart_tool');
    testTempPath = path.join(dartToolDir, 'test', 'tmp');
    initializeIsarCore(dylibs: {
      'windows': path.join(dartToolDir, 'isar_windows_x64.dll'),
      'macos': path.join(dartToolDir, 'libisar_macos_x64.dylib'),
      'linux': path.join(dartToolDir, 'libisar_linux_x64.so'),
    });
  }
}

String getRandomName() {
  var random = Random().nextInt(pow(2, 32) as int);
  return '${random}_tmp';
}

Future<Isar> openTempIsar() async {
  registerBinaries();

  Uint8List? encryptionKey;
  if (testEncryption) {
    encryptionKey = Isar.generateSecureKey();
  }

  return gen.openIsar(
    name: getRandomName(),
    directory: testTempPath,
    encryptionKey: encryptionKey,
  );
}
