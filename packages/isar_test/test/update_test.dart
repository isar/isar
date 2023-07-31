// ignore_for_file: avoid_redundant_argument_values

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'update_test.g.dart';

const _default = Object();

@collection
class Model {
  Model({
    required this.id,
    required this.boolProp,
    required this.nullableBoolProp,
    required this.byteProp,
    required this.shortProp,
    required this.longProp,
    required this.floatProp,
    required this.doubleProp,
    required this.stringProp,
    required this.nullableStringProp,
    required this.dateProp,
  });

  final int id;

  final bool boolProp;

  final bool? nullableBoolProp;

  final byte byteProp;

  final short shortProp;

  final int longProp;

  final float floatProp;

  final double doubleProp;

  final String stringProp;

  final String? nullableStringProp;

  final DateTime dateProp;

  @override
  bool operator ==(Object other) =>
      other is Model &&
      other.id == id &&
      other.boolProp == boolProp &&
      other.byteProp == byteProp &&
      other.shortProp == shortProp &&
      other.longProp == longProp &&
      other.floatProp == floatProp &&
      other.doubleProp == doubleProp &&
      other.stringProp == stringProp &&
      other.nullableStringProp == nullableStringProp &&
      other.dateProp == dateProp;

  Model copyWith({
    Object boolProp = _default,
    Object? nullableBoolProp = _default,
    Object byteProp = _default,
    Object shortProp = _default,
    Object longProp = _default,
    Object floatProp = _default,
    Object doubleProp = _default,
    Object stringProp = _default,
    Object? nullableStringProp = _default,
    Object dateProp = _default,
  }) {
    return Model(
      id: id,
      boolProp: boolProp == _default ? this.boolProp : boolProp as bool,
      nullableBoolProp: nullableBoolProp == _default
          ? this.nullableBoolProp
          : nullableBoolProp as bool?,
      byteProp: byteProp == _default ? this.byteProp : byteProp as byte,
      shortProp: shortProp == _default ? this.shortProp : shortProp as short,
      longProp: longProp == _default ? this.longProp : longProp as int,
      floatProp: floatProp == _default ? this.floatProp : floatProp as float,
      doubleProp:
          doubleProp == _default ? this.doubleProp : doubleProp as double,
      stringProp:
          stringProp == _default ? this.stringProp : stringProp as String,
      nullableStringProp: nullableStringProp == _default
          ? this.nullableStringProp
          : nullableStringProp as String?,
      dateProp: dateProp == _default ? this.dateProp : dateProp as DateTime,
    );
  }
}

void main() {
  group('Update', () {
    late Isar isar;
    late Model model;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      model = Model(
        id: 12,
        boolProp: true,
        nullableBoolProp: false,
        byteProp: 1,
        shortProp: 2,
        longProp: 3,
        floatProp: 4,
        doubleProp: 5,
        stringProp: 'hello',
        nullableStringProp: 'world',
        dateProp:
            DateTime.fromMillisecondsSinceEpoch(200, isUtc: true).toLocal(),
      );
      isar.write((isar) => isar.models.put(model));
    });

    group('update()', () {
      isarTest('bool change', () {
        isar.write((isar) {
          expect(isar.models.update(id: model.id, boolProp: false), true);
        });
        expect(isar.models.get(model.id), model.copyWith(boolProp: false));
      });

      isarTest('bool change to null', () {
        isar.write((isar) {
          expect(
            isar.models.update(id: model.id, nullableBoolProp: null),
            true,
          );
        });
        expect(
          isar.models.get(model.id),
          model.copyWith(nullableBoolProp: null),
        );
      });

      isarTest('byte change', () {
        isar.write((isar) {
          expect(isar.models.update(id: model.id, byteProp: 2), true);
        });
        expect(isar.models.get(model.id), model.copyWith(byteProp: 2));
      });

      isarTest('short change', () {
        isar.write((isar) {
          expect(isar.models.update(id: model.id, shortProp: 3), true);
        });
        expect(isar.models.get(model.id), model.copyWith(shortProp: 3));
      });

      isarTest('long change', () {
        isar.write((isar) {
          expect(isar.models.update(id: model.id, longProp: 4), true);
        });
        expect(isar.models.get(model.id), model.copyWith(longProp: 4));
      });

      isarTest('float change', () {
        isar.write((isar) {
          expect(isar.models.update(id: model.id, floatProp: 5), true);
        });
        expect(isar.models.get(model.id), model.copyWith(floatProp: 5));
      });

      isarTest('double change', () {
        isar.write((isar) {
          expect(isar.models.update(id: model.id, doubleProp: 6), true);
        });
        expect(isar.models.get(model.id), model.copyWith(doubleProp: 6));
      });

      isarTest('string change', () {
        isar.write((isar) {
          expect(isar.models.update(id: model.id, stringProp: 'world'), true);
        });
        expect(isar.models.get(model.id), model.copyWith(stringProp: 'world'));

        isar.write((isar) {
          expect(isar.models.update(id: model.id, stringProp: ''), true);
        });
        expect(isar.models.get(model.id), model.copyWith(stringProp: ''));

        isar.write((isar) {
          expect(isar.models.update(id: model.id, stringProp: 'loooong'), true);
        });
        expect(
          isar.models.get(model.id),
          model.copyWith(stringProp: 'loooong'),
        );
      });

      isarTest('nullable string change', () {
        isar.write((isar) {
          expect(
            isar.models.update(id: model.id, nullableStringProp: null),
            true,
          );
        });
        expect(
          isar.models.get(model.id),
          model.copyWith(nullableStringProp: null),
        );

        isar.write((isar) {
          expect(
            isar.models.update(id: model.id, nullableStringProp: 'testaaaa'),
            true,
          );
        });
        expect(
          isar.models.get(model.id),
          model.copyWith(nullableStringProp: 'testaaaa'),
        );
      });

      isarTest('date change', () {
        isar.write((isar) {
          expect(
            isar.models.update(
              id: model.id,
              dateProp: DateTime.fromMillisecondsSinceEpoch(300, isUtc: true),
            ),
            true,
          );
        });

        expect(
          isar.models.get(model.id),
          model.copyWith(
            dateProp:
                DateTime.fromMillisecondsSinceEpoch(300, isUtc: true).toLocal(),
          ),
        );
      });
    });
  });
}
