// coverage:ignore-file
// ignore_for_file: public_member_api_docs

import 'package:isar/isar.dart';

enum ConnectAction {
  getVersion('ext.isar.getVersion'),
  getSchema('ext.isar.getSchema'),
  listInstances('ext.isar.listInstances'),
  watchInstance('ext.isar.watchInstance'),
  executeQuery('ext.isar.executeQuery'),
  removeQuery('ext.isar.removeQuery'),
  exportQuery('ext.isar.exportQuery'),
  exportJson('ext.isar.exportJson'),
  editProperty('ext.isar.editProperty'),
  addInList('ext.isar.addInList'),
  removeFromList('ext.isar.removeFromList'),
  aggregation('ext.isar.aggregation');

  const ConnectAction(this.method);

  final String method;
}

enum ConnectEvent {
  instancesChanged('isar.instancesChanged'),
  queryChanged('isar.queryChanged'),
  collectionInfoChanged('isar.collectionInfoChanged');

  const ConnectEvent(this.event);

  final String event;
}

class ConnectQuery {
  ConnectQuery({
    required this.instance,
    required this.collection,
    this.filter,
    this.offset,
    this.limit,
    this.sortProperty,
    this.property,
  });

  factory ConnectQuery.fromJson(Map<String, dynamic> json) {
    return ConnectQuery(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      filter: _filterFromJson(json['filter'] as Map<String, dynamic>?),
      offset: json['offset'] as int?,
      limit: json['limit'] as int?,
      sortProperty: json.containsKey('sortProperty')
          ? SortProperty(
              // ignore: avoid_dynamic_calls
              property: json['sortProperty']['property'] as String,
              // ignore: avoid_dynamic_calls
              sort: Sort.values[json['sortProperty']['sort'] as int],
            )
          : null,
      property: json['property'] as String?,
    );
  }

  final String instance;
  final String collection;
  final FilterOperation? filter;
  final int? offset;
  final int? limit;
  final SortProperty? sortProperty;
  final String? property;

  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      if (filter != null) 'filter': _filterToJson(filter!),
      if (offset != null) 'offset': offset,
      if (limit != null) 'limit': limit,
      if (sortProperty != null)
        'sortProperty': {
          'property': sortProperty!.property,
          'sort': sortProperty!.sort.index,
        },
      if (property != null) 'property': property
    };
  }

  static FilterOperation? _filterFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    if (json.containsKey('filters')) {
      final filters = (json['filters'] as List)
          .map((e) => _filterFromJson(e as Map<String, dynamic>?)!)
          .toList();
      return FilterGroup(
        type: FilterGroupType.values[json['type'] as int],
        filters: filters,
      );
    } else if (json.containsKey('linkName')) {
      return LinkFilter(
        filter: _filterFromJson(json['filter'] as Map<String, dynamic>)!,
        linkName: json['linkName'] as String,
        targetCollection: json['targetCollection'] as String,
      );
    } else {
      return FilterCondition(
        type: FilterConditionType.values[json['type'] as int],
        property: json['property'] as String,
        value1: json['value1'],
        value2: json['value2'],
        include1: json['include1'] as bool,
        include2: json['include2'] as bool,
        caseSensitive: json['caseSensitive'] as bool,
      );
    }
  }

  static Map<String, dynamic> _filterToJson(FilterOperation filter) {
    if (filter is FilterCondition) {
      return {
        'type': filter.type.index,
        'property': filter.property,
        'value1': filter.value1,
        'value2': filter.value2,
        'include1': filter.include1,
        'include2': filter.include2,
        'caseSensitive': filter.caseSensitive,
      };
    } else if (filter is FilterGroup) {
      return {
        'type': filter.type.index,
        'filters': filter.filters.map(_filterToJson).toList(),
      };
    } else if (filter is LinkFilter) {
      return {
        'filter': _filterToJson(filter.filter),
        'targetCollection': filter.targetCollection,
        'linkName': filter.linkName,
      };
    } else {
      throw UnimplementedError();
    }
  }
}

class ConnectEdit {
  ConnectEdit({
    required this.instance,
    required this.collection,
    required this.id,
    required this.property,
    this.index,
    required this.value,
  });

  factory ConnectEdit.fromJson(Map<String, dynamic> json) {
    return ConnectEdit(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      id: json['id'] as int,
      index: json['index'] as int?,
      property: json['property'] as String,
      value: json['value'],
    );
  }

  final String instance;
  final String collection;
  final int id;
  final String property;
  final int? index;
  final dynamic value;

  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      'id': id,
      'index': index,
      'property': property,
      'value': value,
    };
  }
}

class ConnectCollectionInfo {
  ConnectCollectionInfo({
    required this.instance,
    required this.collection,
    required this.size,
    required this.count,
  });

  factory ConnectCollectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectCollectionInfo(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      size: json['size'] as int,
      count: json['count'] as int,
    );
  }
  final String instance;
  final String collection;
  final int size;
  final int count;

  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      'size': size,
      'count': count,
    };
  }
}
