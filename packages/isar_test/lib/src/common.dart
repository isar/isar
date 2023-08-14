import 'dart:async';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:isar_test/src/init_native.dart'
    if (dart.library.html) 'package:isar_test/src/init_web.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:test_api/src/backend/invoker.dart';

export 'package:isar_test/src/init_native.dart'
    if (dart.library.html) 'package:isar_test/src/init_web.dart';

final testErrors = <String>[];
int testCount = 0;

String getRandomName() {
  final random = Random().nextInt(pow(2, 32) as int).toString();
  return '${random}_tmp';
}

String? testTempPath;
Future<Isar> openTempIsar(
  List<IsarGeneratedSchema> schemas, {
  String? name,
  String? directory,
  int maxSizeMiB = Isar.defaultMaxSizeMiB,
  String? encryptionKey,
  CompactCondition? compactOnLaunch,
  bool closeAutomatically = true,
}) async {
  await prepareTest();

  final isar = Isar.open(
    schemas: schemas,
    name: name ?? getRandomName(),
    directory: directory ?? testTempPath ?? Isar.sqliteInMemory,
    engine: isSQLite ? IsarEngine.sqlite : IsarEngine.isar,
    maxSizeMiB: maxSizeMiB,
    encryptionKey: encryptionKey,
    compactOnLaunch: compactOnLaunch,
  );

  if (closeAutomatically) {
    addTearDown(() async {
      if (isar.isOpen) {
        isar.close(deleteFromDisk: true);
      }
    });
  }

  return isar;
}

String get _testName => Invoker.current!.liveTest.test.name;

bool get isSQLite => _testName.endsWith('(sqlite)');

const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

@isTestGroup
void isarTest(
  String name,
  FutureOr<void> Function() body, {
  Timeout? timeout,
  bool skip = false,
  bool isar = true,
  bool sqlite = true,
  bool web = true,
}) {
  testCount++;
  group(name, () {
    if (isar && !kIsWeb) {
      test(
        '(isar)',
        () async {
          try {
            await body();
          } catch (e, s) {
            testErrors.add('$name (isar): $e\n$s');
            rethrow;
          }
        },
        timeout: timeout,
        skip: skip,
      );
    }

    if ((!kIsWeb && sqlite) || (kIsWeb && web)) {
      test(
        '(sqlite)',
        () async {
          try {
            await body();
          } catch (e, s) {
            testErrors.add('$name (sqlite): $e\n$s');
            rethrow;
          }
        },
        timeout: timeout,
        skip: skip,
      );
    }
  });
}

extension IsarCollectionX<ID, OBJ> on IsarCollection<ID, OBJ> {
  void verify(List<OBJ> objects) {
    // ignore: invalid_use_of_visible_for_testing_member
    isar.verify();
    expect(where().findAll(), objects);
  }
}
