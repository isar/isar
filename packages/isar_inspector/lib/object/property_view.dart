import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/object/property_builder.dart';
import 'package:isar_inspector/object/property_value.dart';
import 'package:isar_inspector/util.dart';

class PropertyView extends StatelessWidget {
  const PropertyView({
    required this.property,
    required this.value,
    required this.isId,
    required this.isIndexed,
    required this.onUpdate,
    super.key,
  });

  final IsarPropertySchema property;
  final dynamic value;
  final bool isId;
  final bool isIndexed;
  final void Function(dynamic value) onUpdate;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final valueLength =
        // ignore: avoid_dynamic_calls
        value is String || value is List ? '(${value.length})' : '';
    return PropertyBuilder(
      property: property.name,
      bold: isId,
      underline: isIndexed,
      type: '${property.type.typeName} $valueLength',
      value: value is List
          ? null
          : property.type.isList
              ? const NullValue()
              : PropertyValue(
                  value,
                  type: property.type,
                  enumMap: property.enumMap,
                  onUpdate: isId ? null : onUpdate,
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
                onUpdate: onUpdate,
              ),
            ),
      ],
    );
  }
}
