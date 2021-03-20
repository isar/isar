part of isar;

abstract class Isar {
  final String name;

  const Isar(this.name);

  Future<T> txn<T>(Future<T> Function(Isar isar) callback);

  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback,
      {bool silent = false});

  T txnSync<T>(T Function(Isar isar) callback);

  T writeTxnSync<T>(T Function(Isar isar) callback, {bool silent = false});

  Future close();

  static Uint8List generateSecureKey() {
    final random = Random.secure();
    final buffer = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      buffer[i] = random.nextInt(0xFF + 1);
    }
    return buffer;
  }
}
