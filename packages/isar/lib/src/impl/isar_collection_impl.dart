part of isar;

class _IsarCollectionImpl<ID, OBJ> extends IsarCollection<ID, OBJ> {
  _IsarCollectionImpl(
    this.isar,
    this.schema,
    this.collectionIndex,
    this.converter,
  );

  @override
  final _IsarImpl isar;

  @override
  final IsarSchema schema;

  final int collectionIndex;
  final IsarObjectConverter<ID, OBJ> converter;

  @override
  int autoIncrement() {
    if (0 is ID) {
      return IsarCore.b.isar_auto_increment(isar.getPtr(), collectionIndex);
    } else {
      throw UnsupportedError(
        'Collections with String IDs do not support auto increment.',
      );
    }
  }

  @override
  List<OBJ?> getAll(List<ID> ids) {
    final objects = List<OBJ?>.filled(ids.length, null, growable: true);
    return isar.getTxn((isarPtr, txnPtr) {
      final cursorPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarCursor>>();

      IsarCore.b
          .isar_cursor(isarPtr, txnPtr, collectionIndex, cursorPtrPtr)
          .checkNoError();

      final cursorPtr = cursorPtrPtr.ptrValue;
      Pointer<CIsarReader> readerPtr = nullptr;
      for (var i = 0; i < ids.length; i++) {
        final id = _idToInt(ids[i]);
        readerPtr = IsarCore.b.isar_cursor_next(cursorPtr, id, readerPtr);
        if (!readerPtr.isNull) {
          objects[i] = converter.deserialize(readerPtr);
        }
      }
      IsarCore.b.isar_cursor_free(cursorPtr, readerPtr);
      return objects;
    });
  }

  @override
  void putAll(List<OBJ> objects) {
    if (objects.isEmpty) return;

    return isar.getWriteTxn(consume: true, (isarPtr, txnPtr) {
      final writerPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarWriter>>();

      IsarCore.b
          .isar_insert(
            isarPtr,
            txnPtr,
            collectionIndex,
            objects.length,
            writerPtrPtr,
          )
          .checkNoError();

      final insertPtr = writerPtrPtr.ptrValue;
      try {
        for (final object in objects) {
          final id = converter.serialize(insertPtr, object);
          IsarCore.b.isar_insert_save(insertPtr, id).checkNoError();
        }
      } catch (e) {
        IsarCore.b.isar_insert_abort(insertPtr);
        rethrow;
      }

      final txnPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarTxn>>();
      IsarCore.b.isar_insert_finish(insertPtr, txnPtrPtr).checkNoError();

      return (null, txnPtrPtr.ptrValue);
    });
  }

  @override
  int updateProperties(List<ID> ids, Map<int, dynamic> changes) {
    if (ids.isEmpty) return 0;

    final updatePtr = IsarCore.b.isar_update_new();
    for (final propertyId in changes.keys) {
      final value = _isarValue(changes[propertyId]);
      IsarCore.b.isar_update_add_value(updatePtr, propertyId, value);
    }

    return isar.getWriteTxn((isarPtr, txnPtr) {
      var count = 0;
      final updatedPtr = IsarCore.boolPtr;
      for (final id in ids) {
        IsarCore.b
            .isar_update(
              isarPtr,
              txnPtr,
              collectionIndex,
              _idToInt(id),
              updatePtr,
              updatedPtr,
            )
            .checkNoError();

        if (updatedPtr.boolValue) {
          count++;
        }
      }

      return (count, txnPtr);
    });
  }

  @override
  bool delete(ID id) {
    return isar.getWriteTxn((isarPtr, txnPtr) {
      IsarCore.b
          .isar_delete(
            isarPtr,
            txnPtr,
            collectionIndex,
            _idToInt(id),
            IsarCore.boolPtr,
          )
          .checkNoError();

      return (IsarCore.boolPtr.boolValue, txnPtr);
    });
  }

  @override
  int deleteAll(List<ID> ids) {
    if (ids.isEmpty) return 0;

    return isar.getWriteTxn((isarPtr, txnPtr) {
      var count = 0;
      for (final id in ids) {
        IsarCore.b
            .isar_delete(
              isarPtr,
              txnPtr,
              collectionIndex,
              _idToInt(id),
              IsarCore.boolPtr,
            )
            .checkNoError();

        if (IsarCore.boolPtr.boolValue) {
          count++;
        }
      }

      return (count, txnPtr);
    });
  }

  @override
  QueryBuilder<OBJ, OBJ, QStart> where() {
    return QueryBuilder(this);
  }

  @override
  int count() {
    return isar.getTxn((isarPtr, txnPtr) {
      IsarCore.b
          .isar_count(isarPtr, txnPtr, collectionIndex, IsarCore.countPtr);
      return IsarCore.countPtr.u32Value;
    });
  }

