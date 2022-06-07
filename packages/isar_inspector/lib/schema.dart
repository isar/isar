import 'package:json_annotation/json_annotation.dart';

part 'schema.g.dart';

@JsonSerializable()
class ICollection {
  final String name;
  final String idName;
  final List<IProperty> properties;
  final List<ILink> links;

  ICollection({
    required this.name,
    required this.idName,
    required this.properties,
    required this.links,
  });

  late final allProperties = [
    IProperty(name: idName, type: IsarType.Long, isId: true),
    ...properties,
  ];

  factory ICollection.fromJson(Map<String, dynamic> json) =>
      _$ICollectionFromJson(json);
}

@JsonSerializable()
class IProperty {
  final String name;
  @JsonKey(fromJson: _typeFromJson)
  final IsarType type;
  final bool isId;

  const IProperty({
    required this.name,
    required this.type,
    this.isId = false,
  });

  factory IProperty.fromJson(Map<String, dynamic> json) =>
      _$IPropertyFromJson(json);
}

IsarType _typeFromJson(String type) {
  return IsarType.values.firstWhere((e) => e.name == type);
}

@JsonSerializable()
class ILink {
  final String name;
  final String target;

  const ILink({
    required this.name,
    required this.target,
  });

  factory ILink.fromJson(Map<String, dynamic> json) => _$ILinkFromJson(json);
}

// ignore_for_file: constant_identifier_names
enum IsarType {
  Bool(true, 80),
  Int(true, 80),
  Float(true, 80),
  Long(true, 80),
  Double(true, 80),
  String(true, 200),
  Bytes(false, 200),
  IntList(false, 200),
  FloatList(false, 200),
  LongList(false, 200),
  DoubleList(false, 200),
  StringList(false, 200);

  final bool sortable;
  final double width;

  const IsarType(this.sortable, this.width);
}
