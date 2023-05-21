// ignore_for_file: public_member_api_docs

import 'package:analyzer/dart/element/type.dart';
import 'package:isar/src/generator/helper.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker _dateTimeChecker = TypeChecker.fromRuntime(DateTime);

extension DartTypeX on DartType {
  bool get isDartCoreDateTime =>
      element != null && _dateTimeChecker.isExactly(element!);

  PropertyType? get _primitivePropertyType {
    if (isDartCoreBool) {
      return PropertyType.bool;
    } else if (isDartCoreInt) {
      if (alias?.element.name == 'byte') {
        return PropertyType.byte;
      } else if (alias?.element.name == 'short') {
        return PropertyType.int;
      } else {
        return PropertyType.long;
      }
    } else if (isDartCoreDouble) {
      if (alias?.element.name == 'float') {
        return PropertyType.float;
      } else {
        return PropertyType.double;
      }
    } else if (isDartCoreString) {
      return PropertyType.string;
    } else if (isDartCoreDateTime) {
      return PropertyType.dateTime;
    } else if (element!.embeddedAnnotation != null) {
      return PropertyType.object;
    }

    return null;
  }

  DartType get scalarType {
    if (isDartCoreList) {
      final parameterizedType = this as ParameterizedType;
      final typeArguments = parameterizedType.typeArguments;
      if (typeArguments.isNotEmpty) {
        return typeArguments[0];
      }
    }
    return this;
  }

  PropertyType? get propertyType {
    final primitiveType = _primitivePropertyType;
    if (primitiveType != null) {
      return primitiveType;
    }

    if (isDartCoreList) {
      switch (scalarType._primitivePropertyType) {
        case PropertyType.bool:
          return PropertyType.boolList;
        case PropertyType.byte:
          return PropertyType.byteList;
        case PropertyType.int:
          return PropertyType.intList;
        case PropertyType.float:
          return PropertyType.floatList;
        case PropertyType.long:
          return PropertyType.longList;
        case PropertyType.double:
          return PropertyType.doubleList;
        case PropertyType.dateTime:
          return PropertyType.dateTimeList;
        case PropertyType.string:
          return PropertyType.stringList;
        case PropertyType.object:
          return PropertyType.objectList;
        // ignore: no_default_cases
        default:
          return null;
      }
    }

    return null;
  }
}

enum PropertyType {
  bool,
  byte,
  int,
  float,
  long,
  double,
  dateTime,
  string,
  object,
  boolList,
  byteList,
  intList,
  floatList,
  longList,
  doubleList,
  dateTimeList,
  stringList,
  objectList
}

extension PropertyTypeX on PropertyType {
  bool get isBool => this == PropertyType.bool || this == PropertyType.boolList;

  bool get isFloat =>
      this == PropertyType.float ||
      this == PropertyType.floatList ||
      this == PropertyType.double ||
      this == PropertyType.doubleList;

  bool get isDate =>
      this == PropertyType.dateTime || this == PropertyType.dateTimeList;

  bool get isString =>
      this == PropertyType.string || this == PropertyType.stringList;

  bool get isObject =>
      this == PropertyType.object || this == PropertyType.objectList;

  bool get isList => index >= PropertyType.boolList.index;

  /// @nodoc
  PropertyType get scalarType {
    switch (this) {
      case PropertyType.boolList:
        return PropertyType.bool;
      case PropertyType.byteList:
        return PropertyType.byte;
      case PropertyType.intList:
        return PropertyType.int;
      case PropertyType.floatList:
        return PropertyType.float;
      case PropertyType.longList:
        return PropertyType.long;
      case PropertyType.doubleList:
        return PropertyType.double;
      case PropertyType.dateTimeList:
        return PropertyType.dateTime;
      case PropertyType.stringList:
        return PropertyType.string;
      case PropertyType.objectList:
        return PropertyType.object;
      // ignore: no_default_cases
      default:
        return this;
    }
  }

  /// @nodoc
  PropertyType get listType {
    switch (this) {
      case PropertyType.bool:
        return PropertyType.boolList;
      case PropertyType.byte:
        return PropertyType.byteList;
      case PropertyType.int:
        return PropertyType.intList;
      case PropertyType.float:
        return PropertyType.floatList;
      case PropertyType.long:
        return PropertyType.longList;
      case PropertyType.double:
        return PropertyType.doubleList;
      case PropertyType.dateTime:
        return PropertyType.dateTimeList;
      case PropertyType.string:
        return PropertyType.stringList;
      case PropertyType.object:
        return PropertyType.objectList;
      // ignore: no_default_cases
      default:
        return this;
    }
  }
}
