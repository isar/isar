import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:isar/isar.dart';
import 'package:source_gen/source_gen.dart';

enum IsarType {
  bool,
  int,
  float,
  long,
  double,
  dateTime,
  string,
  bytes,
  boolList,
  intList,
  floatList,
  longList,
  doubleList,
  dateTimeList,
  stringList,
}

extension IsarTypeX on IsarType {
  bool get isDynamic {
    return index >= IsarType.string.index;
  }

  bool get isList {
    return index > IsarType.string.index;
  }

  bool get containsFloat {
    return this == IsarType.float ||
        this == IsarType.double ||
        this == IsarType.floatList ||
        this == IsarType.doubleList;
  }

  bool get containsString =>
      index == IsarType.string.index || index == IsarType.stringList.index;

  int get staticSize {
    if (this == IsarType.bool) {
      return 1;
    } else if (this == IsarType.int || this == IsarType.float) {
      return 4;
    } else {
      return 8;
    }
  }

  int get elementSize {
    switch (this) {
      case IsarType.bytes:
      case IsarType.boolList:
        return 1;
      case IsarType.intList:
      case IsarType.floatList:
        return 4;
      case IsarType.longList:
      case IsarType.doubleList:
      case IsarType.dateTimeList:
        return 8;
      default:
        return 0;
    }
  }

  IsarType get scalarType {
    switch (this) {
      case IsarType.boolList:
        return IsarType.bool;
      case IsarType.intList:
        return IsarType.int;
      case IsarType.floatList:
        return IsarType.float;
      case IsarType.longList:
        return IsarType.long;
      case IsarType.doubleList:
        return IsarType.double;
      case IsarType.dateTimeList:
        return IsarType.dateTime;
      case IsarType.stringList:
        return IsarType.string;
      default:
        return this;
    }
  }

  String get name {
    switch (this) {
      case IsarType.bool:
        return "Bool";
      case IsarType.int:
        return "Int";
      case IsarType.float:
        return "Float";
      case IsarType.long:
      case IsarType.dateTime:
        return "Long";
      case IsarType.double:
        return "Double";
      case IsarType.string:
        return "String";
      case IsarType.bytes:
        return "ByteList";
      case IsarType.boolList:
        return "BoolList";
      case IsarType.intList:
        return "IntList";
      case IsarType.floatList:
        return "FloatList";
      case IsarType.longList:
      case IsarType.dateTimeList:
        return "LongList";
      case IsarType.doubleList:
        return "DoubleList";
      case IsarType.stringList:
        return "StringList";
    }
  }

  String dartType(bool nullable, bool elementNullable) {
    final nQ = nullable ? '?' : '';
    final nEQ = elementNullable ? '?' : '';
    switch (this) {
      case IsarType.bool:
        return 'bool$nQ';
      case IsarType.int:
      case IsarType.long:
        return 'int$nQ';
      case IsarType.double:
      case IsarType.float:
        return 'double$nQ';
      case IsarType.dateTime:
        return 'DateTime$nQ';
      case IsarType.string:
        return 'String$nQ';
      case IsarType.bytes:
        return 'Uint8List$nQ';
      case IsarType.boolList:
        return 'List<bool$nEQ>$nQ';
      case IsarType.intList:
      case IsarType.longList:
        return 'List<int$nEQ>$nQ';
      case IsarType.floatList:
      case IsarType.doubleList:
        return 'List<double$nEQ>$nQ';
      case IsarType.dateTimeList:
        return 'List<DateTime$nEQ>$nQ';
      case IsarType.stringList:
        return 'List<String$nEQ>$nQ';
    }
  }
}

final _dateTimeChecker = const TypeChecker.fromRuntime(DateTime);
bool _isDateTime(Element element) => _dateTimeChecker.isExactly(element);

final _uint8ListChecker = const TypeChecker.fromRuntime(Uint8List);
bool _isUint8List(Element element) => _uint8ListChecker.isExactly(element);

final _size32Checker = const TypeChecker.fromRuntime(Size32);
IsarType? getIsarType(DartType type, Element element) {
  final size32 = _size32Checker.hasAnnotationOfExact(element.nonSynthetic);
  if (type.isDartCoreBool) {
    return IsarType.bool;
  } else if (type.isDartCoreInt) {
    if (size32) {
      return IsarType.int;
    } else {
      return IsarType.long;
    }
  } else if (type.isDartCoreDouble) {
    if (size32) {
      return IsarType.float;
    } else {
      return IsarType.double;
    }
  } else if (type.isDartCoreString) {
    return IsarType.string;
  } else if (type.isDartCoreList) {
    final parameterizedType = type as ParameterizedType;
    final typeArguments = parameterizedType.typeArguments;
    if (typeArguments.isNotEmpty) {
      final listType = typeArguments[0];
      if (listType.isDartCoreBool) {
        return IsarType.boolList;
      } else if (listType.isDartCoreInt) {
        if (size32) {
          return IsarType.intList;
        } else {
          return IsarType.longList;
        }
      } else if (listType.isDartCoreDouble) {
        if (size32) {
          return IsarType.floatList;
        } else {
          return IsarType.doubleList;
        }
      } else if (listType.isDartCoreString) {
        return IsarType.stringList;
      } else if (_isDateTime(listType.element!)) {
        return IsarType.dateTimeList;
      }
    }
  } else if (_isDateTime(type.element!)) {
    return IsarType.dateTime;
  } else if (_isUint8List(type.element!)) {
    return IsarType.bytes;
  }
  return null;
}
