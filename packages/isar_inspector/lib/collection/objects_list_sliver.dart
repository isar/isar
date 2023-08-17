import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/object/isar_object.dart';
import 'package:isar_inspector/object/object_view.dart';

class ObjectsListSliver extends StatelessWidget {
  const ObjectsListSliver({
    required this.instance,
    required this.collection,
    required this.schemas,
    required this.objects,
    required this.onUpdate,
    required this.onDelete,
    super.key,
  });

  final String instance;
  final String collection;
  final Map<String, IsarSchema> schemas;
  final List<IsarObject> objects;
  final void Function(dynamic id, String path, dynamic value) onUpdate;
  final void Function(dynamic id) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = schemas[collection]!;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: objects.length,
        (BuildContext context, int index) {
          final object = objects[index];
          final id = object.getValue(schema.idName!);
          return Card(
            key: Key('object $id'),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: ObjectView(
                      schemaName: collection,
                      schemas: schemas,
                      object: object,
                      onUpdate: (path, value) => onUpdate(id, path, value),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.copy_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          tooltip: 'Copy as JSON',
                          visualDensity: VisualDensity.standard,
                          onPressed: () {
                            final json = jsonEncode(object.data);
                            Clipboard.setData(ClipboardData(text: json));
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.standard,
                          onPressed: () => onDelete(id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
