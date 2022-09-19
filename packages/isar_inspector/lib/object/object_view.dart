import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/object/isar_object.dart';
import 'package:isar_inspector/object/property_embedded_view.dart';
import 'package:isar_inspector/object/property_link_view.dart';
import 'package:isar_inspector/object/property_view.dart';

class ObjectView extends StatelessWidget {
  const ObjectView({
    super.key,
    this.root = false,
    required this.schemaName,
    required this.schemas,
    required this.object,
    required this.onUpdate,
  });

  final bool root;
  final String schemaName;
  final Map<String, Schema<dynamic>> schemas;
  final IsarObject object;
  final void Function(
    String collection,
    int? id,
    String path,
    dynamic value,
  ) onUpdate;

  @override
  Widget build(BuildContext context) {
    final schema = schemas[schemaName]!;
    final id = schema is CollectionSchema
        ? object.getValue(schema.idName) as int
        : null;
    return Column(
      children: [
        if (schema is CollectionSchema)
          PropertyView(
            property: PropertySchema(
              id: -1,
              name: schema.idName,
              type: IsarType.long,
            ),
            value: id,
            isId: true,
            isIndexed: false,
            onUpdate: (_) => throw UnimplementedError(),
          ),
        for (final property in schema.properties.values)
          if (property.target == null)
            PropertyView(
              property: property,
              value: object.getValue(property.name),
              isId: false,
              isIndexed: schema is CollectionSchema &&
                  schema.indexes.values.any(
                    (index) => index.properties.any(
                      (p) => p.name == property.name,
                    ),
                  ),
              onUpdate: (value) {
                onUpdate(schemaName, id, property.name, value);
              },
            )
          else
            EmbeddedPropertyView(
              property: property,
              schemas: schemas,
              object: object,
              onUpdate: (_, path, value) {
                onUpdate(schemaName, id, '${property.name}.$path', value);
              },
            ),
        if (root && schema is CollectionSchema)
          for (final link in schema.links.values)
            LinkPropertyView(
              link: link,
              schemas: schemas,
              object: object,
              onUpdate: (id, path, value) {
                onUpdate(link.target, id, path, value);
              },
            ),
      ],
    );
  }
}
