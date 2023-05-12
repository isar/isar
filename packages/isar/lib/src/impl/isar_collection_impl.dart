part of isar;

class _IsarCollectionImpl<ID, OBJ> implements IsarCollection<ID, OBJ> {
  const _IsarCollectionImpl(this.isar, this.collectionIndex, this.converter);

  final _IsarImpl isar;
  final int collectionIndex;
  final ObjectConverter<ID, OBJ> converter;

  @override
  int get largestId {
    return isar_get_largest_id(isar.getPtr(), collectionIndex);
  }

  @override
  OBJ? get(ID id) {
    return isar.getTxn((isarPtr, txnPtr) {
      final readerPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarReader>>();

      isar_get(
        isarPtr,
        txnPtr,
        collectionIndex,
        _idToInt(id),
        readerPtrPtr,
      ).checkNoError();

      final readerPtr = readerPtrPtr.value;
      if (!readerPtr.isNull) {
        final object = converter.deserialize(readerPtr);
        isar_free_reader(readerPtr);
        return object;
      } else {
        return null;
      }
    });
  }

  @override
  List<OBJ?> getAll(List<ID> ids) {
    final objects = List<OBJ?>.filled(ids.length, null);
    return isar.getTxn((isarPtr, txnPtr) {
      final readerPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarReader>>();

      for (var i = 0; i < ids.length; i++) {
        final id = ids[i];

        isar_get(
          isarPtr,
          txnPtr,
          collectionIndex,
          _idToInt(id),
          readerPtrPtr,
        ).checkNoError();

        final readerPtr = readerPtrPtr.value;
        if (!readerPtr.isNull) {
          objects[i] = converter.deserialize(readerPtr);
          isar_free_reader(readerPtr);
        }
      }

      return objects;
    });
  }

  @override
  void put(OBJ object) {
    putAll([object]);
  }

  @override
  void putAll(List<OBJ> objects) {
    return isar.getWriteTxn(consume: true, (isarPtr, txnPtr) {
      final insertPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarInsert>>();
      isar_insert(
        isarPtr,
        txnPtr,
        collectionIndex,
        objects.length,
        insertPtrPtr,
      ).checkNoError();

      final writerPtrPtr = insertPtrPtr.cast<Pointer<CIsarWriter>>();
      for (final object in objects) {
        final id = converter.serialize(object, writerPtrPtr.value);
        isar_insert_save(insertPtrPtr, id).checkNoError();
      }

      final txnPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarTxn>>();
      isar_insert_finish(insertPtrPtr.value, txnPtrPtr).checkNoError();

      return (null, txnPtrPtr.value);
    });
  }

  @override
  bool delete(ID id) {
    return isar.getWriteTxn((isarPtr, txnPtr) {
      isar_delete(
        isarPtr,
        txnPtr,
        collectionIndex,
        _idToInt(id),
        IsarCore.boolPtr,
      ).checkNoError();

      return (IsarCore.boolPtr.value, null);
    });
  }

  @override
  int deleteAll(List<ID> ids) {
    return isar.getWriteTxn((isarPtr, txnPtr) {
      var count = 0;
      for (final id in ids) {
        isar_delete(
          isarPtr,
          txnPtr,
          collectionIndex,
          _idToInt(id),
          IsarCore.boolPtr,
        ).checkNoError();

        if (IsarCore.boolPtr.value) {
          count++;
        }
      }

      return (count, null);
    });
  }

  @override
  QueryBuilder<OBJ, OBJ, QStart> where() {
    return QueryBuilder._(_QueryBuilder(collection: this));
  }

  @override
  int count() {
    return isar.getTxn((isarPtr, txnPtr) {
      isar_count(isarPtr, txnPtr, collectionIndex, IsarCore.countPtr);
      return IsarCore.countPtr.value;
    });
  }

  @override
  void clear() {
    //where().deleteAll();
  }

  @override
  Query<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? property,
  }) {
    final alloc = Arena(malloc);
    final builderPtrPtr = alloc<Pointer<CIsarQueryBuilder>>();
    isar_query_new(isar.getPtr(), collectionIndex, builderPtrPtr)
        .checkNoError();

    final builderPtr = builderPtrPtr.value;
    if (filter != null) {
      final filterPtr = buildFilter(alloc, filter);
      isar_query_set_filter(builderPtr, filterPtr);
    }

    for (final sort in sortBy) {
      isar_query_add_sort(
        builderPtr,
        sort.property,
        sort.sort == Sort.asc,
        sort.caseSensitive,
      );
    }

    final query = isar_query_build(builderPtr);
    return _QueryImpl(
      instanceId: isar.instanceId,
      ptrAddress: query.address,
      deserialize: converter.deserialize as R Function(Pointer<CIsarReader>),
    );
  }
}

@pragma('vm:prefer-inline')
int _idToInt<OBJ>(OBJ id) {
  if (id is int) {
    return id;
  } else if (id is String) {
    return Isar.fastHash(id);
  } else {
    throw 'Unsupported id type';
  }
}
