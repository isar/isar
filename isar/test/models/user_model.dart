import 'package:isar/isar.dart';

import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class UserModel {
  @Id()
  int? id;

  @Index()
  String? name;

  @Index()
  int? age = 0;

  bool admin = false;

  UserModel();

  UserModel.fill(this.name, this.age, this.admin);

  @override
  String toString() {
    return '{name: $name, age: $age, admin: $admin}';
  }

  @override
  bool operator ==(other) {
    final otherModel = other as UserModel;
    return name == otherModel.name &&
        age == otherModel.age &&
        admin == otherModel.admin;
  }
}
