part of isar;

/// Callback for a newly opened Isar instance.
typedef IsarOpenCallback = void Function(Isar isar);

/// Callback for a release Isar instance.
typedef IsarCloseCallback = void Function(String isarName);

/// An instance of the Isar Database.
abstract class Isar {
  /// @nodoc
  @protected
  Isar(this.name) {
    _instances[name] = this;
    for (final callback in _openCallbacks) {
      callback(this);
    }
  }

  /// The version of the Isar library.
  static const version = '3.1.0+1';

  /// Smallest valid id.
  static const Id minId = isarMinId;

  /// Largest valid id.
  static const Id maxId = isarMaxId;

  /// The default Isar instance name.
  static const String defaultName = 'default';

  /// The default max Isar size.
  static const int defaultMaxSizeMiB = 1024;

  /// Placeholder for an auto-increment id.
  static const Id autoIncrement = isarAutoIncrementId;

  static final Map<String, Isar> _instances = <String, Isar>{};
  static final Set<IsarOpenCallback> _openCallbacks = <IsarOpenCallback>{};
  static final Set<IsarCloseCallback> _closeCallbacks = <IsarCloseCallback>{};

  /// Name of the instance.
  final String name;

  /// The directory containing the database file or `null` on the web.
  String? get directory;

  /// The full path of the database file is `directory/name.isar` and the lock
  /// file `directory/name.isar.lock`.
  String? get path => directory != null ? '$directory/$name.isar' : null;

  late final Map<Type, IsarCollection<dynamic>> _collections;
  late final Map<String, IsarCollection<dynamic>> _collectionsByName;

  bool _isOpen = true;

  static void _checkOpen(String name, List<CollectionSchema<dynamic>> schemas) {
    if (name.isEmpty || name.startsWith('_')) {
      throw IsarError('Instance names must not be empty or start with "_".');
    }
    if (_instances.containsKey(name)) {
      throw IsarError('Instance has already been opened.');
    }
    if (schemas.isEmpty) {
      throw IsarError('At least one collection needs to be opened.');
    }

    final schemaNames = <String>{};
    for (final schema in schemas) {
      if (!schemaNames.add(schema.name)) {
        throw IsarError('Duplicate collection ${schema.name}.');
      }
    }
    for (final schema in schemas) {
      final dependencies = schema.links.values.map((e) => e.target);
      for (final dependency in dependencies) {
        if (!schemaNames.contains(dependency)) {
          throw IsarError(
            "Collection ${schema.name} depends on $dependency but it's schema "
            'was not provided.',
          );
        }
      }
    }
  }

  /// Open a new Isar instance.
  static Future<Isar> open(
    List<CollectionSchema<dynamic>> schemas, {
    required String directory,
    String name = defaultName,
    int maxSizeMiB = Isar.defaultMaxSizeMiB,
    bool relaxedDurability = true,
    CompactCondition? compactOnLaunch,
    bool inspector = true,
  }) {
    _checkOpen(name, schemas);

    /// Tree shake the inspector for profile and release builds.
    assert(() {
      if (!_kIsWeb && inspector) {
        _IsarConnect.initialize(schemas);
      }
      return true;
    }());

    return openIsar(
      schemas: schemas,
      directory: directory,
      name: name,
      maxSizeMiB: maxSizeMiB,
      relaxedDurability: relaxedDurability,
      compactOnLaunch: compactOnLaunch,
    );
  }

  /// Open a new Isar instance.
  static Isar openSync(
    List<CollectionSchema<dynamic>> schemas, {
    required String directory,
    String name = defaultName,
    int maxSizeMiB = Isar.defaultMaxSizeMiB,
    bool relaxedDurability = true,
    CompactCondition? compactOnLaunch,
    bool inspector = true,
  }) {
    _checkOpen(name, schemas);

    /// Tree shake the inspector for profile and release builds.
    assert(() {
      if (!_kIsWeb && inspector) {
        _IsarConnect.initialize(schemas);
      }
      return true;
    }());

    return openIsarSync(
      schemas: schemas,
      directory: directory,
      name: name,
      maxSizeMiB: maxSizeMiB,
      relaxedDurability: relaxedDurability,
      compactOnLaunch: compactOnLaunch,
    );
  }

  /// Is the instance open?
  bool get isOpen => _isOpen;

  /// @nodoc
  @protected
  void requireOpen() {
    if (!isOpen) {
      throw IsarError('Isar instance has already been closed');
    }
  }

  /// Executes an asynchronous read-only transaction.
  Future<T> txn<T>(Future<T> Function() callback);

