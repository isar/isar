import 'package:isar/isar.dart';

part 'common.g.dart';

enum MyEnum {
  value1,
  value2,
  value3;
}

@embedded
class MyEmbedded {
  const MyEmbedded([this.test = '']);

  final String test;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => other is MyEmbedded && other.test == test;
}

@Name('Col')
@collection
class EmptyModel {
  EmptyModel(this.id);

  final Id id;
}
