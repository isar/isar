import 'package:json_annotation/json_annotation.dart';

part 'schema.g.dart';

@JsonSerializable()
class Collection {
  final String name;
  final List<Property> properties;
  final List<Link> links;

  const Collection(
    this.name,
    this.properties,
    this.links,
  );

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);
}

@JsonSerializable()
class Property {
  final String name;
  final String type;

  const Property(
    this.name,
    this.type,
  );

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}

@JsonSerializable()
class Link {
  final String name;
  final String target;

  const Link(
    this.name,
    this.target,
  );

  factory Link.fromJson(Map<String, dynamic> json) => _$LinkFromJson(json);
}

enum IsarType {
  bool,
  int,
  float,
  long,
  double,
  string,
  bytes,
  intList,
  floatList,
  longList,
  doubleList,
  stringList,
}
