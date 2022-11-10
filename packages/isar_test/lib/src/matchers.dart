import 'package:isar/isar.dart';
import 'package:isar_test/src/sync_async_helper.dart';
import 'package:test/test.dart';

Future<void> qEqualSet<T>(
  QueryBuilder<dynamic, T, QQueryOperations> query,
  Iterable<T> target,
) async {
  final results = (await query.tFindAll()).toList();
  expect(results.toSet(), target.toSet());
}

Future<void> qEqual<T>(
  QueryBuilder<dynamic, T, QQueryOperations> query,
  List<T> target,
) async {
  final results = (await query.tFindAll()).toList();
  await qEqualSync(results, target);
}

Future<void> qEqualSync<T>(List<T> actual, List<T> target) async {
  if (actual is List<double?>) {
    for (var i = 0; i < actual.length; i++) {
      expect(doubleListEquals(actual.cast(), target.cast()), true);
    }
  } else if (actual is List<List<double?>?>) {
    for (var i = 0; i < actual.length; i++) {
      doubleListEquals(
        actual[i] as List<double?>?,
        target[i] as List<double?>?,
      );
    }
  } else {
    expect(actual, target);
  }
}

bool doubleListEquals(List<double?>? l1, List<double?>? l2) {
  if (l1?.length != l2?.length) {
    return false;
  }
  if (l1 != null && l2 != null) {
    for (var i = 0; i < l1.length; i++) {
      if (!doubleEquals(l1[i], l2[i])) {
        return false;
      }
    }
  }
  return true;
}

bool doubleEquals(double? d1, double? d2) {
  return d1 == d2 ||
      (d1 != null &&
          d2 != null &&
          ((d1.isNaN && d2.isNaN) || (d1 - d2).abs() < 0.001));
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

Matcher get throwsAssertionError {
  var matcher = anything;
  assert(
    () {
      matcher = throwsA(isA<AssertionError>());
      return true;
    }(),
    'only in debug mode',
  );
  return matcher;
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

bool dateTimeListEquals(List<dynamic>? a, List<dynamic>? b) {
  assert(
    (a == null || a.every((e) => e == null || e is DateTime)) &&
        (b == null || b.every((e) => e == null || e is DateTime)),
    'Parameters must be lists of `DateTime` or `DateTime?`',
  );

  return listEquals(
    a?.cast<DateTime?>().map((e) => e?.toUtc()).toList(),
    b?.cast<DateTime?>().map((e) => e?.toUtc()).toList(),
  );
}
