import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:isar/isar.dart';
import 'package:isar/src/isar_interface.dart';
import 'package:isar/src/query_builder.dart';
import 'package:pedantic/pedantic.dart';

const handlers = {
  'getVersion': getVersion,
  'getSchema': getSchema,
  'listInstances': listInstances,
  'executeQuery': executeQuery,
  'watchQuery': watchQuery,
};

var _initialized = false;

void connectToInspector() {
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
}

Future<dynamic> getVersion(Map<String, String> _) async {
  return 1;
}

Future<dynamic> getSchema(Map<String, String> _) async {
  return jsonDecode(IsarInterface.instance!.schemaJson);
}

Future<dynamic> listInstances(Map<String, String> _) async {
  return IsarInterface.instance!.instanceNames;
}

Future<List<Map<String, dynamic>>> executeQuery(
    Map<String, String> params) async {
  final query = getQuery(params);
  final results = await query.findAll();
  return results.map((e) => IsarInterface.instance!.objectToJson(e)).toList();
}

StreamSubscription? watchSubscription;
Future<String> watchQuery(Map<String, String> params) async {
  unawaited(watchSubscription?.cancel());
  watchSubscription = null;
  if (params['filter'] == null) return 'ok';

  final query = getQuery(params);
  final stream = query.watch(lazy: true);

  watchSubscription = stream.listen((event) {
    postEvent('isar.queryChanged', {});
  });

  return 'ok';
}

Query getQuery(Map<String, String> params) {
  final instanceName = params['instance'] as String;
  final collectionName = params['collection'] as String;
  final collection = IsarInterface.instance!.getCollection(
    instanceName,
    collectionName,
  );
  final offset = int.tryParse(params['offset'] ?? '');
  final limit = int.tryParse(params['limit'] ?? '');
  final sortPropertyIndex = int.tryParse(params['sortPropertyIndex'] ?? '');
  final ascending = params['ascending'] == 'true';
  final filterJson = jsonDecode(params['filter']!);
  final filter = parseFilter(filterJson);
  return collection
      .where()
      .addFilterCondition(filter)
      .copyWith(
        offset: offset,
        limit: limit,
        sortByProperties: sortPropertyIndex != null
            ? [SortProperty(sortPropertyIndex, ascending)]
            : null,
      )
      .buildInternal();
}

QueryOperation parseFilter(Map<String, dynamic> json) {
  final type = json['type'];
  switch (type) {
    case 'QueryCondition':
      return QueryCondition(
        ConditionType.values[json['conditionType']],
        json['propertyIndex'],
        json['propertyType'],
        lower: json['lower'],
        includeLower: json['includeLower'],
        upper: json['upper'],
        includeUpper: json['includeUpper'],
        caseSensitive: json['caseSensitive'],
      );
    case 'FilterGroup':
      final conditions = <QueryOperation>[];
      for (var conditionJson in json['conditions']) {
        conditions.add(parseFilter(conditionJson));
      }
      return FilterGroup(
        conditions: conditions,
        groupType: FilterGroupType.values[json['groupType']],
      );
    default:
      throw 'Could not deserialize filter';
  }
}
