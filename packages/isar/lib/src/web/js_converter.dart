import 'dart:typed_data';

import 'package:meta/dart2js.dart';

const falseBool = 1;
const trueBool = 2;
const nullValue = double.negativeInfinity;
final minDate =
    DateTime.fromMillisecondsSinceEpoch(-8640000000000000, isUtc: true);

class JsConverter {
  @tryInline
  static bool? boolOrNullFromJs(dynamic value) {
    if (value == trueBool) {
      return true;
    } else if (value == falseBool) {
      return false;
    }
  }

  @tryInline
  static bool boolFromJs(dynamic value) {
    if (value == trueBool) {
      return true;
    } else {
      return false;
    }
  }

  @tryInline
  static dynamic boolToJs(bool? value) {
    if (value == null) {
      return nullValue;
    } else if (value) {
      return trueBool;
    } else {
      return falseBool;
    }
  }

  @tryInline
  static T? numOrNullFromJs<T extends num>(dynamic value) {
    if (value == nullValue) {
      return null;
    } else {
      return value;
    }
  }

  @tryInline
  static T numFromJs<T extends num>(dynamic value) => value;

  @tryInline
  static dynamic numToJs(num? value) {
    return value ?? nullValue;
  }

  @tryInline
  static DateTime? dateOrNullFromJs(dynamic value) {
    if (value == nullValue) {
      return null;
    } else {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }

  @tryInline
  static DateTime? dateFromJs(dynamic value) {
    return dateOrNullFromJs(value) ?? minDate;
  }

  @tryInline
  static dynamic dateToJs(DateTime? value) {
    return value?.toUtc().millisecondsSinceEpoch ?? nullValue;
  }

  @tryInline
  static String? stringOrNullFromJs(dynamic value) {
    if (value == nullValue) {
      return null;
    } else {
      return value;
    }
  }

  @tryInline
  static String stringFromJs(dynamic value) {
    return stringOrNullFromJs(value) ?? '';
  }

  @tryInline
  static dynamic stringToJs(String? value) {
    return value ?? nullValue;
  }

  @tryInline
  dynamic bytesToJs(String name, Uint8List? value) {
    return value ?? nullValue;
  }

  @tryInline
  dynamic boolListToJs(String name, List<bool?>? value) {
    return value?.map(boolToJs).toList() ?? nullValue;
  }

  @tryInline
  dynamic numListToJs(String name, List<num?>? value) {
    return value?.map(numToJs).toList() ?? nullValue;
  }

  @tryInline
  dynamic dateTimeListToJs(String name, List<DateTime?>? value) {
    return value?.map(dateToJs).toList() ?? nullValue;
  }

  @tryInline
  dynamic stringListToJs(String name, List<String?>? value) {
    return value?.map(stringToJs).toList() ?? nullValue;
  }
}
