import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/object/isar_object.dart';
import 'package:isar_inspector/object/property_embedded_view.dart';
import 'package:isar_inspector/object/property_view.dart';
import 'package:isar_inspector/util.dart';

class ObjectView extends StatelessWidget {
  const ObjectView({
    required this.schemaName,
    required this.schemas,
    required this.object,
    required this.onUpdate,
    super.key,
  });

  final String schemaName;
  final Map<String, IsarSchema> schemas;
  final IsarObject object;
  final void Function(String path, dynamic value) onUpdate;

  @override
  Widget build(BuildContext context) {
    final schema = schemas[schemaName]!;
    return Column(
      children: [
        for (final property in schema.idAndProperties)
          if (property.target == null)
            PropertyView(
              property: property,
              value: object.getValue(property.name),
              isId: property.name == schema.idName,
              isIndexed: schema.indexes.any(
                (index) => index.properties.any((p) => p == property.name),
              ),
              onUpdate: (value) {
                onUpdate(property.name, value);
              },
            )
          else
            EmbeddedPropertyView(
              property: property,
              schemas: schemas,
              object: object,
              onUpdate: (path, value) {
                onUpdate('${property.name}.$path', value);
              },
            ),
      ],
    );
  }
}
