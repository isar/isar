import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker _dateTimeChecker = TypeChecker.fromRuntime(DateTime);
bool _isDateTime(Element element) => _dateTimeChecker.isExactly(element);

const TypeChecker _isarEnumChecker = TypeChecker.fromRuntime(IsarEnum);
bool _isIsarEnum(Element element) => _isarEnumChecker.isAssignableFrom(element);

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
    } else if (isIsarEnum) {
      final enumElement = element! as ClassElement;
      final isarEnum =
          enumElement.allSupertypes.firstWhere((e) => e.isIsarEnum);
      if (isarEnum.typeArguments.firstOrNull?.nullabilitySuffix ==
          NullabilitySuffix.none) {
        final type = isarEnum.typeArguments[0];
        final isarType = type.isarType;
        if (!type.isIsarEnum &&
            isarType != IsarType.object &&
            isarType != IsarType.objectList) {
          return isarType;
        }
      }
    }

    return null;
  }

  bool get isIsarId {
    return alias?.element.name == 'Id';
  }

  bool get isIsarEnum {
    return _isIsarEnum(element!);
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
          throw UnimplementedError();
      }
    }

    return null;
  }
}
