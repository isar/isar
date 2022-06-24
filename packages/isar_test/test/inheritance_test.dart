import 'package:isar/isar.dart';

part 'inheritance_test.g.dart';

class Parent {
  int? id;

  @Index()
  String? parentField;

  @Name('name')
  int get parentFieldLength => parentField?.length ?? 0;

  @Ignore()
  String? ignoreParent;
}

@Collection()
class Child extends Parent {
  late String childField;

  int get childFieldLength => childField.length;

  @Ignore()
  late String ignoreChild;
}

@Collection(inheritance: false)
class NoInheritanceChild extends Parent {
  @Id()
  int? myId;

  late String childField;

  int get childFieldLength => childField.length;

  @Ignore()
  late String ignoreChild;
}

void main() {}