  /// Executes an asynchronous read-write transaction.
  ///
  /// If [silent] is `true`, watchers are not notified about changes in this
  /// transaction.
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false});

  /// Executes a synchronous read-only transaction.
  T txnSync<T>(T Function() callback);

  /// Executes a synchronous read-write transaction.
  ///
  /// If [silent] is `true`, watchers are not notified about changes in this
  /// transaction.
  T writeTxnSync<T>(T Function() callback, {bool silent = false});

  /// @nodoc
  @protected
  void attachCollections(Map<Type, IsarCollection<dynamic>> collections) {
    _collections = collections;
    _collectionsByName = {
      for (IsarCollection<dynamic> col in collections.values) col.name: col,
    };
  }

  /// Get a collection by its type.
  ///
  /// You should use the generated extension methods instead.
  IsarCollection<T> collection<T>() {
    requireOpen();
    final collection = _collections[T];
    if (collection == null) {
      throw IsarError('Missing ${T.runtimeType}Schema in Isar.open');
    }
    return collection as IsarCollection<T>;
  }

  /// @nodoc
  @protected
  IsarCollection<dynamic>? getCollectionByNameInternal(String name) {
    return _collectionsByName[name];
  }

  /// Remove all data in this instance and reset the auto increment values.
  Future<void> clear() async {
    for (final col in _collections.values) {
      await col.clear();
    }
  }

  /// Remove all data in this instance and reset the auto increment values.
  void clearSync() {
    for (final col in _collections.values) {
      col.clearSync();
    }
  }

  /// Returns the size of all the collections in bytes. Not supported on web.
  ///
  /// This method is extremely fast and independent of the number of objects in
  /// the instance.
  Future<int> getSize({bool includeIndexes = false, bool includeLinks = false});

  /// Returns the size of all collections in bytes. Not supported on web.
  ///
  /// This method is extremely fast and independent of the number of objects in
  /// the instance.
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false});

  /// Copy a compacted version of the database to the specified file.
  ///
  /// If you want to backup your database, you should always use a compacted
  /// version. Compacted does not mean compressed.
  ///
  /// Do not run this method while other transactions are active to avoid
  /// unnecessary growth of the database.
  Future<void> copyToFile(String targetPath);

  /// Releases an Isar instance.
  ///
  /// If this is the only isolate that holds a reference to this instance, the
  /// Isar instance will be closed. [deleteFromDisk] additionally removes all
  /// database files if enabled.
  ///
  /// Returns whether the instance was actually closed.
  Future<bool> close({bool deleteFromDisk = false}) {
    requireOpen();
    _isOpen = false;
    if (identical(_instances[name], this)) {
      _instances.remove(name);
    }
    for (final callback in _closeCallbacks) {
      callback(name);
    }
    return Future.value(false);
  }

  /// Verifies the integrity of the database file.
  ///
  /// Do not use this method in production apps.
  @visibleForTesting
  @experimental
  Future<void> verify();

  /// A list of all Isar instances opened in the current isolate.
  static Set<String> get instanceNames => _instances.keys.toSet();

  /// Returns an Isar instance opened in the current isolate by its name. If
  /// no name is provided, the default instance is returned.
  static Isar? getInstance([String name = defaultName]) {
    return _instances[name];
  }

  /// Registers a listener that is called whenever an Isar instance is opened.
  static void addOpenListener(IsarOpenCallback callback) {
    _openCallbacks.add(callback);
  }

  /// Removes a previously registered `IsarOpenCallback`.
  static void removeOpenListener(IsarOpenCallback callback) {
    _openCallbacks.remove(callback);
  }

  /// Registers a listener that is called whenever an Isar instance is
  /// released.
  static void addCloseListener(IsarCloseCallback callback) {
    _closeCallbacks.add(callback);
  }

  /// Removes a previously registered `IsarOpenCallback`.
  static void removeCloseListener(IsarCloseCallback callback) {
    _closeCallbacks.remove(callback);
  }

  /// Initialize Isar Core manually. You need to provide Isar Core libraries
  /// for every platform your app will run on.
  ///
  /// If [download] is `true`, Isar will attempt to download the correct
  /// library and place it in the specified path or the script directory.
  ///
  /// Be careful if multiple unit tests try to download the library at the
  /// same time. Always use `flutter test -j 1` when you rely on auto
  /// downloading to ensure that only one test is running at a time.
  ///
  /// Only use this method for non-Flutter code or unit tests.
  static Future<void> initializeIsarCore({
    Map<IsarAbi, String> libraries = const {},
    bool download = false,
  }) async {
    await initializeCoreBinary(
      libraries: libraries,
      download: download,
    );
  }

  /// Split a String into words according to Unicode Annex #29. Only words
  /// containing at least one alphanumeric character will be included.
  static List<String> splitWords(String input) => isarSplitWords(input);
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
