import 'dart:core';

import 'package:isar/isar.dart';
import 'package:isar_inspector/query_builder.dart';

class ICollection {
  ICollection({
    required this.name,
    required this.idName,
    required this.properties,
    required this.links,
  });

  factory ICollection.fromJson(Map<String, dynamic> json) => ICollection(
        name: json['name'] as String,
        idName: json['idName'] as String,
        properties: (json['properties'] as List<dynamic>)
            .map((e) => IProperty.fromJson(e as Map<String, dynamic>))
            .toList(),
        links: (json['links'] as List<dynamic>)
            .map((e) => ILink.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String name;
  final String idName;
  final List<IProperty> properties;
  final List<ILink> links;
  QueryBuilderUIGroupHelper? uiFilter;
  SortProperty? uiSort;

  late final List<IProperty> allProperties = [
    IProperty(name: idName, type: IsarType.Long, isId: true),
    ...properties,
  ];
}

class IProperty {
  const IProperty({
    required this.name,
    required this.type,
    this.isId = false,
  });

  factory IProperty.fromJson(Map<String, dynamic> json) => IProperty(
        name: json['name'] as String,
        type: IsarType.values.firstWhere((e) => e.name == json['type']),
        isId: json['isId'] as bool? ?? false,
      );

  final String name;
  final IsarType type;
  final bool isId;
}

class ILink {
  const ILink({
    required this.name,
    required this.target,
  });

  factory ILink.fromJson(Map<String, dynamic> json) => ILink(
        name: json['name'] as String,
        target: json['target'] as String,
      );

  final String name;
  final String target;
}

// ignore_for_file: constant_identifier_names
enum IsarType {
  Bool,
  Int,
  Float,
  Long,
  Byte,
  Double,
  String,
  ByteList,
  IntList,
  FloatList,
  LongList,
  DoubleList,
  StringList,
  BoolList;

  bool get isList {
    return const [
      ByteList,
      IntList,
      FloatList,
      LongList,
      DoubleList,
      StringList,
      BoolList
    ].contains(this);
  }

  IsarType get childType {
    //ignore: missing_enum_constant_in_switch
    switch (this) {
      case ByteList:
        return Byte;

      case IntList:
        return Int;

      case FloatList:
        return Float;

      case LongList:
        return Long;

      case DoubleList:
        return Double;

      case StringList:
        return String;

      case BoolList:
        return Bool;
    }
    throw IsarError('new IsarType ($name), rule not defined');
  }
}
