part of isar;

class _IsarQueryImpl<T> extends IsarQuery<T> {
  _IsarQueryImpl({
    required int instanceId,
    required int ptrAddress,
    required Deserialize<T> deserialize,
    List<int>? properties,
  })  : _instanceId = instanceId,
        _ptrAddress = ptrAddress,
        _properties = properties,
        _deserialize = deserialize;

  final int _instanceId;
  final List<int>? _properties;
  final Deserialize<T> _deserialize;
  int _ptrAddress;

  Pointer<CIsarQuery> get _ptr {
    final ptr = ptrFromAddress<CIsarQuery>(_ptrAddress);
    if (ptr.isNull) {
      throw StateError('Query has already been closed.');
    }
    return ptr;
  }

  @override
  _IsarImpl get isar => _IsarImpl.instance(_instanceId);

  List<E> _findAll<E>(Deserialize<E> deserialize, {int? offset, int? limit}) {
    if (limit == 0) {
      throw ArgumentError('Limit must be greater than 0.');
    }

    return isar.getTxn((isarPtr, txnPtr) {
      final cursorPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarQueryCursor>>();
      IsarCore.b
          .isar_query_cursor(
            isarPtr,
            txnPtr,
            _ptr,
            cursorPtrPtr,
            offset ?? 0,
            limit ?? 0,
          )
          .checkNoError();
      final cursorPtr = cursorPtrPtr.ptrValue;

      Pointer<CIsarReader> readerPtr = nullptr;
      final values = <E>[];
      while (true) {
        readerPtr = IsarCore.b.isar_query_cursor_next(cursorPtr, readerPtr);
        if (readerPtr.isNull) break;
        values.add(deserialize(readerPtr));
      }
      IsarCore.b.isar_query_cursor_free(cursorPtr, readerPtr);
      return values;
    });
  }

  @override
  List<T> findAll({int? offset, int? limit}) {
    return _findAll(_deserialize, offset: offset, limit: limit);
  }

  @override
  int updateProperties(Map<int, dynamic> changes, {int? offset, int? limit}) {
    if (limit == 0) {
      throw ArgumentError('Limit must be greater than 0.');
    }

    return isar.getWriteTxn((isarPtr, txnPtr) {
      final updatePtr = IsarCore.b.isar_update_new();
      for (final propertyId in changes.keys) {
        final value = _isarValue(changes[propertyId]);
        IsarCore.b.isar_update_add_value(updatePtr, propertyId, value);
      }

      IsarCore.b
          .isar_query_update(
            isarPtr,
            txnPtr,
            _ptr,
            offset ?? 0,
            limit ?? 0,
            updatePtr,
            IsarCore.countPtr,
          )
          .checkNoError();

      return (IsarCore.countPtr.u32Value, txnPtr);
    });
  }

  @override
  int deleteAll({int? offset, int? limit}) {
    if (limit == 0) {
      throw ArgumentError('Limit must be greater than 0.');
    }

    return isar.getWriteTxn((isarPtr, txnPtr) {
      IsarCore.b
          .isar_query_delete(
            isarPtr,
            txnPtr,
            _ptr,
            offset ?? 0,
            limit ?? 0,
            IsarCore.countPtr,
          )
          .checkNoError();
      return (IsarCore.countPtr.u32Value, txnPtr);
    });
  }

  @override
  List<Map<String, dynamic>> exportJson({int? offset, int? limit}) {
    final bufferPtrPtr = malloc<Pointer<Uint8>>();
    bufferPtrPtr.ptrValue = nullptr;
    final bufferSizePtr = malloc<Uint32>();

    Map<String, dynamic> deserialize(IsarReader reader) {
      final jsonSize =
          IsarCore.b.isar_read_to_json(reader, bufferPtrPtr, bufferSizePtr);
      final bufferPtr = bufferPtrPtr.ptrValue;
      if (bufferPtr == nullptr) {
        throw StateError('Error while exporting JSON.');
      } else {
        final jsonBytes = bufferPtr.asU8List(jsonSize);
        return jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
      }
    }

    try {
      return _findAll(deserialize, offset: offset, limit: limit);
    } finally {
      IsarCore.b
          .isar_buffer_free(bufferPtrPtr.ptrValue, bufferSizePtr.u32Value);
      free(bufferPtrPtr);
      free(bufferSizePtr);
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
      final valuePtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarValue>>();
      IsarCore.b
          .isar_query_aggregate(
            isarPtr,
            txnPtr,
            _ptr,
            aggregation,
            _properties?.firstOrNull ?? 0,
            valuePtrPtr,
          )
          .checkNoError();

      final valuePtr = valuePtrPtr.ptrValue;
      if (valuePtr == nullptr) return null;

      try {
        if (true is R) {
          return (IsarCore.b.isar_value_get_bool(valuePtr) != 0) as R;
        } else if (0.5 is R) {
          return IsarCore.b.isar_value_get_real(valuePtr) as R;
        } else if (0 is R) {
          return IsarCore.b.isar_value_get_integer(valuePtr) as R;
        } else if (DateTime.now() is R) {
          return DateTime.fromMillisecondsSinceEpoch(
            IsarCore.b.isar_value_get_integer(valuePtr),
            isUtc: true,
          ).toLocal() as R;
        } else if ('' is R) {
          final length =
              IsarCore.b.isar_value_get_string(valuePtr, IsarCore.stringPtrPtr);
          if (IsarCore.stringPtr.isNull) {
            return null;
          } else {
            return utf8.decode(IsarCore.stringPtr.asU8List(length)) as R;
          }
        } else {
          throw ArgumentError('Unsupported aggregation type: $R');
        }
      } finally {
        IsarCore.b.isar_value_free(valuePtr);
      }
    });
  }

  @override
  Stream<List<T>> watch({
    bool fireImmediately = false,
    int? offset,
    int? limit,
  }) {
    return watchLazy(fireImmediately: fireImmediately)
        .asyncMap((event) => findAllAsync(offset: offset, limit: limit));
  }

  @override
  Stream<void> watchLazy({bool fireImmediately = false}) {
    if (IsarCore.kIsWeb) {
      throw UnsupportedError('Watchers are not supported on the web');
    }

    final port = ReceivePort();
    final handlePtrPtr = IsarCore.ptrPtr.cast<Pointer<CWatchHandle>>();

    IsarCore.b
        .isar_watch_query(
          isar.getPtr(),
          _ptr,
          port.sendPort.nativePort,
          handlePtrPtr,
        )
        .checkNoError();

    final handlePtr = handlePtrPtr.ptrValue;
    final controller = StreamController<void>(
      onCancel: () {
        isar.getPtr(); // Make sure Isar is not closed
        IsarCore.b.isar_stop_watching(handlePtr);
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
    IsarCore.b.isar_query_free(_ptr);
    _ptrAddress = 0;
  }
}
