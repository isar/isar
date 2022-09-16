import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/isar_object.dart';
import 'package:isar_inspector/table/property_builder.dart';
import 'package:isar_inspector/table/property_value.dart';

class PropertyView extends StatelessWidget {
  const PropertyView({
    super.key,
    required this.property,
    required this.object,
    required this.isId,
    required this.isIndexed,
  });

  final PropertySchema property;
  final IsarObject object;
  final bool isId;
  final bool isIndexed;

  @override
  Widget build(BuildContext context) {
    final value = object.getValue(property.name);
    final valueLength =
        // ignore: avoid_dynamic_calls
        value is String || value is List ? '(${value.length})' : '';
    return PropertyBuilder(
      property: property.name,
      underline: isIndexed,
      type: isId ? 'Id' : '${property.type.typeName} $valueLength',
      value: value is List
          ? null
          : property.type.isList
              ? const NullValue()
              : PropertyValue(
                  value,
                  type: property.type,
                  enumMap: property.enumMap,
                  onUpdate: (newValue) => _onUpdate(newValue),
                ),
      children: [
        if (value is List)
          for (var i = 0; i < value.length; i++)
            PropertyBuilder(
              property: '$i',
              type: property.type.typeName,
              value: PropertyValue(
                value[i],
                type: property.type,
                enumMap: property.enumMap,
                onUpdate: (newValue) => _onUpdate(newValue),
              ),
            ),
      ],
    );
  }

  void _onUpdate(dynamic value) {
    print('UPDATE: $value');
  }
}

extension TypeName on IsarType {
  String get typeName {
    switch (this) {
      case IsarType.bool:
        return 'bool';
      case IsarType.byte:
        return 'byte';
      case IsarType.int:
        return 'short';
      case IsarType.long:
        return 'int';
      case IsarType.float:
        return 'float';
      case IsarType.double:
        return 'double';
      case IsarType.dateTime:
        return 'DateTime';
      case IsarType.string:
        return 'String';
      case IsarType.object:
        return 'Object';
      case IsarType.boolList:
        return 'List<bool>';
      case IsarType.byteList:
        return 'List<byte>';
      case IsarType.intList:
        return 'List<short>';
      case IsarType.longList:
        return 'List<int>';
      case IsarType.floatList:
        return 'List<float>';
      case IsarType.doubleList:
        return 'List<double>';
      case IsarType.dateTimeList:
        return 'List<DateTime>';
      case IsarType.stringList:
        return 'List<String>';
      case IsarType.objectList:
        return 'List<Object>';
    }
  }
}
