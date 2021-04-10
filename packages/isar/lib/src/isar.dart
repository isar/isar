part of isar;

typedef IsarOpenCallback = void Function(Isar);
typedef IsarCloseCallback = void Function(String);

abstract class Isar {
  static final _instances = <String, Isar>{};
  static final _openCallbacks = <IsarOpenCallback>{};
  static final _closeCallbacks = <IsarCloseCallback>{};
  static String? _schema;

  final String name;
  late final Map<String, IsarCollection> _collections;

  Isar(this.name, String schema) {
    _schema = schema;
    _instances[name] = this;
    for (var callback in _openCallbacks) {
      callback(this);
    }
  }

  Future<T> txn<T>(Future<T> Function(Isar isar) callback);

  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback,
      {bool silent = false});

  T txnSync<T>(T Function(Isar isar) callback);

  T writeTxnSync<T>(T Function(Isar isar) callback, {bool silent = false});

  @protected
  void attachCollections(Map<String, IsarCollection> collections) {
    _collections = collections;
  }

  IsarCollection<T> getCollection<T>(String name) {
    final collection = _collections[name];
    if (collection is IsarCollection<T>) {
      return collection;
    } else {
      throw 'Unknown collection or invalid type';
    }
  }

  Future close() {
    if (identical(_instances[name], this)) {
      _instances.remove(name);
    }
    for (var callback in _closeCallbacks) {
      callback(name);
    }
    return Future.value();
  }

  static String? get schema => _schema;

  static List<String> get instanceNames => _instances.keys.toList();

  static Isar? getInstance(String name) {
    return _instances[name];
  }

  static void addOpenListener(IsarOpenCallback callback) {
    _openCallbacks.add(callback);
  }

  static void removeOpenListener(IsarOpenCallback callback) {
    _openCallbacks.remove(callback);
  }

  static void addCloseListener(IsarCloseCallback callback) {
    _closeCallbacks.add(callback);
  }

  static void removeCloseListener(IsarCloseCallback callback) {
    _closeCallbacks.remove(callback);
  }

  static Uint8List generateSecureKey() {
    final random = Random.secure();
    final buffer = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      buffer[i] = random.nextInt(0xFF + 1);
    }
    return buffer;
  }
}
