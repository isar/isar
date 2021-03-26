import 'package:freezed_annotation/freezed_annotation.dart';

part 'schema.freezed.dart';
part 'schema.g.dart';

@freezed
class Collection with _$Collection {
  const factory Collection(
    String name,
    String idProperty,
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
      bool unique, bool replace, List<IndexProperty> properties) = _Index;

  factory Index.fromJson(Map<String, dynamic> json) => _$IndexFromJson(json);
}

@freezed
class IndexProperty with _$IndexProperty {
  const factory IndexProperty(
    String name,
    int indexType,
    bool caseSensitive,
  ) = _IndexProperty;

  factory IndexProperty.fromJson(Map<String, dynamic> json) =>
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
  Bool,
  Int,
  Float,
  Long,
  Double,
  String,
  Bytes,
  IntList,
  FloatList,
  LongList,
  DoubleList,
  StringList,
}
