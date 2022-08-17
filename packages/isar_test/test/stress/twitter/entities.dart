import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

import 'media.dart';
import 'util.dart';

part 'entities.g.dart';

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Entities {
  Entities();

  factory Entities.fromJson(Map<String, dynamic> json) =>
      _$EntitiesFromJson(json);

  List<Hashtag>? hashtags;

  List<Media>? media;

  List<Url>? urls;

  List<UserMention>? userMentions;

  List<Symbol>? symbols;

  List<Poll>? polls;

  Map<String, dynamic> toJson() => _$EntitiesToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Hashtag {
  Hashtag();

  factory Hashtag.fromJson(Map<String, dynamic> json) =>
      _$HashtagFromJson(json);

  List<int>? indices;

  String? text;

  Map<String, dynamic> toJson() => _$HashtagToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Poll {
  Poll();

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);

  List<Option>? options;

  @JsonKey(fromJson: convertTwitterDateTime)
  DateTime? endDatetime;

  String? durationMinutes;

  Map<String, dynamic> toJson() => _$PollToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Option {
  Option();

  factory Option.fromJson(Map<String, dynamic> json) => _$OptionFromJson(json);

  int? position;

  String? text;

  Map<String, dynamic> toJson() => _$OptionToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Symbol {
  Symbol();

  factory Symbol.fromJson(Map<String, dynamic> json) => _$SymbolFromJson(json);

  List<int>? indices;

  String? text;

  Map<String, dynamic> toJson() => _$SymbolToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class Url {
  Url();

  factory Url.fromJson(Map<String, dynamic> json) => _$UrlFromJson(json);

  String? displayUrl;

  String? expandedUrl;

  List<int>? indices;

  String? url;

  Map<String, dynamic> toJson() => _$UrlToJson(this);
}

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
@embedded
class UserMention {
  UserMention();

  factory UserMention.fromJson(Map<String, dynamic> json) =>
      _$UserMentionFromJson(json);

  String? idStr;

  List<int>? indices;

  String? name;

  String? screenName;

  Map<String, dynamic> toJson() => _$UserMentionToJson(this);
}
