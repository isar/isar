import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/query_builder.dart';

class ICollection {
  ICollection({
    required this.name,
    required this.idName,
    required this.properties,
    required this.links,
    required this.objects,
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
      objects: (json['objects'] as List<dynamic>).map((e) {
        return IObject.fromJson(e as Map<String, dynamic>);
      }).toList(),
    );
  }

  final String name;
  final String idName;
  final List<IProperty> properties;
  final List<ILink> links;
  final List<IObject> objects;
  QueryBuilderUIGroupHelper? uiFilter;
  SortProperty? uiSort;

  late final List<IProperty> allProperties = [
    IProperty(name: idName, type: IsarType.long, isId: true),
    ...properties,
  ];
}

@immutable
class IProperty {
  const IProperty({
    required this.name,
    required this.type,
    this.target,
    this.isIndex = false,
    this.isId = false,
  });

  factory IProperty.fromJson(
    Map<String, dynamic> json, [
    Set<String> indexes = const {}
  ]) {
    return IProperty(
      name: json['name'] as String,
      type: IsarType.values.firstWhere((e) => e.schemaName == json['type']),
      target: json['target'] as String?,
      isId: json['isId'] as bool? ?? false,
      isIndex: indexes.contains(json['name']),
    );
  }

  final String name;
  final IsarType type;

  /// Embedded Target
  final String? target;
  final bool isId;
  final bool isIndex;

  @override
  bool operator ==(Object other) {
    return other is IProperty &&
        other.name == name &&
        other.type == type &&
        other.isId == isId &&
        other.isIndex == isIndex;
  }

  @override
  int get hashCode => Object.hash(name, type, isId, isIndex);
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

class IObject {
  const IObject({
    required this.name,
    required this.properties,
  });

  factory IObject.fromJson(Map<String, dynamic> json) {
    return IObject(
      name: json['name'] as String,
      properties: (json['properties'] as List<dynamic>)
          .map((e) => IProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String name;
  final List<IProperty> properties;
}

class ILinkCollection {
  ILinkCollection({
    required this.name,
    required this.idName,
    required this.properties,
    required this.objects,
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
      objects: (json['objects'] as List<dynamic>).map((e) {
        return IObject.fromJson(e as Map<String, dynamic>);
      }).toList(),
    );
  }

  final String name;
  final String idName;
  final List<IProperty> properties;
  final List<IObject> objects;

  late final List<IProperty> allProperties = [
    IProperty(name: idName, type: IsarType.long, isId: true),
    ...properties,
  ];
}

extension IsarTypeNum on IsarType {
  bool get isNum {
    //ignore: missing_enum_constant_in_switch
    switch (this) {
      case IsarType.int:
      case IsarType.float:
      case IsarType.long:
      case IsarType.byte:
      case IsarType.double:
        return true;
    }

    return false;
  }
}
