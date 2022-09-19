import 'package:isar/isar.dart';

part 'asset.g.dart';

@collection
class Asset {
  Asset({
    required this.package,
    required this.version,
    required this.kind,
    required this.content,
  }) : id = Isar.autoIncrement;

  Id id;

  @Index(
    unique: true,
    replace: true,
    composite: [
      CompositeIndex('version'),
      CompositeIndex('kind'),
    ],
  )
  final String package;

  final String version;

  @enumerated
  final AssetKind kind;

  final String content;
}

enum AssetKind { readme, changelog }
