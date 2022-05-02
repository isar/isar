part of isar;

/// Callback for a newly opened Isar instance.
typedef IsarOpenCallback = void Function(Isar);

/// Callback for a release Isar instance.
typedef IsarCloseCallback = void Function(String);

/// An instance of the Isar Database.
abstract class Isar {
  /// Smallest valid id.
  static const minId = isarMinId;

  /// Largest valid id.
  static const maxId = isarMaxId;

  /// The default Isar instance name.
  static const defaultName = 'isar';

  /// Placeholder for an auto-increment id.
  static final autoIncrement = isarAutoIncrementId;

  static final _instances = <String, Isar>{};
  static final _openCallbacks = <IsarOpenCallback>{};
  static final _closeCallbacks = <IsarCloseCallback>{};
  static String? _schema;

  /// Name of the instance.
  final String name;

  late final Map<Type, IsarCollection> _collections;
  late final Map<String, IsarCollection> _collectionsByName;

  var _isOpen = true;

  @protected
  Isar(this.name, String schema) {
    if (_schema != null && _schema != schema) {
      throw 'Cannot open multiple Isar instances with different schema.';
    }
    _schema = schema;
    _instances[name] = this;
    for (var callback in _openCallbacks) {
      callback(this);
    }
  }

  static void _checkOpen(String name, List<CollectionSchema> schemas) {
    if (name.isEmpty || name.startsWith('_')) {
      throw IsarError('Instance names must not be empty or start with "_".');
    }
    if (_instances.containsKey(name)) {
      throw IsarError('Instance has already been opened.');
    }
    if (schemas.isEmpty) {
      throw IsarError('At least one collection needs to be opened.');
    }
    for (var i = 0; i < schemas.length; i++) {
      final schema = schemas[i];
      if (schemas.indexWhere((e) => e.name == schema.name) != i) {
        throw IsarError('Duplicate collection ${schema.name}.');
      }
    }
    schemas.sort((a, b) => a.name.compareTo(b.name));
  }

  /// Open a new Isar instance.
  static Future<Isar> open({
    required List<CollectionSchema> schemas,
    String? directory,
    String name = defaultName,
    bool relaxedDurability = true,
    bool inspector = false,
  }) {
    if (inspector) {
      assert(() {
        _initializeIsarConnect();
        return true;
      }());
    }
    _checkOpen(name, schemas);
    return IsarNative.open(
      schemas: schemas,
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
    );
  }

  /// Open a new Isar instance.
  static Isar openSync({
    required List<CollectionSchema> schemas,
    String? directory,
    String name = defaultName,
    bool relaxedDurability = true,
    bool inspector = false,
  }) {
    if (inspector) {
      assert(() {
        _initializeIsarConnect();
        return true;
      }());
    }
    _checkOpen(name, schemas);
    return IsarNative.openSync(
      schemas: schemas,
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
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
  Future<T> txn<T>(Future<T> Function(Isar isar) callback);

  /// Executes an asynchronous read-write transaction.
  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback,
      {bool silent = false});

  /// Executes a synchronous read-only transaction.
  T txnSync<T>(T Function(Isar isar) callback);

  /// Executes a synchronous read-write transaction.
  T writeTxnSync<T>(T Function(Isar isar) callback, {bool silent = false});

  /// @nodoc
  @protected
  void attachCollections(Map<Type, IsarCollection> collections) {
    _collections = collections;
    _collectionsByName = {
      for (var col in collections.values) col.name: col,
    };
  }

  /// Get a collection by its type.
  ///
  /// You should use the generated extension methods instead.
  IsarCollection<T> getCollection<T>() {
    requireOpen();
    return _collections[T] as IsarCollection<T>;
  }

  /// @nodoc
  @protected
  IsarCollection? getCollectionInternal(String name) {
    return _collectionsByName[name];
  }

  /// Remove all data in this instance and reset the auto increment values.
  Future<void> clear() async {
    for (var col in _collections.values) {
      await col.clear();
    }
  }

  /// Remove all data in this instance and reset the auto increment values.
  void clearSync() {
    for (var col in _collections.values) {
      col.clearSync();
    }
  }

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
      if (_instances.isEmpty) {
        _schema = null;
      }
    }
    for (var callback in _closeCallbacks) {
      callback(name);
    }
    return Future.value(false);
  }

  /// Returns the schema of this Instance. You should avoid usint the schema directly.
  @protected
  static String? get schema => _schema;

  /// A list of all Isar instances opened in the current isolate.
  static Set<String> get instanceNames => _instances.keys.toSet();

  /// Returns an Isar instance opened in the current isolate by its name. If
  /// no name is provided, the default instane is returned.
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

  /// Initialize Isar Code. You need to provide binaries for every platform
  /// your app will run on.
  static initializeLibraries({Map<IsarAbi, String> libraries = const {}}) =>
      IsarNative.initializeLibraries(libraries: libraries);

  /// Split a String into words according to Unicode Annex #29. Only words
  /// containing at least one alphanumeric character will be included.
  static List<String> splitWords(String input) => IsarNative.splitWords(input);
}
