import 'package:isar/isar.dart';

part 'type_models.g.dart';

@collection
class BoolModel {
  BoolModel(this.id);

  final int id;

  bool value = false;

  bool? nValue;

  List<bool> list = [];

  List<bool>? nList;
}

@collection
class ByteModel {
  ByteModel(this.id);

  final int id;

  byte value = 0;

  List<byte> list = [];

  List<byte>? nList;
}

@collection
class ShortModel {
  ShortModel(this.id);

  final int id;

  short value = 0;

  short? nValue;

  List<short> list = [];

  List<short>? nList;
}

@collection
class IntModel {
  IntModel(this.id);

  final int id;

  int value = 0;

  int? nValue;

  List<int> list = [];

  List<int>? nList;
}

@collection
class FloatModel {
  FloatModel(this.id);

  final int id;

  float value = 0;

  float? nValue;

  List<float> list = [];

  List<float>? nList;
}

@collection
class DoubleModel {
  DoubleModel(this.id);

  final int id;

  double value = 0;

  double? nValue;

  List<double> list = [];

  List<double>? nList;
}

@collection
class DateTimeModel {
  DateTimeModel(this.id);

  final int id;

  DateTime value = DateTime.fromMillisecondsSinceEpoch(0);

  DateTime? nValue;

  List<DateTime> list = [];

  List<DateTime>? nList;
}

@collection
class StringModel {
  StringModel(this.id);

  final int id;

  String value = '';

  String? nValue;

  List<String> list = [];

  List<String>? nList;
}

@embedded
class EmbeddedModel {
  EmbeddedModel([this.value]);

  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is EmbeddedModel && other.value == value;
}

@collection
class ObjectModel {
  ObjectModel(this.id);

  final int id;

  EmbeddedModel value = EmbeddedModel();

  EmbeddedModel? nValue;

  List<EmbeddedModel> list = [];

  List<EmbeddedModel>? nList;
}

enum TestEnum {
  option1(1),
  option2(2),
  option3(3);

  const TestEnum(this.value);

  @enumValue
  final int value;
}

@collection
class EnumModel {
  EnumModel(this.id);

  final int id;

  TestEnum value = TestEnum.option1;

  TestEnum? nValue;

  List<TestEnum> list = [];

  List<TestEnum>? nList;
}
