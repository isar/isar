import 'dart:convert';

import 'package:isar_test/common.dart';
import 'package:isar_test/schema_test_model.dart';
import 'package:test/expect.dart';

void main() {
  isarTest('Schema test', () {
    final schemaJson = jsonDecode(SchemaTestModelSchema.schema);
    expect(schemaJson, {
      'name': 'SchemaTestModel',
      'properties': [
        {'name': 'boolField', 'type': 'Byte'},
        {'name': 'boolGetter', 'type': 'Byte'},
        {'name': 'boolListField', 'type': 'ByteList'},
        {'name': 'boolListGetter', 'type': 'ByteList'},
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
        {'name': 'renamedField', 'type': 'Byte'},
        {'name': 'renamedGetter', 'type': 'Byte'},
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
}
