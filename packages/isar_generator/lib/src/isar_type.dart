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
  objectList,
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
    if (this == IsarType.bool || this == IsarType.byte) {
      return 1;
    } else if (this == IsarType.int || this == IsarType.float) {
      return 4;
    } else {
      return 8;
    }
  }

  int get elementSize {
    switch (this) {
      case IsarType.boolList:
      case IsarType.byteList:
        return 1;
      case IsarType.intList:
      case IsarType.floatList:
        return 4;
      case IsarType.longList:
      case IsarType.doubleList:
      case IsarType.dateTimeList:
        return 8;
      // ignore: no_default_cases
      default:
        return 0;
    }
  }

  IsarType get scalarType {
    switch (this) {
      case IsarType.boolList:
        return IsarType.bool;
      case IsarType.byteList:
        return IsarType.byte;
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
      case IsarType.objectList:
        return IsarType.object;
      // ignore: no_default_cases
      default:
        return this;
    }
  }

  IsarType get listType {
    switch (this) {
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
        return this;
    }
  }

  String get name {
    switch (this) {
      case IsarType.id:
        throw UnimplementedError();
      case IsarType.bool:
        return 'Bool';
      case IsarType.byte:
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

  String dartType(bool nullable, bool elementNullable) {
    final nQ = nullable ? '?' : '';
    final nEQ = elementNullable ? '?' : '';
    switch (this) {
      case IsarType.id:
        return 'Id$nQ';
      case IsarType.bool:
        return 'bool$nQ';
      case IsarType.byte:
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
      case IsarType.boolList:
        return 'List<bool$nEQ>$nQ';
      case IsarType.byteList:
        return 'Uint8List$nQ';
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
    throw '';
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
      final listType = typeArguments[0];
      final primitiveType = _getPrimitiveIsarType(listType);
      if (primitiveType == IsarType.id) {
        err('Id lists are not supported.', element);
      } else {
        return primitiveType?.listType;
      }
    }
  }

  return null;
}
