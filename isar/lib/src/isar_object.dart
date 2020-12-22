import 'dart:async';

import 'package:isar/src/isar_collection.dart';
import 'package:isar/src/object_id.dart';

class IsarObject {
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
    return collection!.delete(this);
  }

  void deleteSync() {
    return collection!.deleteSync(this);
  }
}

extension ObjectInternal on IsarObject {
  void init(ObjectId id, IsarCollection collection) {
    _id = id;
    _collection = collection;
  }

  void uninit() {
    _id = null;
    _collection = null;
  }
}
