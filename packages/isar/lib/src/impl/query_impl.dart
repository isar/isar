part of isar;

class _QueryImpl<T> extends Query<T> {
  _QueryImpl({
    required int instanceId,
    required int ptrAddress,
    required Deserialize<T> deserialize,
  })  : _instanceId = instanceId,
        _ptrAddress = ptrAddress,
        _deserialize = deserialize;

  final int _instanceId;
  final Deserialize<T> _deserialize;
  int _ptrAddress;

  Pointer<CIsarQuery> get _ptr {
    final ptr = Pointer<CIsarQuery>.fromAddress(_ptrAddress);
    if (ptr.isNull) {
      throw IsarError('Query was closed already.');
    }
    return ptr;
  }

  @override
  List<T> findAll({int? offset, int? limit}) {
    final isar = _IsarImpl.getInstance(_instanceId);
    return isar.getTxn((isarPtr, txnPtr) {
      final cursorPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarCursor>>();
      isar_query_cursor(
        isarPtr,
        txnPtr,
        _ptr,
        cursorPtrPtr,
        offset ?? 0,
        limit ?? 999999999,
      ).checkNoError();
      final cursorPtr = cursorPtrPtr.value;

      Pointer<CIsarReader> readerPtr = nullptr;
      final values = <T>[];
      while (true) {
        readerPtr = isar_cursor_next(cursorPtr, readerPtr);
        if (!readerPtr.isNull) {
          values.add(_deserialize(readerPtr));
        } else {
          break;
        }
      }

      isar_free_reader(readerPtr);
      isar_free_cursor(cursorPtr);
      return values;
    });
  }

  @override
  int deleteAll({int? offset, int? limit}) {
    // TODO: implement deleteAll
    throw UnimplementedError();
  }

  @override
  int count() {
    // TODO: implement count
    throw UnimplementedError();
  }

  R? aggregate<R>(AggregationOp op) {}

  @override
  void close() {
    isar_free_query(_ptr);
    _ptrAddress = 0;
  }
}
