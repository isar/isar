part of isar;

typedef IsarOpenCallback = void Function(Isar);
typedef IsarCloseCallback = void Function(String);

abstract class Isar {
  static final _openCallbacks = <IsarOpenCallback>{};
  static final _closeCallbacks = <IsarCloseCallback>{};

  final String name;

  Isar(this.name) {
    for (var callback in _openCallbacks) {
      callback(this);
    }
  }

  Future<T> txn<T>(Future<T> Function(Isar isar) callback);

  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback,
      {bool silent = false});

  T txnSync<T>(T Function(Isar isar) callback);

  T writeTxnSync<T>(T Function(Isar isar) callback, {bool silent = false});

  Future close() {
    for (var callback in _closeCallbacks) {
      callback(name);
    }
    return Future.value();
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
