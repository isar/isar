part of isar;

@pragma('vm:isolate-unsendable')
abstract class Isar {
  /// The default Isar instance name.
  static const String defaultName = 'default';

  /// The default max Isar size.
  static const int defaultMaxSizeMiB = 256;

  static const String version = '4.0.0';

  static Isar get({
    required List<IsarCollectionSchema> schemas,
    StorageEngine engine = StorageEngine.isar,
    String name = Isar.defaultName,
  }) {
    return _IsarImpl.getByName(
      name: name,
      schemas: schemas,
      engine: engine,
    );
  }

  static Isar open({
    required List<IsarCollectionSchema> schemas,
    required String directory,
    String name = Isar.defaultName,
    StorageEngine engine = StorageEngine.isar,
    int maxSizeMiB = Isar.defaultMaxSizeMiB,
    CompactCondition? compactOnLaunch,
    bool inspector = true,
  }) {
    return _IsarImpl.open(
      schemas: schemas,
      directory: directory,
      name: name,
      engine: engine,
      maxSizeMiB: maxSizeMiB,
      compactOnLaunch: compactOnLaunch,
    );
  }

  /// Name of the instance.
  String get name;

  /// The directory containing the database file or `null` on the web.
  ///
  /// The full path of the database file is `directory/name.isar` and the lock
  /// file `directory/name.isar.lock`.
  String get directory;

  bool get isOpen;

  IsarCollection<ID, OBJ> collection<ID, OBJ>();

  T txn<T>(T Function(Isar isar) callback);

  T writeTxn<T>(T Function(Isar isar) callback);

  Future<T> txnAsync<T>(T Function(Isar isar) callback);

  Future<T> writeTxnAsync<T>(T Function(Isar isar) callback);

  int getSize({bool includeIndexes = false});

  void copyToFile(String path);

  void clear();

  bool close({bool deleteFromDisk = false});

  /// Initialize Isar Core manually. You need to provide Isar Core libraries
  /// for every platform your app will run on.
  ///
  /// Only use this method for non-Flutter code or unit tests.
  static void initializeIsarCore({Map<Abi, String> libraries = const {}}) {
    IsarCore._initialize(libraries: libraries);
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

enum StorageEngine {
  isar,
  sqlite,
  sqlcipher,
}
