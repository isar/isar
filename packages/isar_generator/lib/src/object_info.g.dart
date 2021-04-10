// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'object_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_ObjectInfo _$_$_ObjectInfoFromJson(Map<String, dynamic> json) {
  return _$_ObjectInfo(
    dartName: json['dartName'] as String,
    isarName: json['isarName'] as String,
    properties: (json['properties'] as List<dynamic>?)
            ?.map((e) => ObjectProperty.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    indexes: (json['indexes'] as List<dynamic>?)
            ?.map((e) => ObjectIndex.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    links: (json['links'] as List<dynamic>?)
            ?.map((e) => ObjectLink.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    imports:
        (json['imports'] as List<dynamic>?)?.map((e) => e as String).toList() ??
            [],
  );
}

Map<String, dynamic> _$_$_ObjectInfoToJson(_$_ObjectInfo instance) =>
    <String, dynamic>{
      'dartName': instance.dartName,
      'isarName': instance.isarName,
      'properties': instance.properties,
      'indexes': instance.indexes,
      'links': instance.links,
      'imports': instance.imports,
    };

_$_ObjectProperty _$_$_ObjectPropertyFromJson(Map<String, dynamic> json) {
  return _$_ObjectProperty(
    dartName: json['dartName'] as String,
    isarName: json['isarName'] as String,
    dartType: json['dartType'] as String,
    isarType: _$enumDecode(_$IsarTypeEnumMap, json['isarType']),
    isId: json['isId'] as bool,
    converter: json['converter'] as String?,
    nullable: json['nullable'] as bool,
    elementNullable: json['elementNullable'] as bool,
  );
}

Map<String, dynamic> _$_$_ObjectPropertyToJson(_$_ObjectProperty instance) =>
    <String, dynamic>{
      'dartName': instance.dartName,
      'isarName': instance.isarName,
      'dartType': instance.dartType,
      'isarType': _$IsarTypeEnumMap[instance.isarType],
      'isId': instance.isId,
      'converter': instance.converter,
      'nullable': instance.nullable,
      'elementNullable': instance.elementNullable,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$IsarTypeEnumMap = {
  IsarType.Bool: 'Bool',
  IsarType.Int: 'Int',
  IsarType.Float: 'Float',
  IsarType.Long: 'Long',
  IsarType.Double: 'Double',
  IsarType.DateTime: 'DateTime',
  IsarType.String: 'String',
  IsarType.Bytes: 'Bytes',
  IsarType.BoolList: 'BoolList',
  IsarType.IntList: 'IntList',
  IsarType.FloatList: 'FloatList',
  IsarType.LongList: 'LongList',
  IsarType.DoubleList: 'DoubleList',
  IsarType.DateTimeList: 'DateTimeList',
  IsarType.StringList: 'StringList',
};

_$_ObjectIndexProperty _$_$_ObjectIndexPropertyFromJson(
    Map<String, dynamic> json) {
  return _$_ObjectIndexProperty(
    property: ObjectProperty.fromJson(json['property'] as Map<String, dynamic>),
    indexType: _$enumDecode(_$IndexTypeEnumMap, json['indexType']),
    caseSensitive: json['caseSensitive'] as bool?,
  );
}

Map<String, dynamic> _$_$_ObjectIndexPropertyToJson(
        _$_ObjectIndexProperty instance) =>
    <String, dynamic>{
      'property': instance.property,
      'indexType': _$IndexTypeEnumMap[instance.indexType],
      'caseSensitive': instance.caseSensitive,
    };

const _$IndexTypeEnumMap = {
  IndexType.value: 'value',
  IndexType.hash: 'hash',
  IndexType.words: 'words',
};

_$_ObjectIndex _$_$_ObjectIndexFromJson(Map<String, dynamic> json) {
  return _$_ObjectIndex(
    properties: (json['properties'] as List<dynamic>)
        .map((e) => ObjectIndexProperty.fromJson(e as Map<String, dynamic>))
        .toList(),
    unique: json['unique'] as bool,
    replace: json['replace'] as bool,
  );
}

Map<String, dynamic> _$_$_ObjectIndexToJson(_$_ObjectIndex instance) =>
    <String, dynamic>{
      'properties': instance.properties,
      'unique': instance.unique,
      'replace': instance.replace,
    };

_$_ObjectLink _$_$_ObjectLinkFromJson(Map<String, dynamic> json) {
  return _$_ObjectLink(
    dartName: json['dartName'] as String,
    isarName: json['isarName'] as String,
    targetDartName: json['targetDartName'] as String?,
    targetCollectionDartName: json['targetCollectionDartName'] as String,
    links: json['links'] as bool,
    backlink: json['backlink'] as bool,
    linkIndex: json['linkIndex'] as int? ?? -1,
  );
}

Map<String, dynamic> _$_$_ObjectLinkToJson(_$_ObjectLink instance) =>
    <String, dynamic>{
      'dartName': instance.dartName,
      'isarName': instance.isarName,
      'targetDartName': instance.targetDartName,
      'targetCollectionDartName': instance.targetCollectionDartName,
      'links': instance.links,
      'backlink': instance.backlink,
      'linkIndex': instance.linkIndex,
    };
