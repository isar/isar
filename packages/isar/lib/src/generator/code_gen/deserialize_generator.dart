// ignore_for_file: use_string_buffers, no_default_cases

import 'dart:typed_data';

import 'package:isar/src/generator/consts.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateDeserialize(ObjectInfo object) {
  var code = '''
  @isarProtected
  ${object.dartName} deserialize${object.dartName}(IsarReader reader) {''';

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
    code += 'final ${p.dartType} _${p.dartName};';
    code += _deserializeProperty(object, p, (value) {
      return '_${p.dartName} = $value;';
    });
  }

  code += 'final object = ${object.dartName}(';

  for (final p in positional) {
    code += '_${p.dartName},';
  }

  for (final p in named) {
    code += '${p.dartName}: _${p.dartName},';
  }

  code += ');';

  final assign = propertiesByMode[DeserializeMode.assign]!;
  for (final p in assign) {
    code += _deserializeProperty(object, p, (value) {
      return 'object.${p.dartName} = $value;';
    });
  }

  return '''
    $code
    return object;
  }''';
}

String generateDeserializeProp(ObjectInfo object) {
  var code = '''
    @isarProtected
    dynamic deserialize${object.dartName}Prop(IsarReader reader, int property) {
      switch (property) {''';
  for (final p in object.properties) {
    final deser = _deserializeProperty(object, p, (value) {
      return 'return $value;';
    });
    code += 'case ${p.index}: $deser';
  }

  return '''
      $code
      default:
        throw ArgumentError('Unknown property: \$property');
      }
    }
    ''';
}

String _deserializeProperty(
  ObjectInfo object,
  PropertyInfo p,
  String Function(String value) result,
) {
  return _deserialize(
    isId: p.isId,
    typeClassName: p.typeClassName,
    type: p.type,
    elementDartType: p.scalarDartType,
    index: p.index.toString(),
    defaultValue: p.defaultValue,
    elementDefaultValue: p.elementDefaultValue,
    transform: (value) {
      if (p.isEnum && !p.type.isList) {
        return result(
          '${p.enumMapName(object)}[$value] ?? ${p.defaultValue}',
        );
      } else {
        return result(value);
      }
    },
    transformElement: (value) {
      if (p.isEnum) {
        return '${p.enumMapName(object)}[$value] ?? ${p.elementDefaultValue}';
      } else {
        return value;
      }
    },
  );
}

String _deserialize({
  required bool isId,
  required String typeClassName,
  required PropertyType type,
  String? elementDartType,
  required String defaultValue,
  String? elementDefaultValue,
  required String index,
  required String Function(String value) transform,
  String Function(String value)? transformElement,
}) {
  switch (type) {
    case PropertyType.bool:
      if (defaultValue == 'false') {
        return transform('IsarCore.isarReadBool(reader, $index)');
      } else {
        return '''
        {
          if (IsarCore.isarReadNull(reader, $index)) {
            ${transform(defaultValue)}
          } else {
            ${transform('IsarCore.isarReadBool(reader, $index)')}
          }
        }''';
      }
    case PropertyType.byte:
      if (defaultValue == '0') {
        return transform('IsarCore.isarReadByte(reader, $index)');
      } else {
        return '''
        {
          final value = IsarCore.isarReadByte(reader, $index);
          if (value == $nullByte) {
            ${transform(defaultValue)}
          } else {
            ${transform('value')}
          }
        }''';
      }
    case PropertyType.int:
      if (defaultValue == '$nullInt') {
        return transform('IsarCore.isarReadInt(reader, $index)');
      } else {
        return '''
        {
          final value = IsarCore.isarReadInt(reader, $index);
          if (value == $nullInt) {
            ${transform(defaultValue)}
          } else {
            ${transform('value')}
          }
        }''';
      }
    case PropertyType.float:
      if (defaultValue == 'double.nan') {
        return transform('IsarCore.isarReadFloat(reader, $index)');
      } else {
        return '''
        {
          final value = IsarCore.isarReadFloat(reader, $index);
          if (value.isNaN) {
            ${transform(defaultValue)}
          } else {
            ${transform('value')}
          }
        }''';
      }
    case PropertyType.long:
      if (isId) {
        return transform('IsarCore.isarReadId(reader)');
      } else if (defaultValue == '$nullLong') {
        return transform('IsarCore.isarReadLong(reader, $index)');
      } else {
        return '''
        {
          final value = IsarCore.isarReadLong(reader, $index);
          if (value == $nullLong) {
            ${transform(defaultValue)}
          } else {
            ${transform('value')}
          }
        }''';
      }
    case PropertyType.dateTime:
      return '''
        {
          final value = IsarCore.isarReadLong(reader, $index);
          if (value == $nullLong) {
            ${transform(defaultValue)}
          } else {
            ${transform('DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal()')}
          }
        }''';

    case PropertyType.double:
      if (defaultValue == 'double.nan') {
        return transform('IsarCore.isarReadDouble(reader, $index)');
      } else {
        return '''
        {
          final value = IsarCore.isarReadDouble(reader, $index);
          if (value.isNaN) {
            ${transform(defaultValue)}
          } else {
            ${transform('value')}
          }
        }''';
      }
    case PropertyType.string:
      if (defaultValue == 'null') {
        return transform('IsarCore.isarReadString(reader, $index)');
      } else {
        return transform(
            'IsarCore.isarReadString(reader, $index) ?? $defaultValue');
      }

    case PropertyType.object:
      return '''
      {
        final objectReader = IsarCore.isarReadObject(reader, $index);
        if (objectReader.isNull) {
          ${transform(defaultValue)}
        } else {
          ${transform('deserialize$typeClassName(objectReader)')}
        }
      }''';
    case PropertyType.boolList:
    case PropertyType.byteList:
    case PropertyType.intList:
    case PropertyType.floatList:
    case PropertyType.longList:
    case PropertyType.dateTimeList:
    case PropertyType.doubleList:
    case PropertyType.stringList:
    case PropertyType.objectList:
      final deser = _deserialize(
        isId: false,
        typeClassName: typeClassName,
        type: type.scalarType,
        defaultValue: elementDefaultValue!,
        index: 'i',
        transform: (value) => 'list[i] = ${transformElement!(value)};',
      );
      return '''
      {
        final length = IsarCore.isarReadList(reader, $index, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            ${transform(defaultValue)}
          } else {
            final list = List<$elementDartType>.filled(length, $elementDefaultValue, growable: true);
            for (var i = 0; i < length; i++) {
              $deser
            }
            ${transform('list')}
          }
        }
      }''';
    case PropertyType.json:
      if (typeClassName == 'dynamic') {
        return transform(
          "isarJsonDecode(IsarCore.isarReadString(reader, $index) ?? 'null') ?? $defaultValue",
        );
      } else {
        return '''
        {
          final json = isarJsonDecode(IsarCore.isarReadString(reader, $index) ?? 'null');
          if (json is ${typeClassName == 'List' ? 'List' : 'Map<String, dynamic>'}) {
            ${typeClassName == 'List' || typeClassName == 'Map' ? transform('json') : transform('$typeClassName.fromJson(json)')}
          } else {
            ${transform(defaultValue)}
          }
        }''';
      }
  }
}
