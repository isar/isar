import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_api/src/backend/invoker.dart';

import 'sync_async_helper.dart';

const bool kIsWeb = identical(0, 0.0);

final testErrors = <String>[];
int testCount = 0;

String _getRustTarget() {
  switch (Abi.current()) {
    case Abi.macosArm64:
      return 'aarch64-apple-darwin';
    case Abi.macosX64:
      return 'x86_64-apple-darwin';
    case Abi.linuxArm64:
      return 'aarch64-unknown-linux-gnu';
    case Abi.linuxX64:
      return 'x86_64-unknown-linux-gnu';
    case Abi.windowsX64:
      return 'x86_64-pc-windows-gnu';
    case Abi.windowsIA32:
      return 'i686-pc-windows-gnu';
    default:
      throw UnsupportedError('Unsupported ABI: ${Abi.current()}');
  }
}

var _setUp = false;
Future<void> _prepareTest() async {
  if (!kIsWeb && !_setUp) {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      try {
        final packagesDir = path.dirname(Directory.current.absolute.path);
        final target = _getRustTarget();
        final binaryName = Platform.isWindows
            ? 'isar.dll'
            : Platform.isMacOS
                ? 'libisar.dylib'
                : 'libisar.so';
        final binaryPath = path.join(
          path.dirname(packagesDir),
          'target',
          target,
          'debug',
          binaryName,
        );

        if (!File(binaryPath).existsSync()) {
          final result = Process.runSync(
            'cargo',
            ['build', '--target', target],
            workingDirectory: path.join(packagesDir, 'isar_core_ffi'),
          );
          if (result.exitCode != 0) {
            throw Exception('Cargo build failed: ${result.stderr}');
          }
        }
        await Isar.initializeIsarCore(libraries: {Abi.current(): binaryPath});
      } catch (e) {
        // ignore. maybe this is an instrumentation test
        // ignore: avoid_print
        print(e);
      }
    }

    _setUp = true;
  }
}

@isTest
void isarTest(
  String name,
  dynamic Function() body, {
  Timeout? timeout,
  bool skip = false,
  bool syncOnly = false,
}) {
  void runTest(bool syncTest) {
    final testName = syncTest ? '$name SYNC' : name;
    test(
      testName,
      () async {
        await runZoned(
          () async {
            try {
              await _prepareTest();
              await body();
              testCount++;
            } catch (e) {
              testErrors.add('$testName: $e');
              rethrow;
            }
          },
          zoneValues: {
            #syncTest: syncTest,
          },
        );
      },
      timeout: timeout ?? const Timeout(Duration(minutes: 10)),
    );
  }

  if (!syncOnly) {
    runTest(false);
  }

  if (!kIsWeb) {
    runTest(true);
  }
}

@isTest
void isarTestVm(String name, dynamic Function() body) {
  isarTest(name, body, skip: kIsWeb);
}

@isTest
void isarTestSync(String name, void Function() body) {
  isarTest(name, body, skip: kIsWeb, syncOnly: true);
}

String getRandomName() {
  final random = Random().nextInt(pow(2, 32) as int).toString();
  return '${random}_tmp';
}

String? testTempPath;
Future<Isar> openTempIsar(
  List<CollectionSchema<dynamic>> schemas, {
  String? name,
  String? directory,
  CompactCondition? compactOnLaunch,
}) async {
  await _prepareTest();
  if (!kIsWeb && directory == null && testTempPath == null) {
    final dartToolDir = path.join(Directory.current.path, '.dart_tool');
    testTempPath = path.join(dartToolDir, 'test', 'tmp');
    await Directory(testTempPath!).create(recursive: true);
  }

  final isar = await tOpen(
    schemas: schemas,
    name: name ?? getRandomName(),
    directory: directory ?? testTempPath,
    compactOnLaunch: compactOnLaunch,
  );

  if (Invoker.current != null) {
    addTearDown(() async {
      if (isar.isOpen) {
        await isar.close(deleteFromDisk: true);
      }
    });
  }

  await isar.verify();
  return isar;
}
