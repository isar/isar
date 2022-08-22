import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

import 'entities.dart';
import 'geo.dart';
import 'media.dart';
import 'user.dart';
import 'util.dart';

part 'tweet.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@collection
class Tweet {
  Tweet();

  factory Tweet.fromJson(Map<String, dynamic> json) => _$TweetFromJson(json);

  Id? isarId;

  @JsonKey(fromJson: convertTwitterDateTime)
  DateTime? createdAt;

  String? idStr;

  String? source;

  bool? truncated;

  String? inReplyToStatusIdStr;

  String? inReplyToUserIdStr;

  String? inReplyToScreenName;

  User? user;

  Coordinates? coordinates;

  Place? place;

  String? quotedStatusIdStr;

  bool? isQuoteStatus;

  int? quoteCount;

  int? replyCount;

  int? retweetCount;

  int? favoriteCount;

  Entities? entities;

  Entities? extendedEntities;

  bool? favorited;

  bool? retweeted;

  bool? possiblySensitive;

  bool? possiblySensitiveAppealable;

  CurrentUserRetweet? currentUserRetweet;

  String? lang;

  QuotedStatusPermalink? quotedStatusPermalink;

  String? fullText;

  List<int>? displayTextRange;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class CurrentUserRetweet {
  CurrentUserRetweet();

  factory CurrentUserRetweet.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserRetweetFromJson(json);

  String? idStr;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class QuotedStatusPermalink {
  QuotedStatusPermalink();

  factory QuotedStatusPermalink.fromJson(Map<String, dynamic> json) =>
      _$QuotedStatusPermalinkFromJson(json);

  String? url;

  String? expanded;

  String? display;
}
