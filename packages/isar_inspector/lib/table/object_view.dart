import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/isar_object.dart';
import 'package:isar_inspector/table/property_embedded_view.dart';
import 'package:isar_inspector/table/property_link_view.dart';
import 'package:isar_inspector/table/property_view.dart';

class ObjectView extends StatelessWidget {
  const ObjectView({
    super.key,
    required this.schemaName,
    required this.schemas,
    required this.object,
    this.root = false,
  });

  final bool root;
  final String schemaName;
  final Map<String, Schema<dynamic>> schemas;
  final IsarObject object;

  @override
  Widget build(BuildContext context) {
    final schema = schemas[schemaName]!;

    return Column(
      children: [
        if (schema is CollectionSchema)
          PropertyView(
            property: PropertySchema(
              id: -1,
              name: schema.idName,
              type: IsarType.long,
            ),
            object: object,
            isId: true,
            isIndexed: false,
          ),
        for (final property in schema.properties.values)
          if (property.target == null)
            PropertyView(
              property: property,
              object: object,
              isId: false,
              isIndexed: schema is CollectionSchema &&
                  schema.indexes.values.any(
                    (index) => index.properties.any(
                      (p) => p.name == property.name,
                    ),
                  ),
            )
          else
            EmbeddedPropertyView(
              property: property,
              schemas: schemas,
              object: object,
            ),
        if (root && schema is CollectionSchema)
          for (final link in schema.links.values)
            LinkPropertyView(
              link: link,
              schemas: schemas,
              object: object,
            ),
      ],
    );
  }
}
