part of isar;

class _RawCursor<T> {
  factory _RawCursor({
    required Pointer<CIsarInstance> isarPtr,
    required Pointer<CIsarTxn> txnPtr,
    required Pointer<CIsarQuery> queryPtr,
    required Deserialize<T> deserialize,
    required int offset,
    required int limit,
  }) {
    final cursorPtr = IsarCore.ptrPtr.cast<Pointer<CIsarCursor>>();
    IsarCore.isar_query_cursor(
      isarPtr,
      txnPtr,
      queryPtr,
      cursorPtr,
      offset,
      limit,
    ).checkNoError();
    return _RawCursor._(cursorPtr.value, deserialize);
  }

  _RawCursor._(this._ptr, this._deserialize);

  final Pointer<CIsarCursor> _ptr;
  final Deserialize<T> _deserialize;
  Pointer<CIsarReader> _readerPtr = nullptr;

  T? _next() {
    _readerPtr = IsarCore.isar_cursor_next(_ptr, _readerPtr);
    if (_readerPtr != nullptr) {
      return _deserialize(_readerPtr);
    } else {
      return null;
    }
  }

  void _free() {
    IsarCore.isar_cursor_free(_ptr, _readerPtr);
  }

  T? findFirst() {
    final object = _next();
    _free();
    return object;
  }

  List<T> findAll() {
    final values = <T>[];
    while (true) {
      final value = _next();
      if (value != null) {
        values.add(value);
      } else {
        break;
      }
    }

    _free();
    return values;
  }
}
