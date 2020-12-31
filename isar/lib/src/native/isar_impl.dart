part of isar_native;

const zoneTxn = #zoneTxn;
const zoneTxnWrite = #zoneTxnWrite;

class IsarImpl extends Isar {
  final Pointer isarPtr;

  Pointer? _currentTxnSync;
  bool _currentTxnSyncWrite = false;

  IsarImpl(String path, this.isarPtr) : super(path);

  void requireNoTxnActive() {
    if (_currentTxnSync != null || Zone.current[zoneTxn] != null) {
      throw 'Nested transactions are not supported yet.';
    }
  }

  @override
  Future<T> txn<T>(Future<T> Function(Isar isar) callback) async {
    requireNoTxnActive();
    throw '';
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback) async {
    requireNoTxnActive();
    throw '';
  }

  T _txnSync<T>(bool write, T Function(Isar isar) callback) {
    requireNoTxnActive();

    var txnPtr = IsarCoreUtils.syncTxnPtr;
    nativeCall(IsarCore.isar_txn_begin(isarPtr, txnPtr, write));
    var txn = txnPtr.value;
    _currentTxnSync = txn;
    _currentTxnSyncWrite = write;

    T result;
    try {
      result = callback(this);
    } catch (e) {
      _currentTxnSync = null;
      IsarCore.isar_txn_abort(txn);
      rethrow;
    }

    _currentTxnSync = null;
    nativeCall(IsarCore.isar_txn_commit(txn));

    return result;
  }

  @override
  T txnSync<T>(T Function(Isar isar) callback) {
    return _txnSync(false, callback);
  }

  @override
  T writeTxnSync<T>(T Function(Isar isar) callback) {
    return _txnSync(true, callback);
  }

  T getTxnSync<T>(bool write, T Function(Pointer txn) callback) {
    if (_currentTxnSync != null) {
      if (write && !_currentTxnSyncWrite) {
        throw 'Operation cannot be performed within a read transaction.';
      }
      return callback(_currentTxnSync!);
    } else if (!write) {
      return _txnSync(write, (isar) => callback(_currentTxnSync!));
    } else {
      throw 'Write operations require an explicit transaction.';
    }
  }
}
