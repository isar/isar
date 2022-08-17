import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'media.g.dart';

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Media {
  Media();

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);

  String? displayUrl;

  String? expandedUrl;

  String? idStr;

  List<int>? indices;

  String? mediaUrl;

  String? mediaUrlHttps;

  Sizes? sizes;

  String? sourceStatusIdStr;

  String? type;

  String? url;

  VideoInfo? videoInfo;

  AdditionalMediaInfo? additionalMediaInfo;

  Map<String, dynamic> toJson() => _$MediaToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Sizes {
  Sizes();

  factory Sizes.fromJson(Map<String, dynamic> json) => _$SizesFromJson(json);

  Size? thumb;

  Size? medium;

  Size? small;

  Size? large;

  Map<String, dynamic> toJson() => _$SizesToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Size {
  Size();

  factory Size.fromJson(Map<String, dynamic> json) => _$SizeFromJson(json);

  int? w;

  int? h;

  String? resize;

  Map<String, dynamic> toJson() => _$SizeToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class AdditionalMediaInfo {
  AdditionalMediaInfo();

  factory AdditionalMediaInfo.fromJson(Map<String, dynamic> json) =>
      _$AdditionalMediaInfoFromJson(json);

  String? title;

  String? description;

  bool? embeddable;

  bool? monetizable;

  Map<String, dynamic> toJson() => _$AdditionalMediaInfoToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class VideoInfo {
  VideoInfo();

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);

  List<int>? aspectRatio;

  int? durationMillis;

  List<Variant>? variants;

  Map<String, dynamic> toJson() => _$VideoInfoToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Variant {
  Variant();

  factory Variant.fromJson(Map<String, dynamic> json) =>
      _$VariantFromJson(json);

  int? bitrate;

  String? contentType;

  String? url;

  Map<String, dynamic> toJson() => _$VariantToJson(this);
}
