import 'dart:typed_data';

import 'package:isar/isar.dart';

part 'schema_test_model.g.dart';

@Collection()
class SchemaTestModel {
  int? id;

  @Name('renamedField')
  @Index(unique: true)
  late bool someField;

  @Name('renamedGetter')
  @Index(unique: true)
  bool get someGetter => false;

  //@Ignore()
  // late bool someOtherField;

  @Index()
  late bool boolField;

  @Index()
  bool get boolGetter => false;

  @Size32()
  late int intField;

  @Size32()
  int get intGetter => 0;

  late int longField;

  int get longGetter => 0;

  @Size32()
  late double floatField;

  @Size32()
  double get floatGetter => 0;

  late double doubleField;

  double get doubleGetter => 0;

  @Index(name: 'stringFieldValue', type: IndexType.value)
  @Index(name: 'stringFieldHashed')
  @Index(name: 'stringFieldCaseSensitive', caseSensitive: true)
  @Index(name: 'stringFieldCaseInsensitive', caseSensitive: false)
  late String stringField;

  @Index(name: 'stringGetterValue', type: IndexType.value)
  @Index(name: 'stringGetterHashed')
  @Index(name: 'stringGetterCaseSensitive', caseSensitive: true)
  @Index(name: 'stringGetterCaseInsensitive', caseSensitive: false)
  String get stringGetter => '';

  @Index()
  late Uint8List bytesField;

  @Index()
  Uint8List get bytesGetter => Uint8List(1);

  @Index(name: 'boolListFieldValue')
  @Index(name: 'boolListFieldHash', type: IndexType.hash)
  late List<bool> boolListField;

  @Index(name: 'boolListGetterValue')
  @Index(name: 'boolListGetterHash', type: IndexType.hash)
  List<bool> get boolListGetter => [];

  @Size32()
  late List<int> intListField;

  @Size32()
  List<int> get intListGetter => [];

  late List<int> longListField;

  List<int> get longListGetter => [];

  @Size32()
  late List<double> floatListField;

  @Size32()
  List<double> get floatListGetter => [];

  late List<double> doubleListField;

  List<double> get doubleListGetter => [];

  @Index(name: 'stringListFieldValue', type: IndexType.value)
  @Index(name: 'stringListFieldHashed', type: IndexType.hash)
  @Index(name: 'stringListFieldHashedElements')
  @Index(name: 'stringListFieldCaseSensitive', caseSensitive: true)
  @Index(name: 'stringListFieldCaseInsensitive', caseSensitive: false)
  late List<String> stringListField;

  @Index(
    name: 'compositeField1',
    composite: [
      CompositeIndex('boolField'),
    ],
  )
  @Index(
    name: 'compositeField2',
    composite: [
      CompositeIndex('boolField'),
      CompositeIndex('intField'),
    ],
  )
  @Index(
    name: 'compositeFieldCSCS',
    composite: [CompositeIndex('stringField')],
  )
  @Index(
    name: 'compositeFieldCICS',
    caseSensitive: false,
    composite: [CompositeIndex('stringField')],
  )
  @Index(
    name: 'compositeFieldCSCI',
    composite: [
      CompositeIndex('stringField', caseSensitive: false),
    ],
  )
  @Index(
    name: 'compositeFieldCICI',
    caseSensitive: false,
    composite: [
      CompositeIndex('stringField', caseSensitive: false),
    ],
  )
  @Index(
    name: 'compositeFieldHashed',
    composite: [CompositeIndex('stringField')],
  )
  @Index(
    name: 'compositeFieldValue',
    composite: [CompositeIndex('stringField', type: IndexType.value)],
  )
  late String compositeField;

  @Index(
    name: 'compositeGetter1',
    composite: [
      CompositeIndex('boolGetter'),
    ],
  )
  @Index(
    name: 'compositeGetter2',
    composite: [
      CompositeIndex('boolGetter'),
      CompositeIndex('intGetter'),
    ],
  )
  @Index(
    name: 'compositeGetterCSCS',
    composite: [CompositeIndex('stringGetter')],
  )
  @Index(
    name: 'compositeGetterCICS',
    caseSensitive: false,
    composite: [CompositeIndex('stringGetter')],
  )
  @Index(
    name: 'compositeGetterCSCI',
    composite: [
      CompositeIndex('stringGetter', caseSensitive: false),
    ],
  )
  @Index(
    name: 'compositeGetterCICI',
    caseSensitive: false,
    composite: [
      CompositeIndex('stringGetter', caseSensitive: false),
    ],
  )
  @Index(
    name: 'compositeGetterHashed',
    composite: [CompositeIndex('stringGetter')],
  )
  @Index(
    name: 'compositeGetterValue',
    composite: [
      CompositeIndex('stringGetter', type: IndexType.value),
    ],
  )
  String get compositeGetter => '';

  var link = IsarLink<SchemaTestModel>();

  var links = IsarLinks<SchemaTestModel>();

  @Name('renamedLink')
  var otherLink = IsarLink<SchemaTestModel>();

  @Name('renamedLinks')
  var otherLinks = IsarLinks<SchemaTestModel>();
}
