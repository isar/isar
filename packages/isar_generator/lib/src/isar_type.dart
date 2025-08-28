import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker _dateTimeChecker = TypeChecker.fromRuntime(DateTime);
bool _isDateTime(Element element) => _dateTimeChecker.isExactly(element);

extension DartTypeX on DartType {
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
    } else if (_isDateTime(element!)) {
      return IsarType.dateTime;
    } else if (element!.embeddedAnnotation != null) {
      return IsarType.object;
    }

    return null;
  }

  bool get isIsarId {
    return alias?.element.name == 'Id';
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

  IsarType? get isarType {
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
        // ignore: no_default_cases
        default:
          return null;
      }
    }

    return null;
  }
}

extension IsarTypeX on IsarType {
  bool get containsBool => this == IsarType.bool || this == IsarType.boolList;

  bool get containsFloat =>
      this == IsarType.float ||
      this == IsarType.floatList ||
      this == IsarType.double ||
      this == IsarType.doubleList;

  bool get containsDate =>
      this == IsarType.dateTime || this == IsarType.dateTimeList;

  bool get containsString =>
      this == IsarType.string || this == IsarType.stringList;

  bool get containsObject =>
      this == IsarType.object || this == IsarType.objectList;
}
