import 'dart:js';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:meta/dart2js.dart';

const falseBool = 1;
const trueBool = 2;
const nullValue = double.negativeInfinity;
final minDate =
    DateTime.fromMillisecondsSinceEpoch(-8640000000000000, isUtc: true);

/// @nodoc
@protected
class JsReader {
  final JsObject obj;

  const JsReader(this.obj);

  @tryInline
  static dynamic _valueOrNull(dynamic value) {
    if (value == nullValue) {
      return null;
    } else {
      return value;
    }
  }

  @tryInline
  static bool? _boolOrNull(dynamic value) {
    if (value == trueBool) {
      return true;
    } else if (value == falseBool) {
      return false;
    }
  }

  @tryInline
  static DateTime? _dateOrNull(dynamic value) {
    if (value != nullValue) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }

  @tryInline
  bool readBool(String name) {
    return _boolOrNull(obj[name]) ?? false;
  }

  @tryInline
  bool? readBoolOrNull(String name) {
    return _boolOrNull(obj[name]);
  }

  @tryInline
  num readNum(String name) {
    return obj[name];
  }

  @tryInline
  num? readNumOrNull(String name) {
    return _valueOrNull(obj[name]);
  }

  @tryInline
  DateTime readDateTime(String name) {
    return _dateOrNull(obj[name]) ?? minDate;
  }

  @tryInline
  DateTime? readDateTimeOrNull(String name) {
    return _dateOrNull(obj[name]);
  }

  @tryInline
  String readString(String name) {
    return _valueOrNull(obj[name]) ?? '';
  }

  @tryInline
  String? readStringOrNull(String name) {
    return _valueOrNull(obj[name]);
  }

  @tryInline
  Uint8List readBytes(String name) {
    return _valueOrNull(obj[name]) ?? Uint8List.fromList([]);
  }

  @tryInline
  Uint8List? readBytesOrNull(String name) {
    return _valueOrNull(obj[name]);
  }

  @tryInline
  List<bool>? readBoolList(String name) {
    return (_valueOrNull(obj[name]) as List?)
        ?.map((e) => _boolOrNull(e) ?? false)
        .toList();
  }

  @tryInline
  List<bool?>? readBoolOrNullList(String name) {
    return (_valueOrNull(obj[name]) as List?)?.map(_boolOrNull).toList();
  }

  @tryInline
  List<bool>? readNumList(String name) {
    return _valueOrNull(obj[name]);
  }

  @tryInline
  List<num?>? readNumOrNullList(String name) {
    return (_valueOrNull(obj[name]) as List?)
        ?.map((e) => _valueOrNull(e) as num?)
        .toList();
  }

  @tryInline
  List<DateTime>? readDateTimeList(String name) {
    return (_valueOrNull(obj[name]) as List?)
        ?.map((e) => _dateOrNull(e) ?? minDate)
        .toList();
  }

  @tryInline
  List<DateTime?>? readDateTimeOrNullList(String name) {
    return (_valueOrNull(obj[name]) as List?)?.map(_dateOrNull).toList();
  }

  @tryInline
  List<String>? readStringList(String name) {
    return (_valueOrNull(obj[name]) as List?)
        ?.map((e) => _valueOrNull(e) as String? ?? '')
        .toList();
  }

  @tryInline
  List<String?>? readStringOrNullList(String name) {
    return (_valueOrNull(obj[name]) as List?)
        ?.map((e) => _valueOrNull(e) as String?)
        .toList();
  }
}