  @override
  int getSize({bool includeIndexes = false}) {
    return isar.getTxn((isarPtr, txnPtr) {
      return IsarCore.b
          .isar_get_size(isarPtr, txnPtr, collectionIndex, includeIndexes);
    });
  }

  @override
  int importJsonString(String json) {
    return isar.getWriteTxn(consume: true, (isarPtr, txnPtr) {
      final txnPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarTxn>>();
      txnPtrPtr.ptrValue = txnPtr;
      final nativeString = IsarCore._toNativeString(json);
      IsarCore.b
          .isar_import_json(
            isarPtr,
            txnPtrPtr,
            collectionIndex,
            nativeString,
            IsarCore.countPtr,
          )
          .checkNoError();
      return (IsarCore.countPtr.u32Value, txnPtrPtr.ptrValue);
    });
  }

  @override
  void clear() {
    return isar.getWriteTxn((isarPtr, txnPtr) {
      IsarCore.b.isar_clear(isarPtr, txnPtr, collectionIndex);
      return (null, txnPtr);
    });
  }

  @override
  Stream<void> watchLazy({bool fireImmediately = false}) {
    if (IsarCore.kIsWeb) {
      throw UnsupportedError('Watchers are not supported on the web');
    }

    final port = ReceivePort();
    final handlePtrPtr = IsarCore.ptrPtr.cast<Pointer<CWatchHandle>>();

    IsarCore.b
        .isar_watch_collection(
          isar.getPtr(),
          collectionIndex,
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
  Stream<OBJ?> watchObject(ID id, {bool fireImmediately = false}) {
    return watchObjectLazy(id, fireImmediately: fireImmediately)
        .asyncMap((event) => getAsync(id));
  }

  @override
  Stream<void> watchObjectLazy(ID id, {bool fireImmediately = false}) {
    if (IsarCore.kIsWeb) {
      throw UnsupportedError('Watchers are not supported on the web');
    }

    final port = ReceivePort();
    final handlePtrPtr = IsarCore.ptrPtr.cast<Pointer<CWatchHandle>>();

    IsarCore.b
        .isar_watch_object(
          isar.getPtr(),
          collectionIndex,
          _idToInt(id),
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
  IsarQuery<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty>? sortBy,
    List<DistinctProperty>? distinctBy,
    List<int>? properties,
  }) {
    if (properties != null && properties.length > 3) {
      throw ArgumentError('Only up to 3 properties are supported');
    }

    final builderPtrPtr = malloc<Pointer<CIsarQueryBuilder>>();
    IsarCore.b
        .isar_query_new(isar.getPtr(), collectionIndex, builderPtrPtr)
        .checkNoError();

    final builderPtr = builderPtrPtr.ptrValue;
    if (filter != null) {
      final pointers = <Pointer<Never>>[];
      try {
        final filterPtr = _buildFilter(filter, pointers);
        IsarCore.b.isar_query_set_filter(builderPtr, filterPtr);
      } finally {
        for (final ptr in pointers) {
          free(ptr);
        }
      }
    }

    if (sortBy != null) {
      for (final sort in sortBy) {
        IsarCore.b.isar_query_add_sort(
          builderPtr,
          sort.property,
          sort.sort == Sort.asc,
          sort.caseSensitive,
        );
      }
    }

    if (distinctBy != null) {
      for (final distinct in distinctBy) {
        IsarCore.b.isar_query_add_distinct(
          builderPtr,
          distinct.property,
          distinct.caseSensitive,
        );
      }
    }

    late final R Function(Pointer<CIsarReader>) deserialize;
    switch (properties?.length ?? 0) {
      case 0:
        deserialize = converter.deserialize as R Function(Pointer<CIsarReader>);
      case 1:
        final property = properties![0];
        final deserializeProp = converter.deserializeProperty!;
        deserialize = (reader) => deserializeProp(reader, property) as R;
      case 2:
        final property1 = properties![0];
        final property2 = properties[1];
        final deserializeProp = converter.deserializeProperty!;
        deserialize = (reader) => (
              deserializeProp(reader, property1),
              deserializeProp(reader, property2)
            ) as R;
      case 3:
        final property1 = properties![0];
        final property2 = properties[1];
        final property3 = properties[2];
        final deserializeProp = converter.deserializeProperty!;
        deserialize = (reader) => (
              deserializeProp(reader, property1),
              deserializeProp(reader, property2),
              deserializeProp(reader, property3),
            ) as R;
    }

    final queryPtr = IsarCore.b.isar_query_build(builderPtr);
    return _IsarQueryImpl(
      instanceId: isar.instanceId,
      ptrAddress: queryPtr.address,
      properties: properties,
      deserialize: deserialize,
    );
  }
}

@tryInline
int _idToInt<OBJ>(OBJ id) {
  if (id is int) {
    return id;
  } else {
    return Isar.fastHash(id as String);
  }
}
