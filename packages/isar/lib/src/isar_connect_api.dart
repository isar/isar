import '../isar.dart';

enum ConnectAction {
  getVersion('ext.isar.getVersion'),
  getSchema('ext.isar.getSchema'),
  listInstances('ext.isar.listInstances'),
  watchInstance('ext.isar.watchInstance'),
  executeQuery('ext.isar.executeQuery'),
  removeQuery('ext.isar.removeQuery'),
  exportQuery('ext.isar.exportQuery');

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
              property: json['sortProperty']['property'] as String,
              sort: Sort.values[json['sortProperty']['sort'] as int],
            )
          : null,
    );
  }
  final String instance;
  final String collection;
  final FilterOperation? filter;
  final int? offset;
  final int? limit;
  final SortProperty? sortProperty;

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
    };
  }

  static FilterOperation? _filterFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    if (json.containsKey('filters')) {
      final List<FilterOperation> filters = (json['filters'] as List)
          .map((e) => _filterFromJson(e as Map<String, dynamic>?)!)
          .toList();
      return FilterGroup(
        type: FilterGroupType.values[json['type'] as int],
        filters: filters,
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
    } else {
      throw UnimplementedError();
    }
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
