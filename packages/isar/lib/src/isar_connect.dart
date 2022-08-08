// coverage:ignore-file
// ignore_for_file: avoid_print

part of isar;

// ignore: avoid_classes_with_only_static_members
abstract class _IsarConnect {
  static const Map<ConnectAction,
      Future<dynamic> Function(Map<String, dynamic> _)> _handlers = {
    ConnectAction.getVersion: _getVersion,
    ConnectAction.getSchema: _getSchema,
    ConnectAction.listInstances: _listInstances,
    ConnectAction.watchInstance: _watchInstance,
    ConnectAction.executeQuery: _executeQuery,
    ConnectAction.removeQuery: _removeQuery,
    ConnectAction.exportJson: _exportJson,
    ConnectAction.editProperty: _editProperty,
    ConnectAction.addInList: _addInList,
    ConnectAction.removeFromList: _removeFromList,
    ConnectAction.aggregation: _aggregation,
  };

  static List<CollectionSchema<dynamic>>? _schemas;

  // ignore: cancel_subscriptions
  static final _querySubscription = <StreamSubscription<void>>[];
  static final List<StreamSubscription<void>> _collectionSubscriptions =
      <StreamSubscription<void>>[];

  static void initialize(List<CollectionSchema<dynamic>> schemas) {
    if (_schemas != null) {
      return;
    }
    _schemas = schemas;

    Isar.addOpenListener((_) {
      postEvent(ConnectEvent.instancesChanged.event, {});
    });

    Isar.addCloseListener((_) {
      postEvent(ConnectEvent.instancesChanged.event, {});
    });

    for (final handler in _handlers.entries) {
      registerExtension(handler.key.method,
          (String method, Map<String, String> parameters) async {
        try {
          final args = parameters.containsKey('args')
              ? jsonDecode(parameters['args']!) as Map<String, dynamic>
              : <String, dynamic>{};
          final result = <String, dynamic>{'result': await handler.value(args)};
          return ServiceExtensionResponse.result(jsonEncode(result));
        } catch (e) {
          return ServiceExtensionResponse.error(
            ServiceExtensionResponse.extensionError,
            e.toString(),
          );
        }
      });
    }

    _printConnection();
  }

