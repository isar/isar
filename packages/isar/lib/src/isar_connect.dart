// coverage:ignore-file
// ignore_for_file: avoid_print

part of isar;

// ignore: avoid_classes_with_only_static_members
abstract class _IsarConnect {
  static const Map<ConnectAction,
      Future<dynamic> Function(Map<String, dynamic> _)> _handlers = {
    ConnectAction.getSchema: _getSchema,
    ConnectAction.listInstances: _listInstances,
    ConnectAction.watchInstance: _watchInstance,
    ConnectAction.executeQuery: _executeQuery,
    ConnectAction.removeQuery: _removeQuery,
    ConnectAction.exportJson: _exportJson,
    ConnectAction.editProperty: _editProperty,
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
      print('║ https://inspect.isar.dev/${Isar.version}/#/$port$path ║');
      print('╚══════════════════════════════════════════════╝');
    });
  }

  static Future<dynamic> _getSchema(Map<String, dynamic> _) async {
    return _schemas!.map((e) => e.toJson()).toList();
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
    for (final sub in _querySubscription) {
      unawaited(sub.cancel());
    }
    _querySubscription.clear();

    final cQuery = ConnectQuery.fromJson(params);
    final instance = Isar.getInstance(cQuery.instance)!;

    final links =
        _schemas!.firstWhere((e) => e.name == cQuery.collection).links.values;

    final query = cQuery.toQuery();
    params.remove('limit');
    params.remove('offset');
    final countQuery = ConnectQuery.fromJson(params).toQuery();

    _querySubscription.add(
      query.watchLazy().listen((_) {
        postEvent(ConnectEvent.queryChanged.event, {});
      }),
    );
    for (final link in links) {
      final target = instance.getCollectionByNameInternal(link.target)!;
      _querySubscription.add(
        target.watchLazy().listen((_) {
          postEvent(ConnectEvent.queryChanged.event, {});
        }),
      );
    }

    final objects = await query.exportJson();
    if (links.isNotEmpty) {
      final source = instance.getCollectionByNameInternal(cQuery.collection)!;
      for (final object in objects) {
        for (final link in links) {
          final target = instance.getCollectionByNameInternal(link.target)!;
          final links = await target.buildQuery<dynamic>(
            whereClauses: [
              LinkWhereClause(
                linkCollection: source.name,
                linkName: link.name,
                id: object[source.schema.idName] as int,
              ),
            ],
            limit: link.single ? 1 : null,
          ).exportJson();

          if (link.single) {
            object[link.name] = links.isEmpty ? null : links.first;
          } else {
            object[link.name] = links;
          }
        }
      }
    }

    return {
      'objects': objects,
      'count': await countQuery.count(),
    };
  }

  static Future<bool> _removeQuery(Map<String, dynamic> params) async {
    final query = ConnectQuery.fromJson(params).toQuery();
    await query.isar.writeTxn(query.deleteAll);
    return true;
  }

  static Future<List<dynamic>> _exportJson(Map<String, dynamic> params) async {
    final query = ConnectQuery.fromJson(params).toQuery();
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

    if (objects.isEmpty ||
        objects[0].setByPath(cEdit.path, cEdit.value) == null) {
      throw IsarError('Cant get object or property is wrong for edit');
    }

    await collection.isar.writeTxn(() async => collection.importJson(objects));
  }
}

extension _MapPath on Map<String, dynamic> {
  Map<String, dynamic>? setByPath(String path, dynamic value) {
    final keys = path.split('.');
    dynamic subData = this;

    try {
      for (final key in keys.take(keys.length - 1)) {
        //ignore: avoid_dynamic_calls
        subData = subData[subData is List ? int.parse(key) : key];
      }
      //ignore: avoid_dynamic_calls
      subData[subData is List ? int.parse(keys.last) : keys.last] = value;
    } catch (_) {
      return null;
    }
    return this;
  }

  dynamic getByPath(String path) {
    final keys = path.split('.');
    dynamic subData = this;

    try {
      for (final key in keys) {
        //ignore: avoid_dynamic_calls
        subData = subData[subData is List ? int.parse(key) : key];
      }
      return subData;
    } catch (_) {
      return null;
    }
  }
}
