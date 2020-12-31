part of isar;

mixin IsarObjectMixin {
  ObjectId? _id;
  IsarCollection? _collection;

  ObjectId? get id => _id;

  IsarCollection? get collection => _collection;

  DateTime? _createdAt;

  DateTime? get createdAt {
    if (_createdAt == null && _id != null) {
      var millisSinceEpoch = _id!.time! * 1000;
      _createdAt = DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);
    }
    return _createdAt;
  }

  Future<void> save() {
    return collection!.put(this);
  }

  void saveSync() {
    collection!.putSync(this);
  }

  Future<void> delete() {
    return collection!.delete(id!);
  }

  void deleteSync() {
    return collection!.deleteSync(id!);
  }
}

extension ObjectInternal on IsarObjectMixin {
  void init(ObjectId id, IsarCollection collection) {
    _id = id;
    _collection = collection;
  }

  void uninit() {
    _id = null;
    _collection = null;
  }
}
