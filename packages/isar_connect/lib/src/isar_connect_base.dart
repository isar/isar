import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:isar/isar.dart';

const handlers = {
  'getVersion': getVersion,
  'getSchema': getSchema,
  'listInstances': listInstances,
  'executeQuery': executeQuery,
  'watchQuery': watchQuery,
};

var _initialized = false;

void initializeIsarConnect() {
  assert(() {
    _connectInternal();
    return true;
  }());
}

void _connectInternal() {
  if (_initialized) return;
  _initialized = true;

  Isar.addOpenListener((_) {
    postEvent('isar.instancesChanged', {});
  });

  Isar.addCloseListener((_) {
    postEvent('isar.instancesChanged', {});
  });

  for (var handler in handlers.entries) {
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

Future<dynamic> getVersion(Map<String, String> _) async {
  return 1;
}

Future<dynamic> getSchema(Map<String, String> _) async {
  // ignore: invalid_use_of_protected_member
  return jsonDecode(Isar.schema!);
}

Future<dynamic> listInstances(Map<String, String> _) async {
  return Isar.instanceNames;
}

Future<List<Map<String, dynamic>>> executeQuery(Map<String, String> params) {
  final query = getQuery(params);
  return query.exportJson();
}

StreamSubscription? watchSubscription;
Future<String> watchQuery(Map<String, String> params) async {
  unawaited(watchSubscription?.cancel());
  watchSubscription = null;
  if (params['filter'] == null) return 'ok';

  final query = getQuery(params);
  final stream = query.watchLazy();

  watchSubscription = stream.listen((event) {
    postEvent('isar.queryChanged', {});
  });

  return 'ok';
}

Query getQuery(Map<String, String> params) {
  final instanceName = params['instance'] as String;
  final collectionName = params['collection'] as String;
  final collection =
      Isar.getInstance(instanceName)!.getCollection(collectionName);
  final offset = int.tryParse(params['offset'] ?? '');
  final limit = int.tryParse(params['limit'] ?? '');
  final sortProperty = params['sortProperty'];
  final sort = Sort.values[int.parse(params['sort'] ?? '0')];
  final filterJson = jsonDecode(params['filter']!);
  final filter = parseFilter(filterJson);
  return collection.buildQuery(
      filter: FilterGroup(filters: [filter], type: FilterGroupType.or),
      offset: offset,
      limit: limit,
      sortBy: [
        if (sortProperty != null)
          SortProperty(property: sortProperty, sort: sort),
      ]);
}

FilterOperation parseFilter(Map<String, dynamic> json) {
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
      if (type == FilterGroupType.and || type == FilterGroupType.or) {
        final filters = <FilterOperation>[];
        for (var filterJson in json['filters']) {
          filters.add(parseFilter(filterJson));
        }
        return FilterGroup.andOr(
          filters: filters,
          type: FilterGroupType.values[json['groupType']],
        );
      } else if(type == FilterGroupType.not) {
        final filter = parseFilter(json['filter']);
        return FilterGroup.not(filter);
      }

    default:
      throw 'Could not deserialize filter';
  }
}
