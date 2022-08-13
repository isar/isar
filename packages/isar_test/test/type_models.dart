import 'package:isar/isar.dart';

part 'type_models.g.dart';

@Collection()
class BoolModel {
  Id? id;

  bool value = false;

  bool? nValue;

  List<bool> list = [];

  List<bool>? nList;
}

@Collection()
class ByteModel {
  Id? id;

  byte value = 0;

  List<byte> list = [];

  List<byte>? nList;
}

@Collection()
class ShortModel {
  Id? id;

  short value = 0;

  short? nValue;

  List<short> list = [];

  List<short>? nList;
}

@Collection()
class IntModel {
  Id? id;

  int value = 0;

  int? nValue;

  List<int> list = [];

  List<int>? nList;
}

@Collection()
class FloatModel {
  Id? id;

  float value = 0;

  float? nValue;

  List<float> list = [];

  List<float>? nList;
}

@Collection()
class DoubleModel {
  Id? id;

  double value = 0;

  double? nValue;

  List<double> list = [];

  List<double>? nList;
}

@Collection()
class DateTimeModel {
  Id? id;

  DateTime value = DateTime.fromMillisecondsSinceEpoch(0);

  DateTime? nValue;

  List<DateTime> list = [];

  List<DateTime>? nList;
}

@Collection()
class StringModel {
  Id? id;

  String value = '';

  String? nValue;

  List<String> list = [];

  List<String>? nList;
}

@Embedded()
class EmbeddedModel {
  EmbeddedModel([this.value]);

  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is EmbeddedModel && other.value == value;
}

@Collection()
class ObjectModel {
  Id? id;

  EmbeddedModel value = EmbeddedModel();

  EmbeddedModel? nValue;

  List<EmbeddedModel> list = [];

  List<EmbeddedModel>? nList;
}

enum TestEnum with IsarEnum<String> {
  option1,
  option2,
  option3;

  @override
  String get value => name;
}

@Collection()
class EnumModel {
  Id? id;

  TestEnum value = TestEnum.option1;

  TestEnum? nValue;

  List<TestEnum> list = [];

  List<TestEnum>? nList;
}
