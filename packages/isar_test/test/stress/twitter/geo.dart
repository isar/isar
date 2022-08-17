import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'geo.g.dart';

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Place {
  Place();

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);

  String? id;

  String? url;

  PlaceType? placeType;

  String? name;

  String? fullName;

  String? countryCode;

  String? country;

  Map<String, dynamic> toJson() => _$PlaceToJson(this);
}

enum PlaceType with IsarEnum<String> {
  admin,
  country,
  city,
  poi,
  neighborhood;

  @override
  String get value => name;
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Coordinates {
  Coordinates();

  factory Coordinates.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesFromJson(json);

  List<double>? coordinates;

  String? type;

  Map<String, dynamic> toJson() => _$CoordinatesToJson(this);
}
