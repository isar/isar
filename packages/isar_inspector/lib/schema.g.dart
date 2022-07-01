// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ICollection _$ICollectionFromJson(Map<String, dynamic> json) => ICollection(
      name: json['name'] as String,
      idName: json['idName'] as String,
      properties: (json['properties'] as List<dynamic>)
          .map((e) => IProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
      links: (json['links'] as List<dynamic>)
          .map((e) => ILink.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ICollectionToJson(ICollection instance) =>
    <String, dynamic>{
      'name': instance.name,
      'idName': instance.idName,
      'properties': instance.properties,
      'links': instance.links,
    };

IProperty _$IPropertyFromJson(Map<String, dynamic> json) => IProperty(
      name: json['name'] as String,
      type: _typeFromJson(json['type'] as String),
      isId: json['isId'] as bool? ?? false,
    );

Map<String, dynamic> _$IPropertyToJson(IProperty instance) => <String, dynamic>{
      'name': instance.name,
      'type': _$IsarTypeEnumMap[instance.type],
      'isId': instance.isId,
    };

const _$IsarTypeEnumMap = {
  IsarType.Bool: 'Bool',
  IsarType.Int: 'Int',
  IsarType.Float: 'Float',
  IsarType.Long: 'Long',
  IsarType.Double: 'Double',
  IsarType.String: 'String',
  IsarType.ByteList: 'ByteList',
  IsarType.IntList: 'IntList',
  IsarType.FloatList: 'FloatList',
  IsarType.LongList: 'LongList',
  IsarType.DoubleList: 'DoubleList',
  IsarType.StringList: 'StringList',
  IsarType.BoolList: 'BoolList',
};

ILink _$ILinkFromJson(Map<String, dynamic> json) => ILink(
      name: json['name'] as String,
      target: json['target'] as String,
    );

Map<String, dynamic> _$ILinkToJson(ILink instance) => <String, dynamic>{
      'name': instance.name,
      'target': instance.target,
    };
