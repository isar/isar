import 'package:freezed_annotation/freezed_annotation.dart';

part 'schema.freezed.dart';
part 'schema.g.dart';

@freezed
class Collection with _$Collection {
  const factory Collection(
    String name,
    List<Property> properties,
    List<Link> links,
  ) = _Collection;

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);
}

@freezed
class Property with _$Property {
  const factory Property(
    String name,
    String type,
  ) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
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
