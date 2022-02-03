import 'dart:js';
import 'dart:typed_data';

import 'package:meta/dart2js.dart';
import 'package:meta/meta.dart';

import 'js_reader.dart';

/// @nodoc
@protected
class JsWriter {
  final JsObject obj = JsObject(context['Object']);

  num _boolToNum(bool? value) {
    if (value == null) {
      return nullValue;
    } else if (value) {
      return trueBool;
    } else {
      return falseBool;
    }
  }

  @tryInline
  void writeBool(String name, bool? value) {
    obj[name] = _boolToNum(value);
  }

  @tryInline
  void writeNum(String name, num? value) {
    obj[name] = value ?? nullValue;
  }

  @tryInline
  void writeDateTime(String name, DateTime? value) {
    writeNum(name, value?.toUtc().millisecondsSinceEpoch);
  }

  @tryInline
  void writeBytes(String name, Uint8List? value) {
    obj[name] = value ?? nullValue;
  }

  @tryInline
  void writeBoolList(String name, List<bool?>? value) {
    obj[name] = value?.map(_boolToNum).toList() ?? nullValue;
  }

  @tryInline
  void writeNumList(String name, List<num?>? value) {
    obj[name] = value?.map((e) => e ?? nullValue).toList() ?? nullValue;
  }

  @tryInline
  void writeDateTimeList(String name, List<DateTime?>? value) {
    final numList = value
        ?.map((e) => e?.toUtc().millisecondsSinceEpoch ?? nullValue)
        .toList();
    obj[name] = numList;
  }

  @tryInline
  void writeStringList(String name, List<String?>? value) {
    obj[name] = value?.map((e) => e ?? nullValue).toList() ?? nullValue;
  }
}
