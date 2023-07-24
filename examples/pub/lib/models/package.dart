import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:isar/isar.dart';
import 'package:pub_app/models/api/metrics.dart';
import 'package:pub_app/models/api/package.dart';
import 'package:pubspec/pubspec.dart';

part 'package.g.dart';

@CopyWith()
@collection
class Package {
  Package({
    required this.name,
    required this.version,
    required this.isLatest,
    this.homepage,
    this.documentation,
    this.description,
    required this.dependencies,
    required this.devDependencies,
    required this.published,
    this.points,
    this.likes,
    this.popularity,
    this.publisher,
    this.dart,
    this.flutter,
    this.flutterFavorite,
    this.license,
    this.osiLicense,
    this.platforms,
  });

  String get id => '$name$version';

  final String name;

  final String version;

  final bool isLatest;

  final String? description;

  final String? homepage;

  final String? documentation;

  final List<Dependency> dependencies;

  final List<Dependency> devDependencies;

  final DateTime published;

  final short? points;

  final short? likes;

  final float? popularity;

  final String? publisher;

  final bool? dart;

  final bool? flutter;

  final bool? flutterFavorite;

  final String? license;

  final bool? osiLicense;

  final List<SupportedPlatform>? platforms;

  static List<Package> fromApiPackage(ApiPackage package) {
    final latestVersion = package.latest.version;
    final versions = <Package>[];
    for (final p in package.versions) {
      versions.add(
        Package(
          name: package.name,
          version: p.version,
          isLatest: p.version == latestVersion,
          homepage: p.pubspec.homepage,
          documentation: p.pubspec.documentation,
          description: p.pubspec.description,
          dependencies: Dependency.fromDependencies(p.pubspec.dependencies),
          devDependencies:
              Dependency.fromDependencies(p.pubspec.devDependencies),
          published: p.published,
        ),
      );
    }

    return versions;
  }

  Package copyWithMetrics(ApiPackageMetrics metrics) {
    final publishers =
        metrics.tags.where((t) => t.startsWith('publisher:')).toList();
    final publisher =
        publishers.isNotEmpty ? publishers.first.substring(10) : null;
    return copyWith(
      points: metrics.grantedPoints,
      likes: metrics.likeCount,
      popularity: metrics.popularityScore,
      publisher: publisher,
      dart: metrics.tags.contains('sdk:dart'),
      flutter: metrics.tags.contains('sdk:flutter'),
      flutterFavorite: metrics.tags.contains('is:flutter-favorite'),
      license: metrics.tags
          .firstWhere(
            (e) =>
                e.startsWith('license:') &&
                e != 'license:osi-approved' &&
                e != 'license:fsf-libre',
            orElse: () => 'license:unknown',
          )
          .substring(8)
          .toUpperCase(),
      osiLicense: metrics.tags.contains('license:osi-approved'),
      platforms: [
        if (metrics.tags.contains('platform:web')) SupportedPlatform.web,
        if (metrics.tags.contains('platform:android'))
          SupportedPlatform.android,
        if (metrics.tags.contains('platform:ios')) SupportedPlatform.ios,
        if (metrics.tags.contains('platform:linux')) SupportedPlatform.linux,
        if (metrics.tags.contains('platform:macos')) SupportedPlatform.macos,
        if (metrics.tags.contains('platform:windows'))
          SupportedPlatform.windows,
      ],
    );
  }
}

@embedded
class Dependency {
  Dependency({this.name = 'unknown', this.constraint = 'any'});

  final String name;

  final String constraint;

  static List<Dependency> fromDependencies(
    Map<String, DependencyReference> dependenciesMap,
  ) {
    final dependencies = <Dependency>[];
    for (final package in dependenciesMap.keys) {
      final dep = dependenciesMap[package]!;
      final constraint =
          dep is HostedReference ? dep.versionConstraint.toString() : 'unknown';
      dependencies.add(
        Dependency(
          name: package,
          constraint: constraint,
        ),
      );
    }

    return dependencies;
  }
}

enum SupportedPlatform {
  android('Android'),
  ios('iOS'),
  linux('Linux'),
  windows('Windows'),
  macos('macOS'),
  web('Web');

  const SupportedPlatform(this.name);

  final String name;
}
