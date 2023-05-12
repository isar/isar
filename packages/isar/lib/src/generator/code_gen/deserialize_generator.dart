// ignore_for_file: use_string_buffers, no_default_cases

import 'package:isar/src/generator/consts.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateDeserialize(ObjectInfo object) {
  var code =
      '${object.dartName} ${object.deserializeName}(IsarReader reader) {';

  final propertiesByMode = {
    DeserializeMode.none: <PropertyInfo>[],
    DeserializeMode.assign: <PropertyInfo>[],
    DeserializeMode.positionalParam: <PropertyInfo>[],
    DeserializeMode.namedParam: <PropertyInfo>[],
  };
  for (final property in object.properties) {
    propertiesByMode[property.mode]!.add(property);
  }

  final positional = propertiesByMode[DeserializeMode.positionalParam]!;
  positional.sort(
      (p1, p2) => p1.constructorPosition!.compareTo(p2.constructorPosition!));
  final named = propertiesByMode[DeserializeMode.namedParam]!;

  for (final p in [...positional, ...named]) {
    code += 'final ${p.dartType} ${p.dartName};';
    code += _deserialize(
      isId: p.isId,
      type: p.type,
      elementType: p.type.scalarType,
      elementDartType: p.scalarDartType,
      nullable: p.nullable,
      elementNullable: p.elementNullable,
      defaultValue: p.defaultValue,
      elementDefaultValue: p.elementDefaultValue,
      index: p.index.toString(),
      result: (value) {
        return '${p.dartName} = $value;';
      },
    );
  }

  code += 'final object = ${object.dartName}(';

  for (final p in positional) {
    code += '${p.dartName},';
  }

  for (final p in named) {
    code += '${p.dartName}: ${p.dartName},';
  }

  code += ');';

  final assign = propertiesByMode[DeserializeMode.assign]!;
  for (final p in assign) {
    code += _deserialize(
      isId: p.isId,
      type: p.type,
      elementType: p.type.scalarType,
      elementDartType: p.scalarDartType,
      nullable: p.nullable,
      elementNullable: p.elementNullable,
      defaultValue: p.defaultValue,
      elementDefaultValue: p.elementDefaultValue,
      index: p.index.toString(),
      result: (value) {
        return 'object.${p.dartName} = $value;';
      },
    );
  }

  return '''
    $code
    return object;
  }''';
}

String generateDeserializeProp(ObjectInfo object) {
  var code = '''
    P ${object.deserializePropName}<P>(IsarReader reader, int property) {
      switch (property) {''';
  for (final p in object.properties) {
    final deser = _deserialize(
      isId: p.isId,
      type: p.type,
      elementType: p.type.scalarType,
      elementDartType: p.scalarDartType,
      nullable: p.nullable,
      elementNullable: p.elementNullable,
      defaultValue: p.defaultValue,
      elementDefaultValue: p.elementDefaultValue,
      index: p.index.toString(),
      result: (value) {
        return 'return ($value) as P;';
      },
    );
    code += 'case ${p.index}: $deser';
  }

  return '''
      $code
      default:
        throw IsarError('Unknown property: \$property');
      }
    }
    ''';
}

String _deserialize({
  required bool isId,
  required PropertyType type,
  PropertyType? elementType,
  String? elementDartType,
  required bool nullable,
  bool? elementNullable,
  required String defaultValue,
  String? elementDefaultValue,
  required String index,
  required String Function(String value) result,
}) {
  switch (type) {
    case PropertyType.bool:
      if (nullable) {
        return '''
        {
          final value = IsarCore.isarReadBool(reader, $index);
          if (value == $nullBool) {
            ${result(defaultValue)}
          } else {
            ${result('value == $falseBool')}
          }
        }''';
      } else {
        return result('IsarCore.isarReadBool(reader, $index) == $trueBool');
      }
    case PropertyType.byte:
      if (nullable) {
        return '''
        {
          final value = IsarCore.isarReadByte(reader, $index);
          if (value == $nullByte) {
            ${result(defaultValue)}
          } else {
            ${result('value')}
          }
        }''';
      } else {
        return result('IsarCore.isarReadByte(reader, $index)');
      }
    case PropertyType.int:
      if (nullable) {
        return '''
        {
          final value = IsarCore.isarReadInt(reader, $index);
          if (value == $nullInt) {
            ${result(defaultValue)}
          } else {
            ${result('value')}
          }
        }''';
      } else {
        return result('IsarCore.isarReadInt(reader, $index)');
      }
    case PropertyType.float:
      if (nullable) {
        return '''
        {
          final value = IsarCore.isarReadFloat(reader, $index);
          if (value.isNaN) {
            ${result(defaultValue)}
          } else {
            ${result('value')}
          }
        }''';
      } else {
        return result('IsarCore.isarReadFloat(reader, $index)');
      }
    case PropertyType.long:
      if (isId) {
        return result('IsarCore.isarReadId(reader)');
      } else if (nullable) {
        return '''
        {
          final value = IsarCore.isarReadLong(reader, $index);
          if (value == $nullLong) {
            ${result(defaultValue)}
          } else {
            ${result('value')}
          }
        }''';
      } else {
        return result('IsarCore.isarReadLong(reader, $index)');
      }
    case PropertyType.double:
      if (nullable) {
        return '''
        {
          final value = IsarCore.isarReadDouble(reader, $index);
          if (value.isNaN) {
            ${result(defaultValue)}
          } else {
            ${result('value')}
          }
        }''';
      } else {
        return result('IsarCore.isarReadDouble(reader, $index)');
      }
    case PropertyType.string:
      return '''
      {
        final length = IsarCore.isarReadString(reader, $index, IsarCore.stringPtrPtr);
        final value = IsarCore.fromNativeString(IsarCore.stringPtr, length);
        IsarCore.isarFreeString(IsarCore.stringPtr, length);
        if (value == null) {
          ${result(defaultValue)}
        } else {
          ${result('value')}
        }
      }''';
    default:
      final deser = _deserialize(
        isId: false,
        type: elementType!,
        nullable: elementNullable!,
        defaultValue: elementDefaultValue!,
        index: 'i',
        result: (value) => 'list.add($value);',
      );
      return '''
      {
        final length = IsarCore.isarReadList(reader, $index, IsarCore.readerPtrPtr);
        final listReader = IsarCore.readerPtr;
        if (listReader.isNull) {
          ${result(defaultValue)}
        } else {
          final list = <$elementDartType>[];
          for (var i = 0; i < length; i++) {
            $deser
          }
          ${result('list')}
        }
      }''';
  }
}
