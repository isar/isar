import 'dart:async';

import 'package:isar/src/isar_collection.dart';

class IsarObject {
  int _id;
  IsarCollection _collection;

  int get id => _id;

  IsarCollection get collection => _collection;

  DateTime _createdAt;

  DateTime get createdAt {
    if (_createdAt == null && _id != null) {
      var secondsSinceEpoch = (_id >> 16) & 0xFFFFFFFF;
      _createdAt =
          DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
    }
    return _createdAt;
  }

  FutureOr<void> save() {
    return collection.put(this);
  }

  FutureOr<void> delete() {
    return collection.delete(this);
  }
}

extension ObjectInternal on IsarObject {
  void init(int id, IsarCollection collection) {
    _id = id;
    _collection = collection;
  }
}
