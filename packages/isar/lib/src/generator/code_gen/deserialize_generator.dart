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
    code += 'final ${p.dartType} ${p.dartName};{';
    code += _deserialize(
      p.type,
      p.type.scalarType,
      p.defaultValue,
      p.elementDefaultValue,
      p.scalarDartType,
      object.properties.indexOf(p).toString(),
      (value) {
        return '${p.dartName} = $value;';
      },
    );
    code += '}';
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
    code += '{';
    code += _deserialize(
      p.type,
      p.type.scalarType,
      p.defaultValue,
      p.elementDefaultValue,
      p.scalarDartType,
      object.properties.indexOf(p).toString(),
      (value) {
        return 'object.${p.dartName} = $value;';
      },
    );
    code += '}';
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
  for (var i = 0; i < object.properties.length; i++) {
    final property = object.properties[i];
    final deser = _deserialize(
      property.type,
      property.type.scalarType,
      property.defaultValue,
      property.elementDefaultValue,
      property.scalarDartType,
      i.toString(),
      (value) {
        return 'return ($value) as P;';
      },
    );
    code += 'case $i: $deser';
  }

  return '''
      $code
      default:
        throw IsarError('Unknown property: \$property');
      }
    }
    ''';
}

String _deserialize(
  PropertyType type,
  PropertyType? elementType,
  String defaultValue,
  String? elementDefaultValue,
  String? elementDartType,
  String index,
  String Function(String? value) result,
) {
  switch (type) {
    case PropertyType.bool:
      return '''
      final value = IsarCore.isar_read_bool(reader, $index);
      if (value == $nullBool) {
        ${result(defaultValue)}
      } else {
        ${result('value == $falseBool')}
      }''';
    case PropertyType.byte:
      return '''
      final value = IsarCore.isar_read_byte(reader, $index);
      if (value == $nullByte) {
        ${result(defaultValue)}
      } else {
        ${result('value')}
      }''';
    case PropertyType.int:
      return '''
      final value = IsarCore.isar_read_int(reader, $index);
      if (value == $nullInt) {
        ${result(defaultValue)}
      } else {
        ${result('value')}
      }''';
    case PropertyType.float:
      return '''
      final value = IsarCore.isar_read_float(reader, $index);
      if (value.isNaN) {
        ${result(defaultValue)}
      } else {
        ${result('value')}
      }''';
    case PropertyType.long:
      return '''
      final value = IsarCore.isar_read_long(reader, $index);
      if (value == $nullLong) {
        ${result(defaultValue)}
      } else {
        ${result('value')}
      }''';
    case PropertyType.double:
      return '''
      final value = IsarCore.isar_read_double(reader, $index);
      if (value.isNaN) {
        ${result(defaultValue)}
      } else {
        ${result('value')}
      }''';
    case PropertyType.string:
      return '''
      final length = IsarCore.isar_read_string(reader, $index, IsarCore.stringPtrPtr);
      final value = IsarCore.fromNativeString(IsarCore.stringPtr, length);
      IsarCore.isar_free_string(IsarCore.stringPtr, length);
      if (value == null) {
        ${result(defaultValue)}
      } else {
        ${result('value')}
      }''';
    default:
      return '''
      final length = IsarCore.isar_read_list(reader, $index, IsarCore.readerPtrPtr);
      final listReader = IsarCore.readerPtr;
      if (listReader.isNull) {
        ${result(defaultValue)}
      } else {
        final list = <$elementDartType>[];
        for (var i = 0; i < length; i++) {
          ${_deserialize(elementType!, null, elementDefaultValue!, null, null, 'i', (value) => 'list.add($value);')}
        }
        ${result('list')}
      }''';
  }
}
