// ignore_for_file: public_member_api_docs

part of isar_generator;

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
    } else if (this is DynamicType) {
      return PropertyType.json;
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
        case PropertyType.json:
          return PropertyType.json;
        // ignore: no_default_cases
        default:
          return null;
      }
    } else if (isDartCoreMap) {
      final keyType = (this as ParameterizedType).typeArguments[0];
      final valueType = (this as ParameterizedType).typeArguments[1];
      if (keyType.isDartCoreString && valueType is DynamicType) {
        return PropertyType.json;
      }
    }

    return null;
  }

  bool get supportsJsonConversion {
    final element = this.element;
    if (element is ClassElement) {
      // check if the class has a toJson() method returning Map<String,dynamic>
      // and a fromJson factory
      final toJson = element.getMethod('toJson');
      final fromJson = element.getNamedConstructor('fromJson');
      if (toJson != null && fromJson != null) {
        final toJsonReturnType = toJson.returnType;
        final fromJsonParameterType = fromJson.parameters.firstOrNull?.type;
        if (toJsonReturnType.isDartCoreMap &&
            toJsonReturnType is ParameterizedType &&
            toJsonReturnType.typeArguments[0].isDartCoreString &&
            toJsonReturnType.typeArguments[1] is DynamicType &&
            fromJsonParameterType != null &&
            fromJsonParameterType.isDartCoreMap &&
            fromJsonParameterType is ParameterizedType &&
            fromJsonParameterType.typeArguments[0].isDartCoreString &&
            fromJsonParameterType.typeArguments[1] is DynamicType) {
          return true;
        }
      }
    }
    return false;
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
  json,
  boolList,
  byteList,
  intList,
  floatList,
  longList,
  doubleList,
  dateTimeList,
  stringList,
  objectList,
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

  bool get isList => scalarType != this;

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
