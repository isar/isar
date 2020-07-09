// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'object_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObjectInfo _$ObjectInfoFromJson(Map<String, dynamic> json) {
  return ObjectInfo(
    json['localName'] as String,
    json['name'] as String,
  )
    ..fields = (json['fields'] as List)
        .map((e) => ObjectField.fromJson(e as Map<String, dynamic>))
        .toList()
    ..indices = (json['indices'] as List)
        .map((e) => ObjectIndex.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$ObjectInfoToJson(ObjectInfo instance) =>
    <String, dynamic>{
      'localName': instance.name,
      'name': instance.dbName,
      'fields': instance.fields.map((e) => e.toJson()).toList(),
      'indices': instance.indices.map((e) => e.toJson()).toList(),
    };

ObjectField _$ObjectFieldFromJson(Map<String, dynamic> json) {
  return ObjectField(
    json['localName'] as String,
    json['name'] as String,
    _$enumDecode(_$DataTypeEnumMap, json['type']),
    json['nullable'] as bool,
  );
}

Map<String, dynamic> _$ObjectFieldToJson(ObjectField instance) =>
    <String, dynamic>{
      'localName': instance.name,
      'name': instance.dbName,
      'type': _$DataTypeEnumMap[instance.type],
      'nullable': instance.nullable,
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

const _$DataTypeEnumMap = {
  DataType.Int: 0,
  DataType.Double: 1,
  DataType.Bool: 2,
  DataType.String: 3,
  DataType.Bytes: 4,
  DataType.IntList: 5,
  DataType.DoubleList: 6,
  DataType.BoolList: 7,
  DataType.StringList: 8,
  DataType.BytesList: 9,
};

ObjectIndex _$ObjectIndexFromJson(Map<String, dynamic> json) {
  return ObjectIndex()
    ..fields = (json['fields'] as List).map((e) => e as String).toList()
    ..unique = json['unique'] as bool
    ..hashValue = json['hashValue'] as bool;
}

Map<String, dynamic> _$ObjectIndexToJson(ObjectIndex instance) =>
    <String, dynamic>{
      'fields': instance.fields,
      'unique': instance.unique,
      'hashValue': instance.hashValue,
    };
