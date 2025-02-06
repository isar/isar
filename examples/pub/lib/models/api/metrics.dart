import 'package:json_annotation/json_annotation.dart';

part 'metrics.g.dart';

@JsonSerializable(createToJson: false)
class ApiPackageMetrics {
  ApiPackageMetrics({
    required this.grantedPoints,
    required this.maxPoints,
    required this.likeCount,
    required this.downloadCount30Days,
    required this.tags,
  });

  factory ApiPackageMetrics.fromJson(Map<String, Object?> json) =>
      _$ApiPackageMetricsFromJson(json);

  final int grantedPoints;

  final int maxPoints;

  final int likeCount;

  final int downloadCount30Days;

  final List<String> tags;
}
