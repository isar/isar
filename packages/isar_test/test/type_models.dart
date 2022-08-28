import 'package:isar/isar.dart';

part 'type_models.g.dart';

@collection
class BoolModel {
  Id? id;

  bool value = false;

  bool? nValue;

  List<bool> list = [];

  List<bool>? nList;
}

@collection
class ByteModel {
  Id? id;

  byte value = 0;

  List<byte> list = [];

  List<byte>? nList;
}

@collection
class ShortModel {
  Id? id;

  short value = 0;

  short? nValue;

  List<short> list = [];

  List<short>? nList;
}

@collection
class IntModel {
  Id? id;

  int value = 0;

  int? nValue;

  List<int> list = [];

  List<int>? nList;
}

@collection
class FloatModel {
  Id? id;

  float value = 0;

  float? nValue;

  List<float> list = [];

  List<float>? nList;
}

@collection
class DoubleModel {
  Id? id;

  double value = 0;

  double? nValue;

  List<double> list = [];

  List<double>? nList;
}

@collection
class DateTimeModel {
  Id? id;

  DateTime value = DateTime.fromMillisecondsSinceEpoch(0);

  DateTime? nValue;

  List<DateTime> list = [];

  List<DateTime>? nList;
}

@collection
class StringModel {
  Id? id;

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
  Id? id;

  EmbeddedModel value = EmbeddedModel();

  EmbeddedModel? nValue;

  List<EmbeddedModel> list = [];

  List<EmbeddedModel>? nList;
}

enum TestEnum {
  option1,
  option2,
  option3;
}

@collection
class EnumModel {
  Id? id;

  @Enumerated(EnumType.name)
  TestEnum value = TestEnum.option1;

  @Enumerated(EnumType.name)
  TestEnum? nValue;

  @Enumerated(EnumType.name)
  List<TestEnum> list = [];

  @Enumerated(EnumType.name)
  List<TestEnum>? nList;
}
