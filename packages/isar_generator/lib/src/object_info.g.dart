// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'object_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_ObjectInfo _$$_ObjectInfoFromJson(Map<String, dynamic> json) =>
    _$_ObjectInfo(
      dartName: json['dartName'] as String,
      isarName: json['isarName'] as String,
      accessor: json['accessor'] as String,
      properties: (json['properties'] as List<dynamic>)
          .map((e) => ObjectProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
      indexes: (json['indexes'] as List<dynamic>)
          .map((e) => ObjectIndex.fromJson(e as Map<String, dynamic>))
          .toList(),
      links: (json['links'] as List<dynamic>)
          .map((e) => ObjectLink.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$_ObjectInfoToJson(_$_ObjectInfo instance) =>
    <String, dynamic>{
      'dartName': instance.dartName,
      'isarName': instance.isarName,
      'accessor': instance.accessor,
      'properties': instance.properties,
      'indexes': instance.indexes,
      'links': instance.links,
    };

_$_ObjectProperty _$$_ObjectPropertyFromJson(Map<String, dynamic> json) =>
    _$_ObjectProperty(
      dartName: json['dartName'] as String,
      isarName: json['isarName'] as String,
      dartType: json['dartType'] as String,
      isarType: $enumDecode(_$IsarTypeEnumMap, json['isarType']),
      isId: json['isId'] as bool,
      converter: json['converter'] as String?,
      nullable: json['nullable'] as bool,
      elementNullable: json['elementNullable'] as bool,
      deserialize: $enumDecode(_$PropertyDeserEnumMap, json['deserialize']),
      assignable: json['assignable'] as bool,
      constructorPosition: json['constructorPosition'] as int?,
    );

Map<String, dynamic> _$$_ObjectPropertyToJson(_$_ObjectProperty instance) =>
    <String, dynamic>{
      'dartName': instance.dartName,
      'isarName': instance.isarName,
      'dartType': instance.dartType,
      'isarType': _$IsarTypeEnumMap[instance.isarType],
      'isId': instance.isId,
      'converter': instance.converter,
      'nullable': instance.nullable,
      'elementNullable': instance.elementNullable,
      'deserialize': _$PropertyDeserEnumMap[instance.deserialize],
      'assignable': instance.assignable,
      'constructorPosition': instance.constructorPosition,
    };

const _$IsarTypeEnumMap = {
  IsarType.bool: 'bool',
  IsarType.int: 'int',
  IsarType.float: 'float',
  IsarType.long: 'long',
  IsarType.double: 'double',
  IsarType.dateTime: 'dateTime',
  IsarType.string: 'string',
  IsarType.bytes: 'bytes',
  IsarType.boolList: 'boolList',
  IsarType.intList: 'intList',
  IsarType.floatList: 'floatList',
  IsarType.longList: 'longList',
  IsarType.doubleList: 'doubleList',
  IsarType.dateTimeList: 'dateTimeList',
  IsarType.stringList: 'stringList',
};

const _$PropertyDeserEnumMap = {
  PropertyDeser.none: 'none',
  PropertyDeser.assign: 'assign',
  PropertyDeser.positionalParam: 'positionalParam',
  PropertyDeser.namedParam: 'namedParam',
};

_$_ObjectIndexProperty _$$_ObjectIndexPropertyFromJson(
        Map<String, dynamic> json) =>
    _$_ObjectIndexProperty(
      property:
          ObjectProperty.fromJson(json['property'] as Map<String, dynamic>),
      type: $enumDecode(_$IndexTypeEnumMap, json['type']),
      caseSensitive: json['caseSensitive'] as bool,
    );

Map<String, dynamic> _$$_ObjectIndexPropertyToJson(
        _$_ObjectIndexProperty instance) =>
    <String, dynamic>{
      'property': instance.property,
      'type': _$IndexTypeEnumMap[instance.type],
      'caseSensitive': instance.caseSensitive,
    };

const _$IndexTypeEnumMap = {
  IndexType.value: 'value',
  IndexType.hash: 'hash',
  IndexType.hashElements: 'hashElements',
};

_$_ObjectIndex _$$_ObjectIndexFromJson(Map<String, dynamic> json) =>
    _$_ObjectIndex(
      name: json['name'] as String,
      properties: (json['properties'] as List<dynamic>)
          .map((e) => ObjectIndexProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
      unique: json['unique'] as bool,
    );

Map<String, dynamic> _$$_ObjectIndexToJson(_$_ObjectIndex instance) =>
    <String, dynamic>{
      'name': instance.name,
      'properties': instance.properties,
      'unique': instance.unique,
    };

_$_ObjectLink _$$_ObjectLinkFromJson(Map<String, dynamic> json) =>
    _$_ObjectLink(
      dartName: json['dartName'] as String,
      isarName: json['isarName'] as String,
      targetIsarName: json['targetIsarName'] as String?,
      targetCollectionDartName: json['targetCollectionDartName'] as String,
      targetCollectionIsarName: json['targetCollectionIsarName'] as String,
      links: json['links'] as bool,
      backlink: json['backlink'] as bool,
    );

Map<String, dynamic> _$$_ObjectLinkToJson(_$_ObjectLink instance) =>
    <String, dynamic>{
      'dartName': instance.dartName,
      'isarName': instance.isarName,
      'targetIsarName': instance.targetIsarName,
      'targetCollectionDartName': instance.targetCollectionDartName,
      'targetCollectionIsarName': instance.targetCollectionIsarName,
      'links': instance.links,
      'backlink': instance.backlink,
    };
