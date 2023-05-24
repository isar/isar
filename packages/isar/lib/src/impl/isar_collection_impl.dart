part of isar;

class _IsarCollectionImpl<ID, OBJ> extends IsarCollection<ID, OBJ> {
  _IsarCollectionImpl(this.isar, this.collectionIndex, this.converter);

  @override
  final _IsarImpl isar;

  final int collectionIndex;
  final ObjectConverter<ID, OBJ> converter;

  @override
  int get largestId {
    if (ID == int) {
      return isar_get_largest_id(isar.getPtr(), collectionIndex);
    } else {
      throw UnsupportedError('Only int ids are supported');
    }
  }

  @override
  OBJ? get(ID id) {
    return isar.getTxn((isarPtr, txnPtr) {
      final readerPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarReader>>();

      isar_get(isarPtr, txnPtr, collectionIndex, _idToInt(id), readerPtrPtr)
          .checkNoError();

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
    final objects = List<OBJ?>.filled(ids.length, null, growable: true);
    return isar.getTxn((isarPtr, txnPtr) {
      final readerPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarReader>>();

      for (var i = 0; i < ids.length; i++) {
        isar_get(
          isarPtr,
          txnPtr,
          collectionIndex,
          _idToInt(ids[i]),
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
  void putAll(List<OBJ> objects) {
    if (objects.isEmpty) return;

    return isar.getWriteTxn(consume: true, (isarPtr, txnPtr) {
      final writerPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarWriter>>();

      isar_insert(
        isarPtr,
        txnPtr,
        collectionIndex,
        objects.length,
        writerPtrPtr,
      ).checkNoError();

      final insertPtr = writerPtrPtr.value;
      for (final object in objects) {
        final id = converter.serialize(insertPtr, object);
        isar_insert_save(insertPtr, id).checkNoError();
      }

      final txnPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarTxn>>();
      isar_insert_finish(insertPtr, txnPtrPtr).checkNoError();

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

      return (IsarCore.boolPtr.value, txnPtr);
    });
  }

  @override
  int deleteAll(List<ID> ids) {
    if (ids.isEmpty) return 0;

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

      return (count, txnPtr);
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
  int getSize({bool includeIndexes = false}) {
    return isar.getTxn((isarPtr, txnPtr) {
      return isar_get_size(isarPtr, txnPtr, collectionIndex, includeIndexes);
    });
  }

  @override
  void importJson(List<Map<String, dynamic>> json) {
    importJsonBytes(const Utf8Encoder().convert(jsonEncode(json)));
  }

  @override
  void importJsonBytes(Uint8List jsonBytes) {
    // TODO: implement importJsonBytes
  }

  @override
  void importJsonFile(String path) {
    // TODO: implement importJsonFile
  }

  @override
  void clear() {
    return isar.getWriteTxn((isarPtr, txnPtr) {
      isar_clear(isarPtr, txnPtr, collectionIndex);
      return (null, txnPtr);
    });
  }

  @override
  Query<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty>? sortBy,
    List<DistinctProperty>? distinctBy,
    List<int>? properties,
  }) {
    if (properties != null && properties.length > 3) {
      throw ArgumentError('Only up to 3 properties are supported');
    }

    final alloc = Arena(malloc);
    final builderPtrPtr = alloc<Pointer<CIsarQueryBuilder>>();
    isar_query_new(isar.getPtr(), collectionIndex, builderPtrPtr)
        .checkNoError();

    final builderPtr = builderPtrPtr.value;
    if (filter != null) {
      isar_query_set_filter(builderPtr, _buildFilter(alloc, filter));
    }

    if (sortBy != null) {
      for (final sort in sortBy) {
        isar_query_add_sort(
          builderPtr,
          sort.property,
          sort.sort == Sort.asc,
          sort.caseSensitive,
        );
      }
    }

    if (distinctBy != null) {
      for (final distinct in distinctBy) {
        isar_query_add_distinct(
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

    final query = isar_query_build(builderPtr);
    return _QueryImpl(
      instanceId: isar.instanceId,
      ptrAddress: query.address,
      properties: properties,
      deserialize: deserialize,
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
    throw UnsupportedError('Unsupported id type. This should never happen.');
  }
}

class X<T extends (A, B), A, B> {}
