import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/isar_object.dart';
import 'package:isar_inspector/table/object_view.dart';
import 'package:isar_inspector/table/property_builder.dart';
import 'package:isar_inspector/table/property_value.dart';

class LinkPropertyView extends StatelessWidget {
  const LinkPropertyView({
    super.key,
    required this.link,
    required this.schemas,
    required this.object,
  });

  final LinkSchema link;
  final Map<String, Schema<dynamic>> schemas;
  final IsarObject object;

  @override
  Widget build(BuildContext context) {
    if (link.single) {
      final child = object.getNested(
        link.name,
        linkCollection: link.target,
      );
      return PropertyBuilder(
        property: link.name,
        type: 'IsarLink<${link.target}>',
        value: child == null ? const NullValue() : null,
        children: [
          if (child != null)
            ObjectView(
              schemaName: link.target,
              schemas: schemas,
              object: child,
            ),
        ],
      );
    } else {
      final children = object.getNestedList(
        link.name,
        linkCollection: link.target,
      );
      final childrenLength = children != null ? '(${children.length})' : '';
      return PropertyBuilder(
        property: link.name,
        type: 'IsarLinks<${link.target}>> $childrenLength',
        value: children == null ? const NullValue() : null,
        children: [
          for (var i = 0; i < (children?.length ?? 0); i++)
            PropertyBuilder(
              property: '$i',
              type: link.target,
              value: children![i] == null ? const NullValue() : null,
              children: [
                if (children[i] != null)
                  ObjectView(
                    schemaName: link.target,
                    schemas: schemas,
                    object: children[i]!,
                  ),
              ],
            ),
        ],
      );
    }
  }
}
