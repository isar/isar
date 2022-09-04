import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:pub_app/asset_loader.dart';
import 'package:pub_app/models/asset.dart';
import 'package:pub_app/models/package.dart';
import 'package:pub_app/repository.dart';

class PackageManager {
  const PackageManager(this.isar, this.repository);

  final Isar isar;
  final Repository repository;

  Stream<Package> watchPackage(String name, {String? version}) async* {
    final query = isar.packages
        .where()
        .nameEqualToAnyVersion(name)
        .filter()
        .optional(version == null, (q) => q.isLatestEqualTo(true))
        .optional(version != null, (q) => q.versionEqualTo(version!))
        .build();

    await for (final results in query.watch(fireImmediately: true)) {
      if (results.isNotEmpty) {
        yield results.first;
      }
    }
  }

  Stream<List<Package>> watchPackageVersions(String name) async* {
    final query = isar.packages
        .where()
        .nameEqualToAnyVersion(name)
        .sortByPublishedDesc()
        .build();

    await for (final results in query.watch(fireImmediately: true)) {
      if (results.isNotEmpty) {
        yield results;
      }
    }
  }

  Stream<String> watchLatestVersion(String name) async* {
    final query = isar.packages
        .where()
        .nameEqualToAnyVersion(name)
        .filter()
        .isLatestEqualTo(true)
        .versionProperty()
        .build();

    await for (final results in query.watch(fireImmediately: true)) {
      if (results.isNotEmpty) {
        yield results.first;
      }
    }
  }

  Stream<String?> watchPreReleaseVersion(String name) async* {
    await for (final _ in isar.packages.watchLazy(fireImmediately: true)) {
      final latestDate = await isar.packages
          .where()
          .nameEqualToAnyVersion(name)
          .filter()
          .isLatestEqualTo(true)
          .publishedProperty()
          .findFirst();

      if (latestDate != null) {
        yield await isar.packages
            .where()
            .nameEqualToAnyVersion(name)
            .filter()
            .publishedGreaterThan(latestDate)
            .sortByPublishedDesc()
            .versionProperty()
            .findFirst();
      }
    }
  }

  Future<void> loadPackage(
    String name, {
    bool loadMetrics = false,
    String? version,
  }) async {
    final newPackageVersions = await repository.getPackageVersions(name);
    final latestExistingDate = await isar.packages
        .where()
        .nameEqualToAnyVersion(name)
        .publishedProperty()
        .max();
    final versionsToAdd = newPackageVersions
        .where(
          (e) =>
              e.published.millisecondsSinceEpoch >
              (latestExistingDate?.millisecondsSinceEpoch ?? 0),
        )
        .toList();

    final currentLatest = await isar.packages
        .where()
        .nameEqualToAnyVersion(name)
        .filter()
        .isLatestEqualTo(true)
        .findFirst();
    final newLatestVersion =
        newPackageVersions.firstWhere((e) => e.isLatest).version;
    if (currentLatest != null && currentLatest.version != newLatestVersion) {
      versionsToAdd.add(currentLatest.copyWith(isLatest: false));
    }

    if (loadMetrics) {
      version ??= newLatestVersion;
      final metrics = await repository.getPackageMetrics(name, version);
      final package = newPackageVersions
          .firstWhere((e) => e.version == version)
          .copyWithMetrics(metrics);
      versionsToAdd.add(package);
    }
    await isar.writeTxn(() async {
      await isar.packages.putAll(versionsToAdd);
    });
  }

  Stream<Map<AssetKind, String>> watchPackageAssets(
    String name,
    String version,
  ) async* {
    final query =
        isar.assets.where().packageVersionEqualToAnyKind(name, version).build();

    final existing = await query.findAll();
    if (existing.isNotEmpty) {
      yield {
        for (final asset in existing) asset.kind: asset.content,
      };
    } else {
      final existingAnyVersion = await isar.assets
          .where()
          .packageEqualToAnyVersionKind(name)
          .sortByVersionDesc()
          .findAll();
      if (existingAnyVersion.isNotEmpty) {
        final assets = <AssetKind, String>{};
        for (final asset in existingAnyVersion) {
          if (!assets.containsKey(asset.kind)) {
            assets[asset.kind] = asset.content;
          }
        }
        yield assets;
      }
    }

    await for (final results in query.watch()) {
      if (results.isNotEmpty) {
        yield {
          for (final asset in results) asset.kind: asset.content,
        };
      }
    }
  }

  Future<void> loadPackageAssets(String name, String version) {
    return compute(loadAssets, PackageAndVersion(name, version));
  }

  Future<List<String>> search(String query, int page, {bool online = true}) {
    if (online) {
      return repository.search(query, page + 1);
    } else {
      return isar.packages
          .filter()
          .nameContains(query, caseSensitive: false)
          .or()
          .descriptionContains(query, caseSensitive: false)
          .sortByLikesDesc()
          .distinctByName()
          .offset(page * 10)
          .limit(10)
          .nameProperty()
          .findAll();
    }
  }

  Future<void> bulkLoad(String query) async {
    var page = 0;
    while (true) {
      final packageNames = await search(query, page);
      if (packageNames.isEmpty) {
        break;
      }
      await Future.wait(
        packageNames.map((e) => loadPackage(e, loadMetrics: true)),
      );
      page++;
    }
  }

  Stream<List<String>> watchFavoriteNames() {
    return isar.packages
        .filter()
        .flutterFavoriteEqualTo(true)
        .distinctByName()
        .nameProperty()
        .watch(fireImmediately: true);
  }
}
