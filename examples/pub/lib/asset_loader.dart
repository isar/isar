import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:pub_app/models/asset.dart';
import 'package:pub_app/models/package.dart';
import 'package:pub_app/repository.dart';
import 'package:tar/tar.dart';

class PackageAndVersion {
  PackageAndVersion(this.package, this.version);

  final String package;
  final String version;
}

Future<void> loadAssets(PackageAndVersion p) async {
  final isar = Isar.get(schemas: [PackageSchema, AssetSchema]);

  Asset? readme;
  Asset? changelog;

  final targz = await Repository(Dio()).downloadPackage(p.package, p.version);
  final tar = gzip.decode(targz);

  final reader = TarReader(Stream.value(tar));
  while (await reader.moveNext()) {
    final entry = reader.current;

    if (entry.type == TypeFlag.reg) {
      if (readme == null && entry.name.toLowerCase() == 'readme.md') {
        final content = await entry.contents.transform(utf8.decoder).join();
        readme = Asset(
          package: p.package,
          version: p.version,
          kind: AssetKind.readme,
          content: content,
        );
      } else if (changelog == null &&
          entry.name.toLowerCase() == 'changelog.md') {
        final content = await entry.contents.transform(utf8.decoder).join();
        changelog = Asset(
          package: p.package,
          version: p.version,
          kind: AssetKind.changelog,
          content: content,
        );
      }
    }

    if (readme != null && changelog != null) {
      break;
    }
  }

  if (readme != null || changelog != null) {
    isar.write((isar) {
      isar.assets.putAll([
        if (readme != null) readme,
        if (changelog != null) changelog,
      ]);
    });
  }
}
