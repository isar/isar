import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'group_test.g.dart';

@collection
class Model {
  Model(this.id, this.name, this.age);

  final int id;

  String? name;

  int? age = 0;

  @override
  String toString() {
    return '{name: $name, age: $age, }';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    // ignore: test_types_in_equals
    return other is Model && name == other.name && age == other.age;
  }
}

void main() {
  group('Filter Groups', () {
    late Isar isar;
    late IsarCollection<int, Model> users;

    late Model david;
    late Model emma;
    late Model tina;
    late Model simon;
    late Model bjorn;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
      users = isar.models;

      david = Model(0, 'David', 20);
      emma = Model(1, 'Emma', 30);
      tina = Model(2, 'Tina', 40);
      simon = Model(3, 'Simon', 30);
      bjorn = Model(4, 'Bjorn', 40);

      isar.write((isar) {
        isar.models.putAll([david, emma, tina, simon, bjorn]);
      });
    });

    isarTest('Simple or', () {
      expect(
        users.where().ageEqualTo(20).or().ageEqualTo(30).findAll(),
        [david, emma, simon],
      );
    });

    isarTest('Simple and', () {
      expect(
        users.where().ageEqualTo(40).and().idEqualTo(4).findAll(),
        [bjorn],
      );
    });

    isarTest('Or followed by and', () {
      expect(
        users
            .where()
            .ageEqualTo(20)
            .or()
            .ageEqualTo(30)
            .and()
            .nameEqualTo('Emma')
            .findAll(),
        [david, emma],
      );
    });

    isarTest('And followed by or', () {
      expect(
        users
            .where()
            .ageEqualTo(30)
            .and()
            .nameEqualTo('Simon')
            .or()
            .ageEqualTo(20)
            .findAll(),
        [david, simon],
      );
    });

    isarTest('Or followed by group', () {
      expect(
        users
            .where()
            .ageEqualTo(20)
            .or()
            .group((q) => q.ageEqualTo(30).and().nameEqualTo('Emma'))
            .findAll(),
        [david, emma],
      );
    });

    isarTest('And followed by group', () {
      expect(
        users
            .where()
            .ageEqualTo(30)
            .and()
            .group((q) => q.nameEqualTo('Simon').or().ageEqualTo(20))
            .findAll(),
        [simon],
      );
    });

    isarTest('Nested groups', () {
      expect(
        users
            .where()
            .group(
              (QueryBuilder<Model, Model, QFilterCondition> q) => q
                  .nameEqualTo('Simon')
                  .or()
                  .group((q) => q.ageEqualTo(30).or().ageEqualTo(20)),
            )
            .findAll(),
        [david, emma, simon],
      );
    });
  });
}
