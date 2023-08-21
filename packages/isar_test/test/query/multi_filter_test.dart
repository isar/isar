// ignore_for_file: inference_failure_on_function_invocation

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'multi_filter_test.g.dart';

@collection
class Model {
  Model(this.id, this.value);

  final int id;

  @Index()
  final int value;

  @override
  bool operator ==(Object other) => other is Model && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

void main() {
  group('Multi filters', () {
    late Isar isar;

    late Model model0;
    late Model model1;
    late Model model2;
    late Model model3;

    setUp(() async {
      model0 = Model(0, 0);
      model1 = Model(1, 1);
      model2 = Model(2, 2);
      model3 = Model(3, 3);

      isar = await openTempIsar([ModelSchema]);
      isar.write((isar) {
        return isar.models.putAll([model0, model1, model2, model3]);
      });
    });

    group('filter anyOf', () {
      isarTest('zero elements', () {
        final q = isar.models.where().anyOf(
          <int>[],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), isEmpty);

        final notQ = isar.models.where().not().anyOf(
          <int>[],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model2, model3]);
      });

      isarTest('one matching element', () {
        final q = isar.models.where().anyOf(
          [2],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), [model2]);

        final notQ = isar.models.where().not().anyOf(
          [2],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model3]);
      });

      isarTest('two matching elements', () {
        final q = isar.models.where().anyOf(
          [0, 2],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), [model0, model2]);

        final notQ = isar.models.where().not().anyOf(
          [0, 2],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model1, model3]);
      });

      isarTest('one non-matching element', () {
        final q = isar.models.where().anyOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), isEmpty);

        final notQ = isar.models.where().not().anyOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model2, model3]);
      });

      isarTest('one matching and one non-matching elements', () {
        final q = isar.models.where().anyOf(
          [7, 3],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), [model3]);

        final notQ = isar.models.where().not().anyOf(
          [7, 3],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model2]);
      });

      isarTest('one non-matching element', () {
        final q = isar.models.where().anyOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), isEmpty);

        final notQ = isar.models.where().not().anyOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model2, model3]);
      });
    });

    group('filter allOf', () {
      isarTest('zero elements', () {
        final q = isar.models.where().allOf(
          <int>[],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), [model0, model1, model2, model3]);

        final notQ = isar.models.where().not().allOf(
          <int>[],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), isEmpty);
      });

      isarTest('one matching element', () {
        final q = isar.models.where().allOf(
          [2],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), [model2]);

        final notQ = isar.models.where().not().allOf(
          [2],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model3]);
      });

      isarTest('two matching elements', () {
        final q = isar.models.where().allOf(
          [2, 2],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), [model2]);

        final notQ = isar.models.where().not().allOf(
          [2, 2],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model3]);
      });

      isarTest('one non-matching element', () {
        final q = isar.models.where().allOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), isEmpty);

        final notQ = isar.models.where().not().allOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model2, model3]);
      });

      isarTest('one matching and one non-matching elements', () {
        final q = isar.models.where().allOf(
          [7, 3],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), isEmpty);

        final notQ = isar.models.where().not().allOf(
          [7, 3],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model2, model3]);
      });

      isarTest('one non-matching element', () {
        final q = isar.models.where().allOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(q.findAll(), isEmpty);

        final notQ = isar.models.where().not().allOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        );
        expect(notQ.findAll(), [model0, model1, model2, model3]);
      });
    });
  });
}
