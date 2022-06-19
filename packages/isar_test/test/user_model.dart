import 'package:isar/isar.dart';

part 'user_model.g.dart';

@Collection()
class UserModel {
  UserModel();

  UserModel.fill(this.name, this.age, this.admin);
  @Id()
  int? id;

  @Index()
  String? name;

  @Index()
  int? age = 0;

  bool admin = false;

  @override
  String toString() {
    return '{name: $name, age: $age, admin: $admin}';
  }

  @override
  bool operator ==(Object other) {
    final UserModel otherModel = other as UserModel;
    return name == otherModel.name &&
        age == otherModel.age &&
        admin == otherModel.admin;
  }
}
