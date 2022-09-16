// ignore_for_file: type_annotate_public_apis, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html';

import 'package:clickup_fading_scroll/clickup_fading_scroll.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/connect_client.dart';
import 'package:isar_inspector/isar_object.dart';
import 'package:isar_inspector/query_builder/query_group.dart';
import 'package:isar_inspector/table/button_prev_next.dart';
import 'package:isar_inspector/table/button_sort.dart';
import 'package:isar_inspector/table/objects_list_sliver.dart';
import 'package:isar_inspector/util.dart';

const objectsPerPage = 20;

class CollectionArea extends StatefulWidget {
  const CollectionArea({
    super.key,
    required this.instance,
    required this.collection,
    required this.schemas,
    required this.client,
  });

  final String instance;
  final String collection;
  final Map<String, Schema<dynamic>> schemas;
  final ConnectClient client;

  CollectionSchema<dynamic> get collectionSchema =>
      schemas[collection]! as CollectionSchema;

  @override
  State<CollectionArea> createState() => _CollectionAreaState();
}

class _CollectionAreaState extends State<CollectionArea> {
  final controller = ScrollController();
  var page = 0;
  var filter = const FilterGroup.and([]);
  late var sortProperty = widget.collectionSchema.idName;
  var sortAsc = true;
  var objects = <IsarObject>[];
  var objectsCount = 0;

  @override
  void initState() {
    _runQuery();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CollectionArea oldWidget) {
    if (oldWidget.instance != widget.instance ||
        oldWidget.collection != widget.collection) {
      controller.jumpTo(0);
      page = 1;
      filter = const FilterGroup.and([]);
      sortProperty = widget.collectionSchema.idName;
      sortAsc = true;
      _runQuery();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _runQuery() async {
    final query = ConnectQuery(
      instance: widget.instance,
      collection: widget.collection,
      filter: filter,
      offset: page * objectsPerPage,
      limit: (page + 1) * objectsPerPage,
      sortProperty: sortProperty,
      sortAsc: sortAsc,
    );
    final result = await widget.client.executeQuery(query);
    final objects = (result['objects']! as List)
        .map(
          (e) => IsarObject(
            collection: widget.collection,
            data: e as Map<String, dynamic>,
          ),
        )
        .toList();

    if (mounted) {
      setState(() {
        this.objects = objects;
        objectsCount = result['count']! as int;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FadingScroll(
            controller: controller,
            builder: (context, controller) {
              return CustomScrollView(
                controller: controller,
                slivers: [
                  SliverToBoxAdapter(
                    child: QueryGroup(
                      collection: widget.collectionSchema,
                      group: filter,
                      level: 0,
                      onChanged: (group) {
                        setState(() {
                          filter = group;
                        });
                        _runQuery();
                      },
                    ),
                  ),
                  ObjectsListSliver(
                    instance: widget.instance,
                    collection: widget.collection,
                    schemas: widget.schemas,
                    objects: objects,
                    onDelete: onDelte,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: PrevNextButtons(
                  page: page,
                  count: objectsCount,
                  onChanged: (newPage) {
                    setState(() {
                      page = newPage;
                    });
                    _runQuery();
                  },
                ),
              ),
            ),
            Row(
              children: [
                SortButtons(
                  properties: widget.collectionSchema.idAndProperties,
                  property: sortProperty,
                  asc: sortAsc,
                  onChanged: (property, asc) {
                    setState(() {
                      sortProperty = property;
                      sortAsc = asc;
                    });
                    _runQuery();
                  },
                ),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.delete_forever_rounded,
                        color: theme.colorScheme.onBackground,
                      ),
                      tooltip: 'Delete All',
                      onPressed: _onDelete,
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(
                        Icons.download_rounded,
                        color: theme.colorScheme.onBackground,
                      ),
                      tooltip: 'Download All',
                      onPressed: _onDownload,
                    )
                  ],
                )
              ],
            ),
          ],
        )
      ],
    );
  }

  Future<void> onDelte(int id) async {
    final query = ConnectQuery(
      instance: widget.instance,
      collection: widget.collection,
      filter: FilterCondition.equalTo(
        property: widget.collectionSchema.idName,
        value: id,
      ),
    );
    await widget.client.removeQuery(query);
    if (mounted) {
      await _runQuery();
    }
  }

  Future<void> _onDownload() async {
    final query = ConnectQuery(
      instance: widget.instance,
      collection: widget.collection,
      filter: filter,
    );
    final data = await widget.client.exportJson(query);
    try {
      final base64 = base64Encode(utf8.encode(jsonEncode(data)));
      final anchor =
          AnchorElement(href: 'data:application/octet-stream;base64,$base64')
            ..target = 'blank'
            ..download = '${widget.collection}.json';

      document.body!.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (_) {}
  }

  Future<void> _onDelete() async {
    final query = ConnectQuery(
      instance: widget.instance,
      collection: widget.collection,
      filter: filter,
    );
    await widget.client.removeQuery(query);
    await _runQuery();
  }
}
