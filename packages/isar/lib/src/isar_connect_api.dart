// ignore_for_file: public_member_api_docs

import 'package:isar/isar.dart';

enum ConnectAction {
  listInstances('ext.isar.listInstances'),
  getSchemas('ext.isar.getSchemas'),
  watchInstance('ext.isar.watchInstance'),
  executeQuery('ext.isar.executeQuery'),
  deleteQuery('ext.isar.deleteQuery'),
  importJson('ext.isar.importJson'),
  exportJson('ext.isar.exportJson'),
  editProperty('ext.isar.editProperty');

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

class ConnectInstancePayload {
  ConnectInstancePayload(this.instance);

  factory ConnectInstancePayload.fromJson(Map<String, dynamic> json) {
    return ConnectInstancePayload(json['instance'] as String);
  }

  final String instance;

  Map<String, dynamic> toJson() {
    return {'instance': instance};
  }
}

class ConnectInstanceNamesPayload {
  ConnectInstanceNamesPayload(this.instances);

  factory ConnectInstanceNamesPayload.fromJson(Map<String, dynamic> json) {
    return ConnectInstanceNamesPayload(
      (json['instances'] as List).cast<String>(),
    );
  }

  final List<String> instances;

  Map<String, dynamic> toJson() {
    return {'instances': instances};
  }
}

class ConnectSchemasPayload {
  ConnectSchemasPayload(this.schemas);

