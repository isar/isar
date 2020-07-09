import 'dart:async';

import 'package:isar/src/isar_bank.dart';

class IsarObject {
  int _id;
  IsarBank _bank;

  int get id => _id;

  IsarBank get bank => _bank;

  DateTime _createdAt;

  DateTime get createdAt {
    if (_createdAt == null) {
      var secondsSinceEpoch = (id >> 16) & 0xFFFFFFFF;
      _createdAt =
          DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
    }
    return _createdAt;
  }

  FutureOr<void> save() {
    return bank.put(this);
  }

  FutureOr<void> delete() {
    return bank.delete(this);
  }
}

extension ObjectInternal on IsarObject {
  void init(int id, IsarBank bank) {
    _id = id;
    _bank = bank;
  }
}