  static void _printConnection() {
    Service.getInfo().then((ServiceProtocolInfo info) {
      final serviceUri = info.serverUri;
      if (serviceUri == null) {
        return;
      }
      final port = serviceUri.port;
      var path = serviceUri.path;
      if (path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      if (path.endsWith('=')) {
        path = path.substring(0, path.length - 1);
      }
      print('╔══════════════════════════════════════════════╗');
      print('║             ISAR CONNECT STARTED             ║');
      print('╟──────────────────────────────────────────────╢');
      print('║ Open the link in Chrome to connect to the    ║');
      print('║ Isar Inspector while this build is running.  ║');
      print('╟──────────────────────────────────────────────╢');
      print('║ https://inspect.isar.dev/#/$port$path ║');
      print('╚══════════════════════════════════════════════╝');
    });
  }

  static Future<dynamic> _getVersion(Map<String, dynamic> _) async {
    return isarCoreVersion;
  }

  static Future<dynamic> _getSchema(Map<String, dynamic> _) async {
    return [..._schemas!.map((e) => e.toSchemaJson())];
  }

  static Future<dynamic> _listInstances(Map<String, dynamic> _) async {
    return Isar.instanceNames.toList();
  }

  static Future<bool> _watchInstance(Map<String, dynamic> params) async {
    for (final sub in _collectionSubscriptions) {
      unawaited(sub.cancel());
    }

    _collectionSubscriptions.clear();
    if (params.isEmpty) {
      return true;
    }

    final instanceName = params['instance'] as String;
    final instance = Isar.getInstance(instanceName)!;

    for (final collection in instance._collections.values) {
      _sendCollectionInfo(collection);
      final sub = collection.watchLazy().listen((_) {
        _sendCollectionInfo(collection);
      });
      _collectionSubscriptions.add(sub);
    }

    return true;
  }

  static void _sendCollectionInfo(IsarCollection<dynamic> collection) {
    final count = collection.countSync();
    final size = collection.getSizeSync(
      includeIndexes: true,
      includeLinks: true,
    );
    final collectionInfo = ConnectCollectionInfo(
      instance: collection.isar.name,
      collection: collection.name,
      size: size,
      count: count,
    );
    postEvent(
      ConnectEvent.collectionInfoChanged.event,
      collectionInfo.toJson(),
    );
  }

  static Future<Map<String, dynamic>> _executeQuery(
    Map<String, dynamic> params,
  ) async {
    if (_querySubscription.isNotEmpty) {
      for (final sub in _querySubscription) {
        unawaited(sub.cancel());
      }
      _querySubscription.clear();
    }

    void listener(event) {
      postEvent(ConnectEvent.queryChanged.event, {});
    }

    final cQuery = ConnectQuery.fromJson(params);

    final links =
        _schemas!.firstWhere((e) => e.name == cQuery.collection).links;

    final query = _getQuery(cQuery);
    params.remove('limit');
    params.remove('offset');
    final countQuery = _getQuery(ConnectQuery.fromJson(params));

    final stream = query.watchLazy();
    _querySubscription.add(stream.listen(listener));

    final results = await query.exportJson();

    if (links.isNotEmpty) {
      final source = Isar.getInstance(cQuery.instance)!
          .getCollectionByNameInternal(cQuery.collection)!;
      for (var index = 0; index < results.length; index++) {
        for (final link in links.values) {
          final target = Isar.getInstance(cQuery.instance)!
              .getCollectionByNameInternal(link.target)!;

          _querySubscription.add(target.watchLazy().listen(listener));

          final qb = QueryBuilderInternal<dynamic>(
            collection: target,
            whereClauses: [
              LinkWhereClause(
                linkCollection: source.name,
                linkName: link.name,
                id: results[index][source.schema.idName] as int,
              ),
            ],
          );

          final q = QueryBuilder<dynamic, dynamic, QAfterFilterCondition>(qb);

          if (link.isSingle) {
            results[index][link.name] =
                await q.findFirst() == null ? null : (await q.exportJson())[0];
          } else {
          results[index][link.name] =
          await QueryBuilder<dynamic, dynamic, QAfterFilterCondition>(qb)
              .exportJson();
          }
        }
      }
    }

    return {
      'results': results,
      'count': await countQuery.count(),
    };
  }

  static Future<bool> _removeQuery(Map<String, dynamic> params) async {
    final query = _getQuery(ConnectQuery.fromJson(params));
    await query.isar.writeTxn(query.deleteAll);
    return true;
  }

  static Future<List<dynamic>> _exportJson(Map<String, dynamic> params) async {
    final query = _getQuery(ConnectQuery.fromJson(params));
    return query.exportJson();
  }

  static Future<void> _editProperty(Map<String, dynamic> params) async {
    final cEdit = ConnectEdit.fromJson(params);
    final collection = Isar.getInstance(cEdit.instance)!
        .getCollectionByNameInternal(cEdit.collection)!;

    final query = collection.buildQuery<dynamic>(
      whereClauses: [IdWhereClause.equalTo(value: cEdit.id)],
    );

    final objects = await query.exportJson();

    if (objects.isEmpty || !objects[0].containsKey(cEdit.property)) {
      throw IsarError('Cant get object or property is wrong for edit');
    }

    if (cEdit.index == null) {
      objects[0][cEdit.property] = cEdit.value;
    } else {
      //ignore: avoid_dynamic_calls
      objects[0][cEdit.property][cEdit.index] = cEdit.value;
    }

    await collection.isar.writeTxn(() async => collection.importJson(objects));
  }

  static Future<void> _addInList(Map<String, dynamic> params) async {
    final cEdit = ConnectEdit.fromJson(params);
    final collection = Isar.getInstance(cEdit.instance)!
        .getCollectionByNameInternal(cEdit.collection)!;

    final query = collection.buildQuery<dynamic>(
      whereClauses: [IdWhereClause.equalTo(value: cEdit.id)],
    );

    final objects = await query.exportJson();

    if (objects.isEmpty ||
        !objects[0].containsKey(cEdit.property) ||
        objects[0][cEdit.property] is! List) {
      throw IsarError('Cant get object or property is wrong for add');
    }

    if (cEdit.index == null) {
      (objects[0][cEdit.property] as List).add(cEdit.value);
    } else {
      (objects[0][cEdit.property] as List).insert(cEdit.index!, cEdit.value);
    }

    await collection.isar.writeTxn(() async => collection.importJson(objects));
  }

  static Future<void> _removeFromList(Map<String, dynamic> params) async {
    final cEdit = ConnectEdit.fromJson(params);
    final collection = Isar.getInstance(cEdit.instance)!
        .getCollectionByNameInternal(cEdit.collection)!;

    final query = collection.buildQuery<dynamic>(
      whereClauses: [IdWhereClause.equalTo(value: cEdit.id)],
    );

    final objects = await query.exportJson();

    if (objects.isEmpty ||
        !objects[0].containsKey(cEdit.property) ||
        objects[0][cEdit.property] is! List) {
      throw IsarError('Cant get object or property is wrong for remove');
    }

    (objects[0][cEdit.property] as List).removeAt(cEdit.index!);
    await collection.isar.writeTxn(() async => collection.importJson(objects));
  }

  static Future<num?> _aggregation(Map<String, dynamic> params) async {
    final cQuery = ConnectQuery.fromJson(
      params['query'] as Map<String, dynamic>,
    );

    final query = _getQuery(cQuery);
    return query.aggregate<num>(AggregationOp.values[params['op'] as int]);
  }

  static Query<dynamic> _getQuery(ConnectQuery query) {
    final collection = Isar.getInstance(query.instance)!
        .getCollectionByNameInternal(query.collection)!;
    WhereClause? whereClause;
    var whereSort = Sort.asc;
    SortProperty? sortProperty;

    final qSort = query.sortProperty;
    if (qSort != null) {
      if (qSort.property == collection.schema.idName) {
        whereClause = const IdWhereClause.any();
        whereSort = qSort.sort;
      } else {
        sortProperty = qSort;
      }
    }
    return collection.buildQuery(
      whereClauses: [if (whereClause != null) whereClause],
      whereSort: whereSort,
      filter: query.filter,
      offset: query.offset,
      limit: query.limit,
      sortBy: [if (sortProperty != null) sortProperty],
      property: query.property,
    );
  }
}
