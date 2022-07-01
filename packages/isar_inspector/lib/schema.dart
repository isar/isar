import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

part 'schema.g.dart';

@JsonSerializable()
class ICollection {
  ICollection({
    required this.name,
    required this.idName,
    required this.properties,
    required this.links,
  });

  factory ICollection.fromJson(Map<String, dynamic> json) =>
      _$ICollectionFromJson(json);
  final String name;
  final String idName;
  final List<IProperty> properties;
  final List<ILink> links;

  late final List<IProperty> allProperties = [
    IProperty(name: idName, type: IsarType.Long, isId: true),
    ...properties,
  ];
}

@JsonSerializable()
class IProperty {
  const IProperty({
    required this.name,
    required this.type,
    this.isId = false,
  });

  factory IProperty.fromJson(Map<String, dynamic> json) =>
      _$IPropertyFromJson(json);
  final String name;
  @JsonKey(fromJson: _typeFromJson)
  final IsarType type;
  final bool isId;
}

IsarType _typeFromJson(String type) {
  return IsarType.values.firstWhere((e) => e.name == type);
}

@JsonSerializable()
class ILink {
  const ILink({
    required this.name,
    required this.target,
  });

  factory ILink.fromJson(Map<String, dynamic> json) => _$ILinkFromJson(json);
  final String name;
  final String target;
}

// ignore_for_file: constant_identifier_names
enum IsarType {
  Bool,
  Int,
  Float,
  Long,
  Double,
  String,
  ByteList,
  IntList,
  FloatList,
  LongList,
  DoubleList,
  StringList,
  BoolList;
}
