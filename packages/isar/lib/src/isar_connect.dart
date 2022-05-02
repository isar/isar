part of isar;

const _handlers = {
  'getVersion': _getVersion,
  'getSchema': _getSchema,
  'listInstances': _listInstances,
  'executeQuery': _executeQuery,
  'watchQuery': _watchQuery,
};

var _initialized = false;
void _initializeIsarConnect() {
  if (_initialized) return;
  _initialized = true;

  Isar.addOpenListener((_) {
    postEvent('isar.instancesChanged', {});
  });

  Isar.addCloseListener((_) {
    postEvent('isar.instancesChanged', {});
  });

  for (var handler in _handlers.entries) {
    registerExtension('ext.isar.${handler.key}', (method, parameters) async {
      try {
        final result = await handler.value(parameters);
        final map = {
          'value': result,
          'type': '_extensionType',
        };
        return ServiceExtensionResponse.result(jsonEncode(map));
      } catch (e) {
        return ServiceExtensionResponse.error(
          ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });
  }

  Service.getInfo().then((info) {
    final serviceUri = info.serverUri;
    if (serviceUri == null) {
      print('╔════════════════════════════════════════╗');
      print('║      ERROR STARTING ISAR CONNECT       ║');
      print('╟────────────────────────────────────────╢');
      print('║ No Dart Service seems to be connected  ║');
      print('╚════════════════════════════════════════╝');
      return;
    }
    final uri = serviceUri.replace(scheme: 'ws');
    print('╔════════════════════════════════════════╗');
    print('║          ISAR CONNECT STARTED          ║');
    print('╟────────────────────────────────────────╢');
    print('║ Open the Isar Inspector and enter the  ║');
    print('║ following URL to connect:              ║');
    print('╟────────────────────────────────────────╢');
    print('║   $uri   ║');
    print('╚════════════════════════════════════════╝');
  });
}

Future<dynamic> _getVersion(Map<String, String> _) async {
  return 1;
}

Future<dynamic> _getSchema(Map<String, String> _) async {
  // ignore: invalid_use_of_protected_member
  return jsonDecode(Isar.schema!);
}

Future<dynamic> _listInstances(Map<String, String> _) async {
  return Isar.instanceNames.toList();
}

Future<List<Map<String, dynamic>>> _executeQuery(Map<String, String> params) {
  final query = _getQuery(params);
  return query.exportJson();
}

StreamSubscription? _watchSubscription;

Future<String> _watchQuery(Map<String, String> params) async {
  if (_watchSubscription != null) {
    unawaited(_watchSubscription!.cancel());
  }

  _watchSubscription = null;
  if (params['filter'] == null) return 'ok';

  final query = _getQuery(params);
  final stream = query.watchLazy();

  _watchSubscription = stream.listen((event) {
    postEvent('isar.queryChanged', {});
  });

  return 'ok';
}

Query _getQuery(Map<String, String> params) {
  final instanceName = params['instance'] as String;
  final collectionName = params['collection'] as String;
  final collection =
      Isar.getInstance(instanceName)!.getCollectionInternal(collectionName)!;
  final offset = int.tryParse(params['offset'] ?? '');
  final limit = int.tryParse(params['limit'] ?? '');
  final sortProperty = params['sortProperty'];
  final sort = Sort.values[int.parse(params['sort'] ?? '0')];
  final filterJson = jsonDecode(params['filter']!);
  final filter = _parseFilter(filterJson);
  return collection.buildQuery(
      filter: FilterGroup.or([filter]),
      offset: offset,
      limit: limit,
      sortBy: [
        if (sortProperty != null)
          SortProperty(property: sortProperty, sort: sort),
      ]);
}

FilterOperation _parseFilter(Map<String, dynamic> json) {
  final type = json['type'];
  switch (type) {
    case 'FilterCondition':
      final type = ConditionType.values[json['conditionType']];
      if (type != ConditionType.between) {
        return FilterCondition(
          type: type,
          property: json['property'],
          value: json['value'],
          caseSensitive: json['caseSensitive'],
        );
      } else {
        return FilterCondition.between(
          property: json['property'],
          lower: json['lower'],
          upper: json['upper'],
          caseSensitive: json['caseSensitive'],
        );
      }

    case 'FilterGroup':
      final type = FilterGroupType.values[json['groupType']];
      if (type == FilterGroupType.not) {
        final filter = _parseFilter(json['filter']!);
        return FilterGroup.not(filter);
      } else {
        final filters = <FilterOperation>[];
        for (var filterJson in json['filters']) {
          filters.add(_parseFilter(filterJson));
        }

        if (type == FilterGroupType.and) {
          return FilterGroup.and(filters);
        }
        return FilterGroup.or(filters);
      }
    default:
      throw 'Could not deserialize filter';
  }
}
