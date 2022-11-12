import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'media.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
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
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class Sizes {
  Sizes();

  factory Sizes.fromJson(Map<String, dynamic> json) => _$SizesFromJson(json);

  Size? thumb;

  Size? medium;

  Size? small;

  Size? large;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class Size {
  Size();

  factory Size.fromJson(Map<String, dynamic> json) => _$SizeFromJson(json);

  int? w;

  int? h;

  String? resize;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class AdditionalMediaInfo {
  AdditionalMediaInfo();

  factory AdditionalMediaInfo.fromJson(Map<String, dynamic> json) =>
      _$AdditionalMediaInfoFromJson(json);

  String? title;

  String? description;

  bool? embeddable;

  bool? monetizable;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class VideoInfo {
  VideoInfo();

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);

  List<int>? aspectRatio;

  int? durationMillis;

  List<Variant>? variants;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class Variant {
  Variant();

  factory Variant.fromJson(Map<String, dynamic> json) =>
      _$VariantFromJson(json);

  int? bitrate;

  String? contentType;

  String? url;
}
