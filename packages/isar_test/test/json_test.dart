import 'package:collection/collection.dart';
import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'json_test.g.dart';

@collection
class Model {
  Model(this.id, this.jsonMap, this.jsonList, this.json, this.object);

  final int id;

  final Map<String, dynamic> jsonMap;

  final List<dynamic> jsonList;

  final dynamic json;

  final MyObject object;

  @override
  operator ==(Object other) {
    return other is Model &&
        other.id == id &&
        const DeepCollectionEquality().equals(other.jsonMap, jsonMap) &&
        const DeepCollectionEquality().equals(other.jsonList, jsonList) &&
        const DeepCollectionEquality().equals(other.json, json) &&
        other.object == object;
  }
}

class MyObject {
  MyObject(this.integer, this.string);

  factory MyObject.fromJson(Map<String, dynamic> json) {
    return MyObject(
      json['integer'] as int,
      json['string'] as String,
    );
  }

  final int integer;

  final String string;

  Map<String, dynamic> toJson() {
    return {
      'integer': integer,
      'string': string,
    };
  }

  @override
  operator ==(Object other) {
    return other is MyObject &&
        other.integer == integer &&
        other.string == string;
  }
}

void main() {
  group('JSON', () {
    late Isar isar;

    setUp(() async {
      isar = openTempIsar([ModelSchema]);
    });

    isarTest('get() put()', () {
      final model1 = Model(
        1,
        {'key': 'value'},
        ['item1', 'item2'],
        'json',
        MyObject(1, 'string'),
      );
      final model2 = Model(
        2,
        {
          'a': ['b', 4],
          'c': 'test'
        },
        ['item1', 'item2', 99, null],
        'json',
        MyObject(1, 'string'),
      );

      isar.writeTxn((isar) => isar.models.putAll([model1, model2]));
      expect(isar.models.where().findAll(), [model1, model2]);
    });
  });
}
