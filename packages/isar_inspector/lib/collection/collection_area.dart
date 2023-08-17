// ignore_for_file: type_annotate_public_apis, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:clickup_fading_scroll/clickup_fading_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/collection/button_prev_next.dart';
import 'package:isar_inspector/collection/button_sort.dart';
import 'package:isar_inspector/collection/objects_list_sliver.dart';
import 'package:isar_inspector/connect_client.dart';
import 'package:isar_inspector/object/isar_object.dart';
import 'package:isar_inspector/query_builder/query_filter.dart';
import 'package:isar_inspector/query_builder/query_group.dart';
import 'package:isar_inspector/util.dart';

const objectsPerPage = 20;

class CollectionArea extends StatefulWidget {
  CollectionArea({
    required this.instance,
    required this.collection,
    required this.schemas,
    required this.client,
    super.key,
  });

  final String instance;
  final String collection;
  final Map<String, IsarSchema> schemas;
  final ConnectClient client;

  late final schema = schemas[collection]!;

  @override
  State<CollectionArea> createState() => _CollectionAreaState();
}

class _CollectionAreaState extends State<CollectionArea> {
  final controller = ScrollController();
  late final StreamSubscription<void> querySubscription;

  var page = 0;
  var filter = FilterGroup(true, []);
  late var sortProperty = widget.schema.idName!;
  var sortAsc = true;

  var objects = <IsarObject>[];
  var objectsCount = 0;

  @override
  void initState() {
    querySubscription = widget.client.queryChanged.listen((_) {
      _runQuery();
    });
    _runQuery();
    super.initState();
  }

  @override
  void dispose() {
    querySubscription.cancel();
    super.dispose();
  }

  Future<void> _runQuery() async {
    final query = ConnectQueryPayload(
      instance: widget.instance,
      collection: widget.collection,
      filter: filter.toIsarFilter(),
      offset: page * objectsPerPage,
      limit: (page + 1) * objectsPerPage,
      sortProperty: widget.schema.getPropertyIndex(sortProperty),
      sortAsc: sortAsc,
    );
    final result = await widget.client.executeQuery(query);
    final objects = result.objects.map(IsarObject.new).toList();

    if (mounted) {
      setState(() {
        this.objects = objects;
        objectsCount = result.count;
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
                      key: Key('${widget.schema.name}-filter'),
                      schema: widget.schema,
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
                    onUpdate: _onUpdate,
                    onDelete: _onDelete,
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
                  properties: [
                    for (final p in widget.schema.idAndProperties)
                      if (!p.type.isObject && !p.type.isList) p.name,
                  ],
                  selectedProperty: sortProperty,
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
                        Icons.add_rounded,
                        color: theme.colorScheme.onBackground,
                      ),
                      iconSize: 26,
                      tooltip: 'Create Object',
                      onPressed: _onCreate,
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      icon: Icon(
                        Icons.paste_rounded,
                        color: theme.colorScheme.onBackground,
                      ),
                      iconSize: 20,
                      tooltip: 'Import JSON from clipboard',
                      onPressed: _onImport,
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      icon: Icon(
                        Icons.download_rounded,
                        color: theme.colorScheme.onBackground,
                      ),
                      tooltip: 'Download All',
                      onPressed: _onDownload,
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      icon: Icon(
                        Icons.delete_forever_rounded,
                        color: theme.colorScheme.onBackground,
                      ),
                      tooltip: 'Delete All',
                      onPressed: _onDeleteAll,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _onUpdate(dynamic id, String path, dynamic value) {
    final edit = ConnectEditPayload(
      instance: widget.instance,
      collection: widget.collection,
      id: id,
      path: path,
      value: value,
    );
    widget.client.editProperty(edit);
  }

  void _onDelete(dynamic id) {
    final query = ConnectQueryPayload(
      instance: widget.instance,
      collection: widget.collection,
      filter: EqualCondition(
        property: widget.schema.getPropertyIndex(widget.schema.idName!),
        value: id,
      ),
    );
    widget.client.deleteQuery(query);
  }

  Future<void> _onCreate() async {
    final randInt = Random().nextInt(100000000);
    final idIndex = widget.schema.getPropertyIndex(widget.schema.idName!);
    final randomId = idIndex == 0 ? randInt : '$randInt';
    final p = ConnectObjectsPayload(
      instance: widget.instance,
      collection: widget.collection,
      objects: [
        {widget.schema.idName!: randomId},
      ],
    );

    setState(() {
      page = 0;
      filter = FilterGroup(true, [
        FilterCondition(
          property: idIndex,
          type: FilterType.equalTo,
          value1: randomId,
        ),
      ]);
    });
    await widget.client.importJson(p);
    await _runQuery();
  }

  Future<void> _onImport() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final jsonStr = await Clipboard.getData(Clipboard.kTextPlain);
      var json = jsonDecode(jsonStr!.text!);
      if (json is! List) {
        json = [json];
      }
      final p = ConnectObjectsPayload(
        instance: widget.instance,
        collection: widget.collection,
        objects: json.cast(),
      );
      await widget.client.importJson(p);
    } on PlatformException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not access clipboard.')),
      );
    } on FormatException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid JSON in clipboard.')),
      );
    }
  }

  void _onDeleteAll() {
    final query = ConnectQueryPayload(
      instance: widget.instance,
      collection: widget.collection,
      filter: filter.toIsarFilter(),
    );
    widget.client.deleteQuery(query);
  }

  Future<void> _onDownload() async {
    final query = ConnectQueryPayload(
      instance: widget.instance,
      collection: widget.collection,
      filter: filter.toIsarFilter(),
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
}
