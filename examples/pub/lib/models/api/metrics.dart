import 'package:json_annotation/json_annotation.dart';

part 'metrics.g.dart';

@JsonSerializable(createToJson: false)
class ApiPackageMetrics {
  ApiPackageMetrics({
    required this.grantedPoints,
    required this.maxPoints,
    required this.likeCount,
    required this.popularityScore,
    required this.tags,
  });

  factory ApiPackageMetrics.fromJson(Map<String, Object?> json) =>
      _$ApiPackageMetricsFromJson(json);

  final int grantedPoints;

  final int maxPoints;

  final int likeCount;

  final double popularityScore;

  final List<String> tags;
}
