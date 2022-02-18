import 'dart:convert';
import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'package:test/expect.dart';

import 'common.dart';

part 'schema_test.g.dart';

@Collection()
class SchemaTestModel {
  int? id;

  @Name('renamedField')
  @Index(unique: true)
  late bool someField;

  @Name('renamedGetter')
  @Index(unique: true)
  bool get someGetter => false;

  @Ignore()
  late bool someOtherField;

  @Ignore()
  bool get someOtherGetter => false;

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

@Collection()
class $Dollar$Model {
  @Id()
  int? $dollar$id;

  @Index(unique: true)
  late bool $dollar$Field;

  @Index()
  bool get $dollar$Getter => false;

  final $dollar$Link = IsarLink<$Dollar$Model>();

  final $dollar$Links = IsarLinks<$Dollar$Model>();
}

void main() {
  isarTest('Schema test', () {
    final schemaJson = jsonDecode(SchemaTestModelSchema.schema);
    expect(schemaJson, {
      'name': 'SchemaTestModel',
      'idName': 'id',
      'properties': [
        {'name': 'boolField', 'type': 'Bool'},
        {'name': 'boolGetter', 'type': 'Bool'},
        {'name': 'boolListField', 'type': 'BoolList'},
        {'name': 'boolListGetter', 'type': 'BoolList'},
        {'name': 'bytesField', 'type': 'ByteList'},
        {'name': 'bytesGetter', 'type': 'ByteList'},
        {'name': 'compositeField', 'type': 'String'},
        {'name': 'compositeGetter', 'type': 'String'},
        {'name': 'doubleField', 'type': 'Double'},
        {'name': 'doubleGetter', 'type': 'Double'},
        {'name': 'doubleListField', 'type': 'DoubleList'},
        {'name': 'doubleListGetter', 'type': 'DoubleList'},
        {'name': 'floatField', 'type': 'Float'},
        {'name': 'floatGetter', 'type': 'Float'},
        {'name': 'floatListField', 'type': 'FloatList'},
        {'name': 'floatListGetter', 'type': 'FloatList'},
        {'name': 'intField', 'type': 'Int'},
        {'name': 'intGetter', 'type': 'Int'},
        {'name': 'intListField', 'type': 'IntList'},
        {'name': 'intListGetter', 'type': 'IntList'},
        {'name': 'longField', 'type': 'Long'},
        {'name': 'longGetter', 'type': 'Long'},
        {'name': 'longListField', 'type': 'LongList'},
        {'name': 'longListGetter', 'type': 'LongList'},
        {'name': 'renamedField', 'type': 'Bool'},
        {'name': 'renamedGetter', 'type': 'Bool'},
        {'name': 'stringField', 'type': 'String'},
        {'name': 'stringGetter', 'type': 'String'},
        {'name': 'stringListField', 'type': 'StringList'}
      ],
      'indexes': [
        {
          'name': 'boolField',
          'unique': false,
          'properties': [
            {'name': 'boolField', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'boolGetter',
          'unique': false,
          'properties': [
            {'name': 'boolGetter', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'boolListFieldHash',
          'unique': false,
          'properties': [
            {'name': 'boolListField', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'boolListFieldValue',
          'unique': false,
          'properties': [
            {'name': 'boolListField', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'boolListGetterHash',
          'unique': false,
          'properties': [
            {'name': 'boolListGetter', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'boolListGetterValue',
          'unique': false,
          'properties': [
            {'name': 'boolListGetter', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'bytesField',
          'unique': false,
          'properties': [
            {'name': 'bytesField', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'bytesGetter',
          'unique': false,
          'properties': [
            {'name': 'bytesGetter', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'compositeField1',
          'unique': false,
          'properties': [
            {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'boolField', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'compositeField2',
          'unique': false,
          'properties': [
            {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'boolField', 'type': 'Value', 'caseSensitive': false},
            {'name': 'intField', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'compositeFieldCICI',
          'unique': false,
          'properties': [
            {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': false},
            {'name': 'stringField', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'compositeFieldCICS',
          'unique': false,
          'properties': [
            {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': false},
            {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'compositeFieldCSCI',
          'unique': false,
          'properties': [
            {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'stringField', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'compositeFieldCSCS',
          'unique': false,
          'properties': [
            {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'compositeFieldHashed',
          'unique': false,
          'properties': [
            {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'compositeFieldValue',
          'unique': false,
          'properties': [
            {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'stringField', 'type': 'Value', 'caseSensitive': true}
          ]
        },
        {
          'name': 'compositeGetter1',
          'unique': false,
          'properties': [
            {'name': 'compositeGetter', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'boolGetter', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'compositeGetter2',
          'unique': false,
          'properties': [
            {'name': 'compositeGetter', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'boolGetter', 'type': 'Value', 'caseSensitive': false},
            {'name': 'intGetter', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'compositeGetterCICI',
          'unique': false,
          'properties': [
            {'name': 'compositeGetter', 'type': 'Hash', 'caseSensitive': false},
            {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'compositeGetterCICS',
          'unique': false,
          'properties': [
            {'name': 'compositeGetter', 'type': 'Hash', 'caseSensitive': false},
            {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'compositeGetterCSCI',
          'unique': false,
          'properties': [
            {'name': 'compositeGetter', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'compositeGetterCSCS',
          'unique': false,
          'properties': [
            {'name': 'compositeGetter', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'compositeGetterHashed',
          'unique': false,
          'properties': [
            {'name': 'compositeGetter', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'compositeGetterValue',
          'unique': false,
          'properties': [
            {'name': 'compositeGetter', 'type': 'Hash', 'caseSensitive': true},
            {'name': 'stringGetter', 'type': 'Value', 'caseSensitive': true}
          ]
        },
        {
          'name': 'renamedField',
          'unique': true,
          'properties': [
            {'name': 'renamedField', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'renamedGetter',
          'unique': true,
          'properties': [
            {'name': 'renamedGetter', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': 'stringFieldCaseInsensitive',
          'unique': false,
          'properties': [
            {'name': 'stringField', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'stringFieldCaseSensitive',
          'unique': false,
          'properties': [
            {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'stringFieldHashed',
          'unique': false,
          'properties': [
            {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'stringFieldValue',
          'unique': false,
          'properties': [
            {'name': 'stringField', 'type': 'Value', 'caseSensitive': true}
          ]
        },
        {
          'name': 'stringGetterCaseInsensitive',
          'unique': false,
          'properties': [
            {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': false}
          ]
        },
        {
          'name': 'stringGetterCaseSensitive',
          'unique': false,
          'properties': [
            {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'stringGetterHashed',
          'unique': false,
          'properties': [
            {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'stringGetterValue',
          'unique': false,
          'properties': [
            {'name': 'stringGetter', 'type': 'Value', 'caseSensitive': true}
          ]
        },
        {
          'name': 'stringListFieldCaseInsensitive',
          'unique': false,
          'properties': [
            {
              'name': 'stringListField',
              'type': 'HashElements',
              'caseSensitive': false
            }
          ]
        },
        {
          'name': 'stringListFieldCaseSensitive',
          'unique': false,
          'properties': [
            {
              'name': 'stringListField',
              'type': 'HashElements',
              'caseSensitive': true
            }
          ]
        },
        {
          'name': 'stringListFieldHashed',
          'unique': false,
          'properties': [
            {'name': 'stringListField', 'type': 'Hash', 'caseSensitive': true}
          ]
        },
        {
          'name': 'stringListFieldHashedElements',
          'unique': false,
          'properties': [
            {
              'name': 'stringListField',
              'type': 'HashElements',
              'caseSensitive': true
            }
          ]
        },
        {
          'name': 'stringListFieldValue',
          'unique': false,
          'properties': [
            {'name': 'stringListField', 'type': 'Value', 'caseSensitive': true}
          ]
        }
      ],
      'links': [
        {'name': 'link', 'target': 'SchemaTestModel'},
        {'name': 'links', 'target': 'SchemaTestModel'},
        {'name': 'renamedLink', 'target': 'SchemaTestModel'},
        {'name': 'renamedLinks', 'target': 'SchemaTestModel'}
      ]
    });
  });

  isarTest('Dollar Schema test', () {
    final schemaJson = jsonDecode($Dollar$ModelSchema.schema);
    expect(schemaJson, {
      'name': '\$Dollar\$Model',
      'idName': '\$dollar\$id',
      'properties': [
        {'name': '\$dollar\$Field', 'type': 'Bool'},
        {'name': '\$dollar\$Getter', 'type': 'Bool'}
      ],
      'indexes': [
        {
          'name': '\$dollar\$Field',
          'unique': true,
          'properties': [
            {'name': '\$dollar\$Field', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': '\$dollar\$Getter',
          'unique': false,
          'properties': [
            {
              'name': '\$dollar\$Getter',
              'type': 'Value',
              'caseSensitive': false
            }
          ]
        }
      ],
      'links': [
        {'name': '\$dollar\$Link', 'target': '\$Dollar\$Model'},
        {'name': '\$dollar\$Links', 'target': '\$Dollar\$Model'}
      ]
    });
  });
}
