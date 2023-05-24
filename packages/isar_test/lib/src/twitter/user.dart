import 'package:isar/isar.dart';
import 'package:isar_test/src/twitter/entities.dart';
import 'package:isar_test/src/twitter/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class User {
  User();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  String? idStr;

  String? name;

  String? screenName;

  String? location;

  String? url;

  UserEntities? entities;

  String? description;

  bool? protected;

  bool? verified;

  int? followersCount;

  int? friendsCount;

  int? listedCount;

  int? favoritesCount;

  int? statusesCount;

  @JsonKey(fromJson: convertTwitterDateTime)
  DateTime? createdAt;

  String? profileBannerUrl;

  String? profileImageUrlHttps;

  bool? defaultProfile;

  bool? defaultProfileImage;

  List<String>? withheldInCountries;

  String? withheldScope;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class UserEntities {
  UserEntities();

  factory UserEntities.fromJson(Map<String, dynamic> json) =>
      _$UserEntitiesFromJson(json);

  UserEntityUrl? url;

  UserEntityUrl? description;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@embedded
class UserEntityUrl {
  UserEntityUrl();

  factory UserEntityUrl.fromJson(Map<String, dynamic> json) =>
      _$UserEntityUrlFromJson(json);

  List<Url>? urls;
}
