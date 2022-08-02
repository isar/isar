import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:source_gen/source_gen.dart';

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
