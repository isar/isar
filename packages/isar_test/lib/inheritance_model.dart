import 'package:isar/isar.dart';

part 'inheritance_model.g.dart';

class Parent {
  int? id;

  @Index()
  late String parentField;

  @Name("name")
  int get parentFieldLength => parentField.length;

  @Ignore()
  late String ignoreParent;
}

@Collection()
class Child extends Parent {
  late String childField;

  int get childFieldLength => childField.length;

  @Ignore()
  late String ignoreChild;
}
