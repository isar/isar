// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Collection _$CollectionFromJson(Map<String, dynamic> json) {
  return Collection(
    json['name'] as String,
    (json['properties'] as List<dynamic>)
        .map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList(),
    (json['links'] as List<dynamic>)
        .map((e) => Link.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$CollectionToJson(Collection instance) =>
    <String, dynamic>{
      'name': instance.name,
      'properties': instance.properties,
      'links': instance.links,
    };

Property _$PropertyFromJson(Map<String, dynamic> json) {
  return Property(
    json['name'] as String,
    json['type'] as String,
  );
}

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
    };

Link _$LinkFromJson(Map<String, dynamic> json) {
  return Link(
    json['name'] as String,
    json['target'] as String,
  );
}

Map<String, dynamic> _$LinkToJson(Link instance) => <String, dynamic>{
      'name': instance.name,
      'target': instance.target,
    };
