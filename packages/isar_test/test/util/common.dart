import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'sync_async_helper.dart';

const bool kIsWeb = identical(0, 0.0);

Future<void> qEqualSet<T>(
  Future<Iterable<T>> actual,
  Iterable<T> target,
) async {
  expect((await actual).toSet(), target.toSet());
}

Future<void> qEqual<T>(Future<Iterable<T>> actual, List<T> target) async {
  final results = (await actual).toList();
  await qEqualSync(results, target);
}

Future<void> qEqualSync<T>(List<T> actual, List<T> target) async {
  if (actual is List<double?>) {
    for (var i = 0; i < actual.length; i++) {
      final result = (actual[i] as double) - (target[i] as double);
      expect(result.abs() < 0.01, true);
    }
  } else if (actual is List<List<double?>?>) {
    for (var i = 0; i < actual.length; i++) {
      await qEqualSync(actual[i] as List, target[i] as List);
    }
  } else {
    expect(actual, target);
  }
}

final testErrors = <String>[];
int testCount = 0;

Future<void> _prepareTest() async {
  if (!kIsWeb) {
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (e) {
      // ignore. maybe this is an instrumentation test
    }
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
  void runTest(bool testSync) {
    final testName = testSync ? '$name SYNC' : name;
    runZoned(
      zoneValues: {'testSync': testSync},
      () {
        test(
          testName,
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
          timeout: timeout,
          skip: skip,
        );
      },
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
}) async {
  await _prepareTest();
  if (!kIsWeb && testTempPath == null) {
    final dartToolDir = path.join(Directory.current.path, '.dart_tool');
    testTempPath = path.join(dartToolDir, 'test', 'tmp');
    await Directory(testTempPath!).create(recursive: true);
  }

  return tOpen(
    schemas: schemas,
    name: name ?? getRandomName(),
    directory: kIsWeb ? '' : testTempPath!,
  );
}

bool doubleListEquals(List<double?>? l1, List<double?>? l2) {
  if (l1?.length != l2?.length) {
    return false;
  }
  if (l1 != null && l2 != null) {
    for (var i = 0; i < l1.length; i++) {
      final e1 = l1[i];
      final e2 = l2[i];
      if (e1 != null && e2 != null) {
        if ((e1 - e2).abs() > 0.001) {
          return false;
        }
      } else if (e1 != null || e2 != null) {
        return false;
      }
    }
  }
  return true;
}

Matcher isIsarError([String? contains]) {
  return allOf(
    isA<IsarError>(),
    predicate(
      (IsarError e) =>
          contains == null ||
          e.toString().toLowerCase().contains(contains.toLowerCase()),
    ),
  );
}

Matcher throwsIsarError([String? contains]) {
  return throwsA(isIsarError(contains));
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
