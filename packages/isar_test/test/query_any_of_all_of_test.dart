// ignore_for_file: inference_failure_on_function_invocation

import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'query_any_of_all_of_test.g.dart';

@Collection()
class Model {
  Model(this.id, this.value);
  final int id;

  @Index()
  final int value;

  @override
  operator @override
  bool ==(Object other) => other is Model && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

void main() {
  testSyncAsync(tests);
}

void tests() {
  group('AnyOf AllOf', () {
    late Isar isar;

    late Model model0;
    late Model model1;
    late Model model2;
    late Model model3;

    Future<void> setupModels() async {
      model0 = Model(0, 0);
      model1 = Model(1, 1);
      model2 = Model(2, 2);
      model3 = Model(3, 3);
      isar = await openTempIsar([ModelSchema]);
      await isar.writeTxn(() {
        return isar.models.putAll([model0, model1, model2, model3]);
      });
    }

    group('where anyOf', () {
      setUp(setupModels);

      tearDown(() => isar.close());

      isarTest('zero elements', () async {
        final one = isar.models.where().anyOf(
          <int>[],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, [model0, model1, model2, model3]);
      });

      isarTest('one matching element', () async {
        final one = isar.models.where().anyOf(
          [2],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, [model2]);
      });

      isarTest('one non-matching element', () async {
        final one = isar.models.where().anyOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, []);
      });

      isarTest('one matching and one non-matching elements', () async {
        final one = isar.models.where().anyOf(
          [7, 3],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, [model3]);
      });

      isarTest('one non-matching element', () async {
        final one = isar.models.where().anyOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, []);
      });
    });

    group('filter anyOf', () {
      setUp(setupModels);

      tearDown(() => isar.close());

      isarTest('zero elements', () async {
        final one = isar.models.filter().anyOf(
          <int>[],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, [model0, model1, model2, model3]);
      });

      isarTest('one matching element', () async {
        final one = isar.models.filter().anyOf(
          [2],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, [model2]);
      });

      isarTest('one non-matching element', () async {
        final one = isar.models.filter().anyOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, []);
      });

      isarTest('one matching and one non-matching elements', () async {
        final one = isar.models.filter().anyOf(
          [7, 3],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, [model3]);
      });

      isarTest('one non-matching element', () async {
        final one = isar.models.filter().anyOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, []);
      });
    });

    group('filter allOf', () {
      setUp(setupModels);

      tearDown(() => isar.close());

      isarTest('zero elements', () async {
        final one = isar.models.filter().allOf(
          <int>[],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, [model0, model1, model2, model3]);
      });

      isarTest('one matching element', () async {
        final one = isar.models.filter().allOf(
          [2],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, [model2]);
      });

      isarTest('one non-matching element', () async {
        final one = isar.models.filter().allOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, []);
      });

      isarTest('one matching and one non-matching elements', () async {
        final one = isar.models.filter().allOf(
          [7, 3],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, []);
      });

      isarTest('one non-matching element', () async {
        final one = isar.models.filter().allOf(
          [5],
          (q, int element) => q.valueEqualTo(element),
        ).findAll();
        await qEqual(one, []);
      });
    });
  });
}
