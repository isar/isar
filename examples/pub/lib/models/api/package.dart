import 'package:json_annotation/json_annotation.dart';
import 'package:pubspec/pubspec.dart';

part 'package.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ApiPackage {
  ApiPackage({
    required this.name,
    required this.latest,
    this.versions = const [],
  });

  factory ApiPackage.fromJson(Map<String, dynamic> json) =>
      _$ApiPackageFromJson(json);

  final String name;

  final ApiPackageVersion latest;

  final List<ApiPackageVersion> versions;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ApiPackageVersion {
  ApiPackageVersion({
    required this.version,
    required this.pubspec,
    required this.published,
  });

  factory ApiPackageVersion.fromJson(Map<String, dynamic> json) =>
      _$ApiPackageVersionFromJson(json);

  final String version;

  final PubSpec pubspec;

  final DateTime published;
}
