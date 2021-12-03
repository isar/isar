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
    (json['indexes'] as List<dynamic>)
        .map((e) => Index.fromJson(e as Map<String, dynamic>))
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
      'indexes': instance.indexes,
      'links': instance.links,
    };

_$_Property _$_$_PropertyFromJson(Map<String, dynamic> json) {
  return _$_Property(
    json['name'] as String,
    json['type'] as int,
  );
}

Map<String, dynamic> _$_$_PropertyToJson(_$_Property instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
    };

_$_Index _$_$_IndexFromJson(Map<String, dynamic> json) {
  return _$_Index(
    json['unique'] as bool,
    json['replace'] as bool,
    (json['properties'] as List<dynamic>)
        .map((e) => IndexProperty.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$_$_IndexToJson(_$_Index instance) => <String, dynamic>{
      'unique': instance.unique,
      'replace': instance.replace,
      'properties': instance.properties,
    };

_$_IndexProperty _$_$_IndexPropertyFromJson(Map<String, dynamic> json) {
  return _$_IndexProperty(
    json['name'] as String,
    json['indexType'] as int,
    json['caseSensitive'] as bool,
  );
}

Map<String, dynamic> _$_$_IndexPropertyToJson(_$_IndexProperty instance) =>
    <String, dynamic>{
      'name': instance.name,
      'indexType': instance.indexType,
      'caseSensitive': instance.caseSensitive,
    };

_$_Link _$_$_LinkFromJson(Map<String, dynamic> json) {
  return _$_Link(
    json['name'] as String,
    json['collection'] as String,
  );
}

Map<String, dynamic> _$_$_LinkToJson(_$_Link instance) => <String, dynamic>{
      'name': instance.name,
      'collection': instance.collection,
    };
