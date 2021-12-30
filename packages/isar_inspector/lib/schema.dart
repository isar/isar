import 'package:freezed_annotation/freezed_annotation.dart';

part 'schema.freezed.dart';
part 'schema.g.dart';

@freezed
class Collection with _$Collection {
  const factory Collection(
    String name,
    List<Property> properties,
    List<Index> indexes,
    List<Link> links,
  ) = _Collection;

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);
}

@freezed
class Property with _$Property {
  const factory Property(
    String name,
    int type,
  ) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}

extension PropertyX on Property {
  String get typeName =>
      ['Bool', 'Int', 'Float', 'Long', 'Double', 'String'][type];
}

@freezed
class Index with _$Index {
  const factory Index(
      bool unique, bool replace, List<ObjectIndexProperty> properties) = _Index;

  factory Index.fromJson(Map<String, dynamic> json) => _$IndexFromJson(json);
}

@freezed
class ObjectIndexProperty with _$ObjectIndexProperty {
  const factory ObjectIndexProperty(
    String name,
    int indexType,
    bool caseSensitive,
  ) = _IndexProperty;

  factory ObjectIndexProperty.fromJson(Map<String, dynamic> json) =>
      _$IndexPropertyFromJson(json);
}

@freezed
class Link with _$Link {
  const factory Link(
    String name,
    String collection,
  ) = _Link;

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
