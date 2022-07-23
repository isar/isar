import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:source_gen/source_gen.dart';

enum IsarType {
  id,
  bool,
  byte,
  int,
  float,
  long,
  double,
  dateTime,
  enumeration,
  string,
  object,
  boolList,
  byteList,
  intList,
  floatList,
  longList,
  doubleList,
  dateTimeList,
  enumerationList,
  stringList,
  objectList,
}

extension IsarTypeX on IsarType {
  bool get isDynamic {
    return index >= IsarType.string.index;
  }

  bool get isList {
    return index > IsarType.string.index;
  }

  int get staticSize {
    if (this == IsarType.bool || this == IsarType.byte) {
      return 1;
    } else if (this == IsarType.int || this == IsarType.float) {
      return 4;
    } else {
      return 8;
    }
  }

  String get name {
    switch (this) {
      case IsarType.id:
        throw UnimplementedError();
      case IsarType.bool:
        return 'Bool';
      case IsarType.byte:
      case IsarType.enumeration:
        return 'Byte';
      case IsarType.int:
        return 'Int';
      case IsarType.float:
        return 'Float';
      case IsarType.long:
      case IsarType.dateTime:
        return 'Long';
      case IsarType.double:
        return 'Double';
      case IsarType.string:
        return 'String';
      case IsarType.object:
        return 'Object';
      case IsarType.boolList:
        return 'BoolList';
      case IsarType.byteList:
      case IsarType.enumerationList:
        return 'ByteList';
      case IsarType.intList:
        return 'IntList';
      case IsarType.floatList:
        return 'FloatList';
      case IsarType.longList:
      case IsarType.dateTimeList:
        return 'LongList';
      case IsarType.doubleList:
        return 'DoubleList';
      case IsarType.stringList:
        return 'StringList';
      case IsarType.objectList:
        return 'ObjectList';
    }
  }
}

const TypeChecker _dateTimeChecker = TypeChecker.fromRuntime(DateTime);
bool _isDateTime(Element element) => _dateTimeChecker.isExactly(element);

const TypeChecker _uint8ListChecker = TypeChecker.fromRuntime(Uint8List);
bool _isUint8List(Element element) => _uint8ListChecker.isExactly(element);

IsarType? _getPrimitiveIsarType(DartType type) {
  if (type.isDartCoreBool) {
    return IsarType.bool;
  } else if (type.isDartCoreInt) {
    if (type.alias?.element.name == 'Id') {
      return IsarType.id;
    } else if (type.alias?.element.name == 'byte') {
      return IsarType.byte;
    } else if (type.alias?.element.name == 'short') {
      return IsarType.int;
    } else {
      return IsarType.long;
    }
  } else if (type.isDartCoreDouble) {
    if (type.alias?.element.name == 'float') {
      return IsarType.float;
    } else {
      return IsarType.double;
    }
  } else if (type.isDartCoreString) {
    return IsarType.string;
  } else if (_isDateTime(type.element!)) {
    return IsarType.dateTime;
  } else if (type.isDartCoreEnum) {
    return IsarType.enumeration;
  }

  return null;
}

IsarType? getIsarType(DartType type, Element element) {
  final primitiveType = _getPrimitiveIsarType(type);
  if (primitiveType != null) {
    return primitiveType;
  }

  if (_isUint8List(type.element!)) {
    return IsarType.byteList;
  } else if (type.isDartCoreList) {
    final parameterizedType = type as ParameterizedType;
    final typeArguments = parameterizedType.typeArguments;
    if (typeArguments.isNotEmpty) {
      switch (_getPrimitiveIsarType(typeArguments[0])) {
        case IsarType.id:
          err('Id lists are not supported.', element);
        case IsarType.bool:
          return IsarType.boolList;
        case IsarType.byte:
          return IsarType.byteList;
        case IsarType.int:
          return IsarType.intList;
        case IsarType.float:
          return IsarType.floatList;
        case IsarType.long:
          return IsarType.longList;
        case IsarType.double:
          return IsarType.doubleList;
        case IsarType.dateTime:
          return IsarType.dateTimeList;
        case IsarType.enumeration:
          return IsarType.enumerationList;
        case IsarType.string:
          return IsarType.stringList;
        case IsarType.object:
          return IsarType.objectList;
        // ignore: no_default_cases
        default:
          throw UnimplementedError();
      }
    }
  }

  return null;
}
