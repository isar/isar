part of isar_generator;

const TypeChecker _dateTimeChecker = TypeChecker.fromRuntime(DateTime);

extension on DartType {
  bool get isDartCoreDateTime =>
      element != null && _dateTimeChecker.isExactly(element!);

  IsarType? get _primitiveIsarType {
    if (isDartCoreBool) {
      return IsarType.bool;
    } else if (isDartCoreInt) {
      if (alias?.element.name == 'byte') {
        return IsarType.byte;
      } else if (alias?.element.name == 'short') {
        return IsarType.int;
      } else {
        return IsarType.long;
      }
    } else if (isDartCoreDouble) {
      if (alias?.element.name == 'float') {
        return IsarType.float;
      } else {
        return IsarType.double;
      }
    } else if (isDartCoreString) {
      return IsarType.string;
    } else if (isDartCoreDateTime) {
      return IsarType.dateTime;
    } else if (element!.embeddedAnnotation != null) {
      return IsarType.object;
    } else if (this is DynamicType) {
      return IsarType.json;
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

  IsarType? get propertyType {
    final primitiveType = _primitiveIsarType;
    if (primitiveType != null) {
      return primitiveType;
    }

    if (isDartCoreList) {
      switch (scalarType._primitiveIsarType) {
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
        case IsarType.string:
          return IsarType.stringList;
        case IsarType.object:
          return IsarType.objectList;
        case IsarType.json:
          return IsarType.json;
        // ignore: no_default_cases
        default:
          return null;
      }
    } else if (isDartCoreMap) {
      final keyType = (this as ParameterizedType).typeArguments[0];
      final valueType = (this as ParameterizedType).typeArguments[1];
      if (keyType.isDartCoreString && valueType is DynamicType) {
        return IsarType.json;
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
