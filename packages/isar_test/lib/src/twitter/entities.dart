import 'package:isar/isar.dart';
import 'package:isar_test/src/twitter/media.dart';
import 'package:isar_test/src/twitter/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'entities.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
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
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class Hashtag {
  Hashtag();

  factory Hashtag.fromJson(Map<String, dynamic> json) =>
      _$HashtagFromJson(json);

  List<int>? indices;

  String? text;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class Poll {
  Poll();

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);

  List<Option>? options;

  @JsonKey(fromJson: convertTwitterDateTime)
  DateTime? endDatetime;

  String? durationMinutes;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class Option {
  Option();

  factory Option.fromJson(Map<String, dynamic> json) => _$OptionFromJson(json);

  int? position;

  String? text;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class Symbol {
  Symbol();

  factory Symbol.fromJson(Map<String, dynamic> json) => _$SymbolFromJson(json);

  List<int>? indices;

  String? text;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class Url {
  Url();

  factory Url.fromJson(Map<String, dynamic> json) => _$UrlFromJson(json);

  String? displayUrl;

  String? expandedUrl;

  List<int>? indices;

  String? url;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class UserMention {
  UserMention();

  factory UserMention.fromJson(Map<String, dynamic> json) =>
      _$UserMentionFromJson(json);

  String? idStr;

  List<int>? indices;

  String? name;

  String? screenName;
}
