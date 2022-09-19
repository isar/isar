// ignore_for_file: type_annotate_public_apis

import 'dart:typed_data';

import 'package:isar/isar.dart';

part 'schema_test.g.dart';

@collection
class SchemaTestModel {
  Id? id;

  @Name('renamedField')
  @Index(unique: true)
  late bool someField;

  @Name('renamedGetter')
  @Index(unique: true, replace: true)
  bool get someGetter => false;

  @ignore
  late bool someOtherField;

  @ignore
  bool get someOtherGetter => false;

  @Index()
  late bool boolField;

  @Index()
  bool get boolGetter => false;

  late byte byteField;

  byte get byteGetter => 2;

  late short intField;

  short get intGetter => 0;

  late int longField;

  int get longGetter => 0;

  late float floatField;

  float get floatGetter => 0;

  late double doubleField;

  double get doubleGetter => 0;

  @Index(name: 'stringFieldValue', type: IndexType.value)
  @Index(name: 'stringFieldHashed')
  @Index(name: 'stringFieldCaseSensitive')
  @Index(name: 'stringFieldCaseInsensitive', caseSensitive: false)
  late String stringField;

  @Index(name: 'stringGetterValue', type: IndexType.value)
  @Index(name: 'stringGetterHashed')
  @Index(name: 'stringGetterCaseSensitive')
  @Index(name: 'stringGetterCaseInsensitive', caseSensitive: false)
  String get stringGetter => '';

  @Index(name: 'boolListFieldValue', type: IndexType.value)
  @Index(name: 'boolListFieldHash')
  late List<bool> boolListField;

  @Index(name: 'boolListGetterValue', type: IndexType.value)
  @Index(name: 'boolListGetterHash')
  List<bool> get boolListGetter => [];

  @Index()
  late List<byte> bytesField;

  @Index()
  List<byte> get bytesGetter => Uint8List(1);

  late List<short> intListField;

  List<short> get intListGetter => [];

  late List<int> longListField;

  List<int> get longListGetter => [];

  late List<float> floatListField;

  List<float> get floatListGetter => [];

  late List<double> doubleListField;

  List<double> get doubleListGetter => [];

  @Index(name: 'stringListFieldValue', type: IndexType.value)
  @Index(name: 'stringListFieldHashed')
  @Index(name: 'stringListFieldHashedElements', type: IndexType.hashElements)
  @Index(name: 'stringListFieldCaseSensitive')
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

@collection
class $Dollar$Model {
  Id? $dollar$id;

  @Index(unique: true)
  late bool $dollar$Field;

  @Index()
  bool get $dollar$Getter => false;

  final $dollar$Link = IsarLink<$Dollar$Model>();

