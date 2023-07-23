part of isar;

class _IsarQueryImpl<T> extends IsarQuery<T> {
  _IsarQueryImpl({
    required int instanceId,
    required int ptrAddress,
    List<int>? properties,
    required Deserialize<T> deserialize,
  })  : _instanceId = instanceId,
        _ptrAddress = ptrAddress,
        _properties = properties,
        _deserialize = deserialize;

  final int _instanceId;
  final List<int>? _properties;
  final Deserialize<T> _deserialize;
  int _ptrAddress;

  Pointer<CIsarQuery> get _ptr {
    final ptr = Pointer<CIsarQuery>.fromAddress(_ptrAddress);
    if (ptr.isNull) {
      throw QueryError('Query has already been closed.');
    }
    return ptr;
  }

  @override
  _IsarImpl get isar => _IsarImpl.instance(_instanceId);

  List<E> _findAll<E>(Deserialize<E> deserialize, {int? offset, int? limit}) {
    return isar.getTxn((isarPtr, txnPtr) {
      final cursorPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarCursor>>();
      isar_query_cursor(
        isarPtr,
        txnPtr,
        _ptr,
        cursorPtrPtr,
        offset ?? -1,
        limit ?? -1,
      ).checkNoError();
      final cursorPtr = cursorPtrPtr.value;

      Pointer<CIsarReader> readerPtr = nullptr;
      final values = <E>[];
      while (true) {
        readerPtr = isar_cursor_next(cursorPtr, readerPtr);
        if (readerPtr.isNull) break;
        values.add(deserialize(readerPtr));
      }

      isar_read_free(readerPtr);
      isar_cursor_free(cursorPtr);
      return values;
    });
  }

  @override
  List<T> findAll({int? offset, int? limit}) {
    return _findAll(_deserialize, offset: offset, limit: limit);
  }

  @override
  int deleteAll({int? offset, int? limit}) {
    return isar.getTxn((isarPtr, txnPtr) {
      isar_query_delete(
        isarPtr,
        txnPtr,
        _ptr,
        offset ?? -1,
        limit ?? -1,
        IsarCore.countPtr,
      ).checkNoError();
      return IsarCore.countPtr.value;
    });
  }

  @override
  List<Map<String, dynamic>> exportJson({int? offset, int? limit}) {
    final bufferPtrPtr = calloc<Pointer<Uint8>>();
    final bufferSizePtr = malloc<Uint32>();

    Map<String, dynamic> deserialize(IsarReader reader) {
      final jsonSize = isar_read_to_json(reader, bufferPtrPtr, bufferSizePtr);
      final bufferPtr = bufferPtrPtr.value;
      if (bufferPtr.isNull) {
        throw QueryError('Failed to export JSON');
      } else {
        final jsonBytes = bufferPtr.asTypedList(jsonSize);
        return jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
      }
    }

    try {
      return _findAll(deserialize, offset: offset, limit: limit);
    } finally {
      isar_buffer_free(bufferPtrPtr.value, bufferSizePtr.value);
      calloc.free(bufferPtrPtr);
      malloc.free(bufferSizePtr);
    }
  }

  @override
  R? aggregate<R>(Aggregation op) {
    final aggregation = switch (op) {
      Aggregation.count => AGGREGATION_COUNT,
      Aggregation.isEmpty => AGGREGATION_IS_EMPTY,
      Aggregation.min => AGGREGATION_MIN,
      Aggregation.max => AGGREGATION_MAX,
      Aggregation.sum => AGGREGATION_SUM,
      Aggregation.average => AGGREGATION_AVERAGE,
    };

    return isar.getTxn((isarPtr, txnPtr) {
      final valuePtr = IsarCore.ptrPtr.cast<Pointer<CIsarValue>>();
      isar_query_aggregate(
        isarPtr,
        txnPtr,
        _ptr,
        aggregation,
        _properties?.firstOrNull ?? 0,
        valuePtr,
      ).checkNoError();

      final value = valuePtr.value;
      if (value.isNull) return null;

      try {
        if (true is R) {
          return isar_value_get_bool(value) as R;
        } else if (0.0 is R) {
          return isar_value_get_real(value) as R;
        } else if (0 is R) {
          return isar_value_get_integer(value) as R;
        } else if (DateTime.now() is R) {
          return DateTime.fromMillisecondsSinceEpoch(
            isar_value_get_integer(value),
            isUtc: true,
          ).toLocal() as R;
        } else if ('' is R) {
          final length = isar_value_get_string(value, IsarCore.stringPtrPtr);
          if (IsarCore.stringPtr.isNull) {
            return null;
          } else {
            return utf8.decode(IsarCore.stringPtr.asTypedList(length)) as R;
          }
        } else {
          throw ArgumentError('Unsupported aggregation type: $R');
        }
      } finally {
        isar_value_free(value);
      }
    });
  }

  @override
  Stream<List<T>> watch({bool fireImmediately = false}) {
    return watchLazy(fireImmediately: fireImmediately)
        .asyncMap((event) => findAllAsync());
  }

  @override
  Stream<void> watchLazy({bool fireImmediately = false}) {
    final port = ReceivePort();
    final handlePtrPtr = IsarCore.ptrPtr.cast<Pointer<CWatchHandle>>();

    isar_watch_query(
      isar.getPtr(),
      _ptr,
      port.sendPort.nativePort,
      handlePtrPtr,
    ).checkNoError();

    final handlePtr = handlePtrPtr.value;
    final controller = StreamController<void>(
      onCancel: () {
        isar.getPtr(); // Make sure Isar is not closed
        isar_stop_watching(handlePtr);
        port.close();
      },
    );

    if (fireImmediately) {
      controller.add(null);
    }

    controller.addStream(port);
    return controller.stream;
  }

  @override
  void close() {
    isar_query_free(_ptr);
    _ptrAddress = 0;
  }
}
