import 'package:isar/isar.dart';

part 'constructor_model.g.dart';

@Collection()
class EmptyConstructorModel {
  int? id;

  EmptyConstructorModel();
}

@Collection()
class NamedConstructorModel {
  int? id;

  final String name;

  NamedConstructorModel({required this.name});
}

@Collection()
class PositionalConstructorModel {
  final int? id;

  final String name;

  PositionalConstructorModel(this.id, this.name);
}

@Collection()
class OptionalConstructorModel {
  final int? id;

  final String name;

  OptionalConstructorModel(this.name, [this.id]);
}

@Collection()
class PositionalNamedConstructorModel {
  final int id;

  String name;

  PositionalNamedConstructorModel(this.name, {required this.id});
}

@Collection()
class SerializeOnlyModel {
  final int? id;

  final String name = 'myName';

  String get someGetter => '$name$name';

  SerializeOnlyModel(this.id);
}
