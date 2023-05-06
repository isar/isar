part of isar;

abstract class Isar {
  factory Isar.get({
    required List<CollectionSchema> schemas,
    String name = Isar.defaultName,
  }) {
    Isar.initializeIsarCore();
    return _IsarImpl.get(
      converters: schemas.map((e) => e.converter).toList(),
      name: name,
    );
  }

  factory Isar.open({
    required List<CollectionSchema> schemas,
    required String directory,
    String name = Isar.defaultName,
    int maxSizeMiB = Isar.defaultMaxSizeMiB,
    bool relaxedDurability = true,
    CompactCondition? compactOnLaunch,
    bool inspector = true,
  }) {
    Isar.initializeIsarCore();
    return _IsarImpl.open(
      schemas: schemas,
      directory: directory,
      name: name,
      maxSizeMiB: maxSizeMiB,
      relaxedDurability: relaxedDurability,
      compactOnLaunch: compactOnLaunch,
      inspector: inspector,
    );
  }

  /// The default Isar instance name.
  static const String defaultName = 'default';

  /// The default max Isar size.
  static const int defaultMaxSizeMiB = 1024;

  static const String version = '4.0.0';

  IsarCollection<ID, OBJ> collection<ID, OBJ>();

  T txn<T>(T Function(Isar isar) callback);

  T writeTxn<T>(T Function(Isar isar) callback);

  void clear();

  /// Initialize Isar Core manually. You need to provide Isar Core libraries
  /// for every platform your app will run on.
  ///
  /// Only use this method for non-Flutter code or unit tests.
  static void initializeIsarCore({Map<Abi, String> libraries = const {}}) {
    _initializeIsarCore(libraries: libraries);
  }

  /// FNV-1a 64bit hash algorithm optimized for Dart Strings
  static int fastHash(String string) {
    var hash = 0xcbf29ce484222325;

    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }

    return hash;
  }
}

/// Isar databases can contain unused space that will be reused for later
/// operations. You can specify conditions to trigger manual compaction where
/// the entire database is copied and unused space freed.
///
/// This operation can only be performed while a database is being opened and
/// should only be used if absolutely necessary.
class CompactCondition {
  /// Compaction will happen if all of the specified conditions are true.
  const CompactCondition({
    this.minFileSize,
    this.minBytes,
    this.minRatio,
  }) : assert(
          minFileSize != null || minBytes != null || minRatio != null,
          'At least one condition needs to be specified.',
        );

  /// The minimum size in bytes of the database file to trigger compaction. It
  /// is highly  discouraged to trigger compaction solely on this condition.
  final int? minFileSize;

  /// The minimum number of bytes that can be freed with compaction.
  final int? minBytes;

  /// The minimum compaction ration. For example `2.0` would trigger compaction
  /// as soon as the file size can be halved.
  final double? minRatio;
}
