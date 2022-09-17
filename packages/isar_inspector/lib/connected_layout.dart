import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/collection/collection_area.dart';
import 'package:isar_inspector/connect_client.dart';
import 'package:isar_inspector/sidebar.dart';

class ConnectedLayout extends StatefulWidget {
  const ConnectedLayout({
    super.key,
    required this.client,
    required this.instances,
    required this.collections,
  });

  final ConnectClient client;
  final List<String> instances;
  final List<CollectionSchema<dynamic>> collections;

  @override
  State<ConnectedLayout> createState() => _ConnectedLayoutState();
}

class _ConnectedLayoutState extends State<ConnectedLayout> {
  late String selectedInstance;
  late String selectedCollection = widget.collections.first.name;
  late StreamSubscription<void> infoSubscription;

  @override
  void initState() {
    _selectInstance(widget.instances.first);
    infoSubscription = widget.client.collectionInfoChanged.listen((_) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ConnectedLayout oldWidget) {
    if (!widget.instances.contains(selectedInstance)) {
      _selectInstance(widget.instances.first);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    infoSubscription.cancel();
    super.dispose();
  }

  void _selectInstance(String instance) {
    selectedInstance = instance;
    widget.client.watchInstance(instance);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 320,
            child: Sidebar(
              instances: widget.instances,
              selectedInstance: selectedInstance,
              onInstanceSelected: (instance) {
                setState(() {
                  _selectInstance(instance);
                });
              },
              collections: widget.collections,
              collectionInfo: widget.client.collectionInfo,
              selectedCollection: selectedCollection,
              onCollectionSelected: (collection) {
                setState(() {
                  selectedCollection = collection;
                });
              },
            ),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: CollectionArea(
              key: Key('$selectedInstance.$selectedCollection'),
              instance: selectedInstance,
              collection: selectedCollection,
              client: widget.client,
              schemas: {
                for (final schema in widget.collections) ...{
                  schema.name: schema,
                  for (final embedded in schema.embeddedSchemas.values) ...{
                    embedded.name: embedded,
                  }
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
