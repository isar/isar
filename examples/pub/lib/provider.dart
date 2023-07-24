// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_app/models/asset.dart';
import 'package:pub_app/models/package.dart';
import 'package:pub_app/package_manager.dart';
import 'package:pub_app/repository.dart';
import 'package:riverpod/riverpod.dart';

final isarPod = FutureProvider((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(schemas: [PackageSchema, AssetSchema], directory: dir.path);
});

final repositoryPod = Provider((ref) {
  return Repository(Dio());
});

final packageManagerPod = FutureProvider((ref) async {
  final isar = await ref.watch(isarPod.future);
  final repository = ref.watch(repositoryPod);
  return PackageManager(isar, repository);
});

final freshPackagePod =
    StreamProvider.family<Package, PackageNameVersion>((ref, package) async* {
  final manager = await ref.watch(packageManagerPod.future);
  unawaited(
    manager.loadPackage(
      package.name,
      version: package.version,
      loadMetrics: true,
    ),
  );
  yield* manager.watchPackage(package.name, version: package.version);
});

final packagePod =
    StreamProvider.family<Package, PackageNameVersion>((ref, package) async* {
  final manager = await ref.watch(packageManagerPod.future);
  yield* manager.watchPackage(package.name, version: package.version);
});

final packageVersionsPod =
    StreamProvider.family<List<Package>, String>((ref, package) async* {
  final manager = await ref.watch(packageManagerPod.future);
  yield* manager.watchPackageVersions(package);
});

final latestVersionPod =
    StreamProvider.family<String, String>((ref, name) async* {
  final manager = await ref.watch(packageManagerPod.future);
  yield* manager.watchLatestVersion(name);
});

final preReleaseVersionPod =
    StreamProvider.family<String?, String>((ref, name) async* {
  final manager = await ref.watch(packageManagerPod.future);
  yield* manager.watchPreReleaseVersion(name);
});

final assetsPod =
    StreamProvider.family<Map<AssetKind, String>, PackageNameVersion>(
        (ref, package) async* {
  final manager = await ref.watch(packageManagerPod.future);
  unawaited(manager.loadPackageAssets(package.name, package.version!));
  yield* manager.watchPackageAssets(package.name, package.version!);
});

class PackageNameVersion {
  const PackageNameVersion(this.name, [this.version]);

  final String name;
  final String? version;

  @override
  int get hashCode => Object.hash(name, version);

  @override
  bool operator ==(Object other) =>
      other is PackageNameVersion &&
      name == other.name &&
      version == other.version;
}

class QueryPage {
  const QueryPage(this.query, this.page);

  final String query;
  final int page;

  @override
  int get hashCode => Object.hash(query, page);

  @override
  bool operator ==(Object other) =>
      other is QueryPage && query == other.query && page == other.page;
}
