part of isar;

/// Callback for a newly opened Isar instance.
typedef IsarOpenCallback = void Function(Isar);

/// Callback for a release Isar instance.
typedef IsarCloseCallback = void Function(String);

/// An instance of the Isar Database.
abstract class Isar {
  static final _instances = <String, Isar>{};
  static final _openCallbacks = <IsarOpenCallback>{};
  static final _closeCallbacks = <IsarCloseCallback>{};
  static String? _schema;

  final String name;
  late final Map<String, IsarCollection> _collections;

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

  /// Executes an asynchronous read-only transaction.
  Future<T> txn<T>(Future<T> Function(Isar isar) callback);

  /// Executes an asynchronous read-write transaction.
  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback,
      {bool silent = false});

  /// Executes a synchronous read-only transaction.
  T txnSync<T>(T Function(Isar isar) callback);

  /// Executes a synchronous read-write transaction.
  T writeTxnSync<T>(T Function(Isar isar) callback, {bool silent = false});

  @protected
  void attachCollections(Map<String, IsarCollection> collections) {
    _collections = collections;
  }

  /// Get a collection by its name.
  ///
  /// You should use the generated extension methods instead.
  IsarCollection<T> getCollection<T>(String name) {
    final collection = _collections[name];
    if (collection is IsarCollection<T>) {
      return collection;
    } else {
      throw 'Unknown collection or invalid type';
    }
  }

  /// Releases an Isar instance.
  ///
  /// If this is the only isolate that holds a reference to this instance, the
  /// Isar instance will be closed.
  Future close() {
    if (identical(_instances[name], this)) {
      _instances.remove(name);
    }
    for (var callback in _closeCallbacks) {
      callback(name);
    }
    return Future.value();
  }

  @protected
  static String? get schema => _schema;

  /// A list of all opened Isar instances
  static List<String> get instanceNames => _instances.keys.toList();

  /// Returns an opened Isar instance by its name or `null`.
  static Isar? getInstance(String name) {
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

  /// Registers a listener that is called whenever an Isar instance is released.
  static void addCloseListener(IsarCloseCallback callback) {
    _closeCallbacks.add(callback);
  }

  /// Removes a previously registered `IsarOpenCallback`.
  static void removeCloseListener(IsarCloseCallback callback) {
    _closeCallbacks.remove(callback);
  }

  /// Generates a secure 32 byte (256bit) key.
  static Uint8List generateSecureKey() {
    final random = Random.secure();
    final buffer = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      buffer[i] = random.nextInt(0xFF + 1);
    }
    return buffer;
  }
}
