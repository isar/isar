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

  factory ICollection.fromJson(
    Map<String, dynamic> json,
    List<dynamic> schema,
  ) {
    final indexes = <String>{};
    final jsonIndexes = json['indexes'] as List<dynamic>;

    for (var i = 0; i < jsonIndexes.length; i++) {
      indexes.addAll(
        //ignore: avoid_dynamic_calls
        (jsonIndexes[i]['properties'] as List<dynamic>).map(
          (e) {
            //ignore: avoid_dynamic_calls
            return e['name'] as String;
          },
        ).toList(),
      );
    }

    return ICollection(
      name: json['name'] as String,
      idName: json['idName'] as String,
      properties: (json['properties'] as List<dynamic>)
          .map((e) => IProperty.fromJson(e as Map<String, dynamic>, indexes))
          .toList(),
      links: (json['links'] as List<dynamic>).map((e) {
        return ILink.fromJson(e as Map<String, dynamic>, schema);
      }).toList(),
    );
  }

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
    this.isIndex = false,
    this.isId = false,
  });

  factory IProperty.fromJson(Map<String, dynamic> json, Set<String> indexes) {
    return IProperty(
      name: json['name'] as String,
      type: IsarType.values.firstWhere((e) => e.name == json['type']),
      isId: json['isId'] as bool? ?? false,
      isIndex: indexes.contains(json['name']),
    );
  }

  final String name;
  final IsarType type;
  final bool isId;
  final bool isIndex;
}

class ILink {
  const ILink({
    required this.name,
    required this.single,
    required this.target,
  });

  factory ILink.fromJson(
    Map<String, dynamic> json,
    List<dynamic> schema,
  ) {
    return ILink(
      name: json['name'] as String,
      single: json['single'] as bool,
      target: ILinkCollection.fromJson(
        //ignore: avoid_dynamic_calls
        schema.firstWhere((e) => e['name'] == json['target'])
            as Map<String, dynamic>,
      ),
    );
  }

  final String name;
  final bool single;
  final ILinkCollection target;
}

class ILinkCollection {
  ILinkCollection({
    required this.name,
    required this.idName,
    required this.properties,
  });

  factory ILinkCollection.fromJson(Map<String, dynamic> json) {
    final indexes = <String>{};
    final jsonIndexes = json['indexes'] as List<dynamic>;

    for (var i = 0; i < jsonIndexes.length; i++) {
      indexes.addAll(
        //ignore: avoid_dynamic_calls
        (jsonIndexes[i]['properties'] as List<dynamic>).map(
          (e) {
            //ignore: avoid_dynamic_calls
            return e['name'] as String;
          },
        ).toList(),
      );
    }

    return ILinkCollection(
      name: json['name'] as String,
      idName: json['idName'] as String,
      properties: (json['properties'] as List<dynamic>)
          .map((e) => IProperty.fromJson(e as Map<String, dynamic>, indexes))
          .toList(),
    );
  }

  final String name;
  final String idName;
  final List<IProperty> properties;

  late final List<IProperty> allProperties = [
    IProperty(name: idName, type: IsarType.Long, isId: true),
    ...properties,
  ];
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
      BoolList,
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
