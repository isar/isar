// coverage:ignore-file
// ignore_for_file: avoid_print

part of isar;

abstract class _IsarConnect {
  static const Map<ConnectAction,
      Future<dynamic> Function(Map<String, dynamic> _)> _handlers = {
    ConnectAction.getSchema: _getSchema,
    ConnectAction.listInstances: _listInstances,
    ConnectAction.watchInstance: _watchInstance,
    ConnectAction.executeQuery: _executeQuery,
    ConnectAction.removeQuery: _removeQuery,
    ConnectAction.importJson: _importJson,
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
      final url = ' https://inspect.isar.dev/${Isar.version}/#/$port$path ';
      String line(String text, String fill) {
        final fillCount = url.length - text.length;
        final left = List.filled(fillCount ~/ 2, fill);
        final right = List.filled(fillCount - left.length, fill);
        return left.join() + text + right.join();
      }

      print('╔${line('', '═')}╗');
      print('║${line('ISAR CONNECT STARTED', ' ')}║');
      print('╟${line('', '─')}╢');
      print('║${line('Open the link to connect to the Isar', ' ')}║');
      print('║${line('Inspector while this build is running.', ' ')}║');
      print('╟${line('', '─')}╢');
      print('║$url║');
      print('╚${line('', '═')}╝');
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
      final sub = collection.watchLazy(fireImmediately: true).listen((_) {
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
    final subscribed = {cQuery.collection};
    for (final link in links) {
      if (subscribed.add(link.target)) {
        final target = instance.getCollectionByNameInternal(link.target)!;
        _querySubscription.add(
          target.watchLazy().listen((_) {
            postEvent(ConnectEvent.queryChanged.event, {});
          }),
        );
      }
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

  static Future<void> _importJson(Map<String, dynamic> params) async {
    final instance = Isar.getInstance(params['instance'] as String)!;
    final collection =
        instance.getCollectionByNameInternal(params['collection'] as String)!;
    final objects = (params['objects'] as List).cast<Map<String, dynamic>>();
    await instance.writeTxn(() async {
      await collection.importJson(objects);
    });
  }

  static Future<List<dynamic>> _exportJson(Map<String, dynamic> params) async {
    final query = ConnectQuery.fromJson(params).toQuery();
    return query.exportJson();
  }

  static Future<void> _editProperty(Map<String, dynamic> params) async {
    final cEdit = ConnectEdit.fromJson(params);
    final isar = Isar.getInstance(cEdit.instance)!;
    final collection = isar.getCollectionByNameInternal(cEdit.collection)!;
    final keys = cEdit.path.split('.');

    final query = collection.buildQuery<dynamic>(
      whereClauses: [IdWhereClause.equalTo(value: cEdit.id)],
    );

    final objects = await query.exportJson();
    if (objects.isNotEmpty) {
      dynamic object = objects.first;
      for (var i = 0; i < keys.length; i++) {
        if (i == keys.length - 1 && object is Map) {
          object[keys[i]] = cEdit.value;
        } else if (object is Map) {
          object = object[keys[i]];
        } else if (object is List) {
          object = object[int.parse(keys[i])];
        }
      }
      try {
        await isar.writeTxn(() async {
          await collection.importJson(objects);
        });
      } catch (e) {
        print(e);
      }
    }
  }
}