  final $dollar$Links = IsarLinks<$Dollar$Model>();
}

void main() {
  /*isarTest('DollarModel Schema test', () {
    final schemaJson = jsonDecode($Dollar$ModelSchema.schema);
    expect(schemaJson, {
      'name': r'$Dollar$Model',
      'idName': r'$dollar$id',
      'properties': [
        {'name': r'$dollar$Field', 'type': 'Bool'},
        {'name': r'$dollar$Getter', 'type': 'Bool'}
      ],
      'indexes': [
        {
          'name': r'$dollar$Field',
          'unique': true,
          'replace': false,
          'properties': [
            {'name': r'$dollar$Field', 'type': 'Value', 'caseSensitive': false}
          ]
        },
        {
          'name': r'$dollar$Getter',
          'unique': false,
          'replace': false,
          'properties': [
            {'name': r'$dollar$Getter', 'type': 'Value', 'caseSensitive': false}
          ]
        }
      ],
      'links': [
        {'name': r'$dollar$Link', 'target': r'$Dollar$Model', 'single': true},
        {'name': r'$dollar$Links', 'target': r'$Dollar$Model', 'single': false}
      ]
    });
  });

  isarTest('Schema test', () {
    final schemaJson = jsonDecode(SchemaTestModelSchema.schema);
    expect(
      schemaJson,
      {
        'name': 'SchemaTestModel',
        'idName': 'id',
        'properties': [
          {'name': 'boolField', 'type': 'Bool'},
          {'name': 'boolGetter', 'type': 'Bool'},
          {'name': 'boolListField', 'type': 'BoolList'},
          {'name': 'boolListGetter', 'type': 'BoolList'},
          {'name': 'byteField', 'type': 'Byte'},
          {'name': 'byteGetter', 'type': 'Byte'},
          {'name': 'bytesField', 'type': 'ByteList'},
          {'name': 'bytesField2', 'type': 'ByteList'},
          {'name': 'bytesGetter', 'type': 'ByteList'},
          {'name': 'bytesGetter2', 'type': 'ByteList'},
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
            'replace': false,
            'properties': [
              {'name': 'boolField', 'type': 'Value', 'caseSensitive': false}
            ]
          },
          {
            'name': 'boolGetter',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'boolGetter', 'type': 'Value', 'caseSensitive': false}
            ]
          },
          {
            'name': 'boolListFieldHash',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'boolListField', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'boolListFieldValue',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'boolListField', 'type': 'Value', 'caseSensitive': false}
            ]
          },
          {
            'name': 'boolListGetterHash',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'boolListGetter', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'boolListGetterValue',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'boolListGetter',
                'type': 'Value',
                'caseSensitive': false
              }
            ]
          },
          {
            'name': 'bytesField',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'bytesField', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'bytesField2',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'bytesField2', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'bytesGetter',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'bytesGetter', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'bytesGetter2',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'bytesGetter2', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'compositeField1',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
              {'name': 'boolField', 'type': 'Value', 'caseSensitive': false}
            ]
          },
          {
            'name': 'compositeField2',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
              {'name': 'boolField', 'type': 'Value', 'caseSensitive': false},
              {'name': 'intField', 'type': 'Value', 'caseSensitive': false}
            ]
          },
          {
            'name': 'compositeFieldCICI',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeField',
                'type': 'Hash',
                'caseSensitive': false
              },
              {'name': 'stringField', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'compositeFieldCICS',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeField',
                'type': 'Hash',
                'caseSensitive': false
              },
              {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'compositeFieldCSCI',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
              {'name': 'stringField', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'compositeFieldCSCS',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
              {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'compositeFieldHashed',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
              {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'compositeFieldValue',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'compositeField', 'type': 'Hash', 'caseSensitive': true},
              {'name': 'stringField', 'type': 'Value', 'caseSensitive': true}
            ]
          },
          {
            'name': 'compositeGetter1',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeGetter',
                'type': 'Hash',
                'caseSensitive': true
              },
              {'name': 'boolGetter', 'type': 'Value', 'caseSensitive': false}
            ]
          },
          {
            'name': 'compositeGetter2',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeGetter',
                'type': 'Hash',
                'caseSensitive': true
              },
              {'name': 'boolGetter', 'type': 'Value', 'caseSensitive': false},
              {'name': 'intGetter', 'type': 'Value', 'caseSensitive': false}
            ]
          },
          {
            'name': 'compositeGetterCICI',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeGetter',
                'type': 'Hash',
                'caseSensitive': false
              },
              {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'compositeGetterCICS',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeGetter',
                'type': 'Hash',
                'caseSensitive': false
              },
              {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'compositeGetterCSCI',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeGetter',
                'type': 'Hash',
                'caseSensitive': true
              },
              {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'compositeGetterCSCS',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeGetter',
                'type': 'Hash',
                'caseSensitive': true
              },
              {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'compositeGetterHashed',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeGetter',
                'type': 'Hash',
                'caseSensitive': true
              },
              {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'compositeGetterValue',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'compositeGetter',
                'type': 'Hash',
                'caseSensitive': true
              },
              {'name': 'stringGetter', 'type': 'Value', 'caseSensitive': true}
            ]
          },
          {
            'name': 'renamedField',
            'unique': true,
            'replace': false,
            'properties': [
              {'name': 'renamedField', 'type': 'Value', 'caseSensitive': false}
            ]
          },
          {
            'name': 'renamedGetter',
            'unique': true,
            'replace': true,
            'properties': [
              {'name': 'renamedGetter', 'type': 'Value', 'caseSensitive': false}
            ]
          },
          {
            'name': 'stringFieldCaseInsensitive',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringField', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'stringFieldCaseSensitive',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'stringFieldHashed',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringField', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'stringFieldValue',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringField', 'type': 'Value', 'caseSensitive': true}
            ]
          },
          {
            'name': 'stringGetterCaseInsensitive',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': false}
            ]
          },
          {
            'name': 'stringGetterCaseSensitive',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'stringGetterHashed',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringGetter', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'stringGetterValue',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringGetter', 'type': 'Value', 'caseSensitive': true}
            ]
          },
          {
            'name': 'stringListFieldCaseInsensitive',
            'unique': false,
            'replace': false,
            'properties': [
              {
                'name': 'stringListField',
                'type': 'Hash',
                'caseSensitive': false
              }
            ]
          },
          {
            'name': 'stringListFieldCaseSensitive',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringListField', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'stringListFieldHashed',
            'unique': false,
            'replace': false,
            'properties': [
              {'name': 'stringListField', 'type': 'Hash', 'caseSensitive': true}
            ]
          },
          {
            'name': 'stringListFieldHashedElements',
            'unique': false,
            'replace': false,
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
            'replace': false,
            'properties': [
              {
                'name': 'stringListField',
                'type': 'Value',
                'caseSensitive': true
              }
            ]
          }
        ],
        'links': [
          {'name': 'link', 'target': 'SchemaTestModel', 'single': true},
          {'name': 'links', 'target': 'SchemaTestModel', 'single': false},
          {'name': 'renamedLink', 'target': 'SchemaTestModel', 'single': true},
          {'name': 'renamedLinks', 'target': 'SchemaTestModel', 'single': false}
        ]
      },
    );
  });*/
}
