part of isar_native;

const zoneTxn = #zoneTxn;
const zoneTxnWrite = #zoneTxnWrite;
const zoneTxnStream = #zoneTxnStream;

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

  Future<T> _txn<T>(bool write, Future<T> Function(Isar isar) callback) async {
    requireNoTxnActive();

    final portStreamController = StreamController<Null>.broadcast();
    final portStream = portStreamController.stream;

    final port = ReceivePort();
    port.listen(
      (event) {
        if (event == 0) {
          portStreamController.add(null);
        } else {
          portStreamController.addError('err');
        }
      },
      onDone: () {
        portStreamController.close();
      },
    );

    final txnPtrPtr = allocate<Pointer<NativeType>>();
    IC.isar_txn_begin_async(
        isarPtr, txnPtrPtr, write, port.sendPort.nativePort);

    Pointer<NativeType> txnPtr;
    try {
      await portStream.first;
      txnPtr = txnPtrPtr.value;
    } finally {
      free(txnPtrPtr);
    }

    final zone = Zone.current.fork(zoneValues: {
      zoneTxn: txnPtr,
      zoneTxnWrite: write,
      zoneTxnStream: portStream,
    });

    T result;
    try {
      result = await zone.run(() => callback(this));
    } catch (e) {
      IC.isar_txn_abort_async(txnPtr);
      port.close();
      rethrow;
    }

    IC.isar_txn_commit_async(txnPtr);
    await portStream.first;

    port.close();

    return result;
  }

  @override
  Future<T> txn<T>(Future<T> Function(Isar isar) callback) {
    return _txn(false, callback);
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback) {
    return _txn(true, callback);
  }

  Future<T> getTxn<T>(bool write,
      Future<T> Function(Pointer txn, Stream<Null> stream) callback) {
    final currentTxn = Zone.current[zoneTxn];
    if (currentTxn != null) {
      if (write && !Zone.current[zoneTxnWrite]) {
        throw 'Operation cannot be performed within a read transaction.';
      }
      return callback(currentTxn, Zone.current[zoneTxnStream]);
    } else if (!write) {
      return _txn(write, (isar) {
        return callback(Zone.current[zoneTxn], Zone.current[zoneTxnStream]);
      });
    } else {
      throw 'Write operations require an explicit transaction.';
    }
  }

  T _txnSync<T>(bool write, T Function(Isar isar) callback) {
    requireNoTxnActive();

    var txnPtr = IsarCoreUtils.syncTxnPtr;
    nCall(IC.isar_txn_begin(isarPtr, txnPtr, write));
    var txn = txnPtr.value;
    _currentTxnSync = txn;
    _currentTxnSyncWrite = write;

    T result;
    try {
      result = callback(this);
    } catch (e) {
      _currentTxnSync = null;
      IC.isar_txn_abort(txn);
      rethrow;
    }

    _currentTxnSync = null;
    nCall(IC.isar_txn_commit(txn));

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
