// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_Collection _$_$_CollectionFromJson(Map<String, dynamic> json) {
  return _$_Collection(
    json['name'] as String,
    (json['properties'] as List<dynamic>)
        .map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList(),
    (json['links'] as List<dynamic>)
        .map((e) => Link.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$_$_CollectionToJson(_$_Collection instance) =>
    <String, dynamic>{
      'name': instance.name,
      'properties': instance.properties,
      'links': instance.links,
    };

_$_Property _$_$_PropertyFromJson(Map<String, dynamic> json) {
  return _$_Property(
    json['name'] as String,
    json['type'] as String,
  );
}

Map<String, dynamic> _$_$_PropertyToJson(_$_Property instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
    };

_$_Link _$_$_LinkFromJson(Map<String, dynamic> json) {
  return _$_Link(
    json['name'] as String,
    json['target'] as String,
  );
}

Map<String, dynamic> _$_$_LinkToJson(_$_Link instance) => <String, dynamic>{
      'name': instance.name,
      'target': instance.target,
    };