  factory ConnectSchemasPayload.fromJson(Map<String, dynamic> json) {
    return ConnectSchemasPayload(
      (json['schemas'] as List)
          .map((e) => IsarSchema.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<IsarSchema> schemas;

  Map<String, dynamic> toJson() {
    return {
      'schemas': schemas.map((e) => e.toJson()).toList(),
    };
  }
}

class ConnectQueryPayload {
  ConnectQueryPayload({
    required this.instance,
    required this.collection,
    this.filter,
    this.offset,
    this.limit,
    this.sortProperty,
    this.sortAsc = true,
  });

  factory ConnectQueryPayload.fromJson(Map<String, dynamic> json) {
    return ConnectQueryPayload(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      filter: json['filter'] != null
          ? _filterFromJson(json['filter'] as Map<String, dynamic>)
          : null,
      offset: json['offset'] as int?,
      limit: json['limit'] as int?,
      sortProperty: json['sortProperty'] as int?,
      sortAsc: json['sortAsc'] as bool,
    );
  }

  final String instance;
  final String collection;
  final Filter? filter;
  final int? offset;
  final int? limit;
  final int? sortProperty;
  final bool sortAsc;

  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      if (filter != null) 'filter': _filterToJson(filter!),
      if (offset != null) 'offset': offset,
      if (limit != null) 'limit': limit,
      if (sortProperty != null) 'sortProperty': sortProperty,
      'sortAsc': sortAsc,
    };
  }

  static Filter _filterFromJson(Map<String, dynamic> json) {
    final property = json['property'] as int?;
    final value = json['value'] ?? json['wildcard'];
    switch (json['type']) {
      case 'eq':
        return EqualCondition(property: property!, value: value);
      case 'gt':
        return GreaterCondition(property: property!, value: value);
      case 'gte':
        return GreaterOrEqualCondition(property: property!, value: value);
      case 'lt':
        return LessCondition(property: property!, value: value);
      case 'lte':
        return LessOrEqualCondition(property: property!, value: value);
      case 'between':
        return BetweenCondition(
          property: property!,
          lower: json['lower'],
          upper: json['upper'],
        );
      case 'startsWith':
        return StartsWithCondition(property: property!, value: value as String);
      case 'endsWith':
        return EndsWithCondition(property: property!, value: value as String);
      case 'contains':
        return ContainsCondition(property: property!, value: value as String);
      case 'matches':
        return MatchesCondition(property: property!, wildcard: value as String);
      case 'isNull':
        return IsNullCondition(property: property!);
      case 'and':
        return AndGroup(
          (json['filters'] as List)
              .map((e) => _filterFromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'or':
        return OrGroup(
          (json['filters'] as List)
              .map((e) => _filterFromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'not':
        return NotGroup(
          _filterFromJson(json['filter'] as Map<String, dynamic>),
        );
      default:
        throw UnimplementedError();
    }
  }

  static Map<String, dynamic> _filterToJson(Filter filter) {
    switch (filter) {
      case EqualCondition(:final property, :final value):
        return {'type': 'eq', 'property': property, 'value': value};
      case GreaterCondition(:final property, :final value):
        return {'type': 'gt', 'property': property, 'value': value};
      case GreaterOrEqualCondition(:final property, :final value):
        return {'type': 'gte', 'property': property, 'value': value};
      case LessCondition(:final property, :final value):
        return {'type': 'lt', 'property': property, 'value': value};
      case LessOrEqualCondition(:final property, :final value):
        return {'type': 'lte', 'property': property, 'value': value};
      case BetweenCondition(
          property: final property,
          lower: final lower,
          upper: final upper,
        ):
        return {
          'type': 'between',
          'property': property,
          'lower': lower,
          'upper': upper,
        };
      case StartsWithCondition(:final property, :final value):
        return {'type': 'startsWith', 'property': property, 'value': value};
      case EndsWithCondition(:final property, :final value):
        return {'type': 'endsWith', 'property': property, 'value': value};
      case ContainsCondition(:final property, :final value):
        return {'type': 'contains', 'property': property, 'value': value};
      case MatchesCondition(property: final property, wildcard: final wildcard):
        return {'type': 'matches', 'property': property, 'value': wildcard};
      case IsNullCondition(property: final property):
        return {'type': 'isNull', 'property': property};
      case AndGroup(filters: final filters):
        return {'type': 'and', 'filters': filters.map(_filterToJson).toList()};
      case OrGroup(filters: final filters):
        return {'type': 'or', 'filters': filters.map(_filterToJson).toList()};
      case NotGroup(filter: final filter):
        return {'type': 'not', 'filter': _filterToJson(filter)};
      case ObjectFilter():
        throw UnimplementedError();
    }
  }

  IsarQuery<dynamic> toQuery(Isar isar) {
    final colIndex = isar.schemas.indexWhere((e) => e.name == this.collection);
    final collection = isar.collectionByIndex<dynamic, dynamic>(colIndex);
    return collection.buildQuery(
      filter: filter,
      sortBy: [
        if (sortProperty != null)
          SortProperty(
            property: sortProperty!,
            sort: sortAsc == true ? Sort.asc : Sort.desc,
          ),
      ],
    );
  }
}

class ConnectEditPayload {
  ConnectEditPayload({
    required this.instance,
    required this.collection,
    required this.id,
    required this.path,
    required this.value,
  });

  factory ConnectEditPayload.fromJson(Map<String, dynamic> json) {
    return ConnectEditPayload(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      id: json['id'],
      path: json['path'] as String,
      value: json['value'],
    );
  }

  final String instance;
  final String collection;
  final dynamic id;
  final String path;
  final dynamic value;

  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      'id': id,
      'path': path,
      'value': value,
    };
  }
}

class ConnectCollectionInfoPayload {
  ConnectCollectionInfoPayload({
    required this.instance,
    required this.collection,
    required this.size,
    required this.count,
  });

  factory ConnectCollectionInfoPayload.fromJson(Map<String, dynamic> json) {
    return ConnectCollectionInfoPayload(
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

class ConnectObjectsPayload {
  ConnectObjectsPayload({
    required this.instance,
    required this.collection,
    required this.objects,
    int? count,
  }) : count = count ?? objects.length;

  factory ConnectObjectsPayload.fromJson(Map<String, dynamic> json) {
    return ConnectObjectsPayload(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      objects: (json['objects'] as List).cast<Map<String, dynamic>>(),
      count: json['count'] as int,
    );
  }

  final String instance;
  final String collection;
  final List<Map<String, dynamic>> objects;
  final int count;

  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      'objects': objects,
      'count': count,
    };
  }
}
