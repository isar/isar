import 'package:isar/isar.dart';

part 'common.g.dart';

enum MyEnum with IsarEnum<String> {
  value1,
  value2,
  value3;

  @override
  String get isarValue => name;
}

@Embedded()
class MyEmbedded {
  const MyEmbedded([this.test = '']);

  final String test;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => other is MyEmbedded && other.test == test;
}

@Name('Col')
@Collection()
class EmptyModel {
  EmptyModel(this.id);

  final Id id;
}
