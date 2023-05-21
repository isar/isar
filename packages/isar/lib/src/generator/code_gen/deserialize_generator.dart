// ignore_for_file: use_string_buffers, no_default_cases

import 'package:isar/src/generator/consts.dart';
import 'package:isar/src/generator/helper.dart';
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
    transform: (value) {
      if (value == null) {
        return result(p.defaultValue);
      } else if (p.isEnum && !p.type.isList) {
        return result(
          '${p.enumMapName(object)}[$value] ?? ${p.defaultValue}',
        );
      } else {
        return result(value);
      }
    },
    transformElement: (value) {
      if (value == null) {
        return p.elementDefaultValue!;
      } else if (p.isEnum) {
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
  required String index,
  required String Function(String? value) transform,
  String Function(String? value)? transformElement,
}) {
  switch (type) {
    case PropertyType.bool:
      return '''
        {
          if (IsarCore.isarReadNull(reader, $index)) {
            ${transform(null)}
          } else {
            ${transform('IsarCore.isarReadBool(reader, $index)')}
          }
        }''';
    case PropertyType.byte:
      return '''
        {
          final value = IsarCore.isarReadByte(reader, $index);
          if (value == $nullByte) {
            ${transform(null)}
          } else {
            ${transform('value')}
          }
        }''';
    case PropertyType.int:
      return '''
        {
          final value = IsarCore.isarReadInt(reader, $index);
          if (value == $nullInt) {
            ${transform(null)}
          } else {
            ${transform('value')}
          }
        }''';
    case PropertyType.float:
      return '''
        {
          final value = IsarCore.isarReadFloat(reader, $index);
          if (value.isNaN) {
            ${transform(null)}
          } else {
            ${transform('value')}
          }
        }''';
    case PropertyType.long:
      if (isId) {
        return transform('IsarCore.isarReadId(reader)');
      } else {
        return '''
        {
          final value = IsarCore.isarReadLong(reader, $index);
          if (value == $nullLong) {
            ${transform(null)}
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
            ${transform(null)}
          } else {
            ${transform('DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal()')}
          }
        }''';
    case PropertyType.double:
      return '''
        {
          final value = IsarCore.isarReadDouble(reader, $index);
          if (value.isNaN) {
            ${transform(null)}
          } else {
            ${transform('value')}
          }
        }''';
    case PropertyType.string:
      return '''
        {
          final value = IsarCore.isarReadString(reader, $index);
          if (value == null) {
            ${transform(null)}
          } else {
            ${transform('value')}
          }
        }''';
    case PropertyType.object:
      return '''
      {
        final objectReader = IsarCore.isarReadObject(reader, $index);
        if (objectReader.isNull) {
          ${transform(null)}
        } else {
          ${transform('deserialize$typeClassName(objectReader)')}
        }
      }''';
    default:
      final deser = _deserialize(
        isId: false,
        typeClassName: typeClassName,
        type: type.scalarType,
        index: 'i',
        transform: (value) => 'list.add(${transformElement!(value)});',
      );
      return '''
      {
        final length = IsarCore.isarReadList(reader, $index, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            ${transform(null)}
          } else {
            final list = <$elementDartType>[];
            for (var i = 0; i < length; i++) {
              $deser
            }
            ${transform('list')}
          }
        }
      }''';
  }
}
