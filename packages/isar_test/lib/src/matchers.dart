import 'package:isar/isar.dart';
import 'package:test/test.dart';

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

Matcher throwsWriteTxnError() {
  return throwsA(isA<WriteTxnRequiredError>());
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
    final first = a[index];
    final second = b[index];
    if (first is double && second is double) {
      if (!doubleEquals(first, second)) {
        return false;
      }
    } else if (first is List && second is List) {
      if (!listEquals(first, second)) {
        return false;
      }
    } else if (first is Map && second is Map) {
      if (!listEquals(first.keys.toList(), second.keys.toList())) {
        return false;
      }
      if (!listEquals(first.values.toList(), second.values.toList())) {
        return false;
      }
    } else if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
