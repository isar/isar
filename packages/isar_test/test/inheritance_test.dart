void main() {}

/*import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'inheritance_test.g.dart';

abstract class Person {
  Person({
    required this.name,
    required this.age,
  });

  Id id = Isar.autoIncrement;

  String? name;

  @Index()
  float? age;
}

@Collection()
class Grandparent extends Person {
  Grandparent({
    required super.name,
    required super.age,
  });

  @ignore
  String? ignoredFieldGrandparent;

  final friends = IsarLinks<Friend>();

  @override
  String toString() {
    return 'Grandparent{id: $id, ignoredFieldGrandparent: 
    $ignoredFieldGrandparent, name: $name, age: $age}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Grandparent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;
}

@Collection()
class Parent extends Grandparent {
  Parent({
    required super.name,
    required super.age,
    required this.jobTitle,
  });

  String? jobTitle;

  @override
  String toString() {
    return 'Parent{id: $id, jobTitle: $jobTitle, name: $name, age: $age}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parent &&
          runtimeType == other.runtimeType &&
          jobTitle == other.jobTitle &&
          name == other.name &&
          age == other.age;
}

@Collection()
class Child extends Parent {
  Child({
    required super.name,
    required super.age,
  }) : super(jobTitle: null);

  @override
  @ignore
  // ignore: overridden_fields
  String? jobTitle;

  @override
  String toString() {
    return 'Child{id: $id, jobTitle: $jobTitle, name: $name, age: $age}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is Child &&
          runtimeType == other.runtimeType &&
          jobTitle == other.jobTitle &&
          name == other.name &&
          age == other.age;
}

@Collection()
class Grandchild extends Child {
  Grandchild({
    required super.name,
    required super.age,
    required this.birthdate,
  });

  DateTime birthdate;

  @override
  String toString() {
    return 'Grandchild{id: $id, birthdate: $birthdate, name: $name, age: $age}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is Grandchild &&
          runtimeType == other.runtimeType &&
          birthdate == other.birthdate &&
          name == other.name &&
          age == other.age;
}

@Collection(inheritance: false)
class Friend extends Parent {
  Friend({
    required this.nickname,
  }) : super(
          name: null,
          age: null,
          jobTitle: null,
        );

  @override
  // ignore: overridden_fields
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false, type: IndexType.value)
  String nickname;

  @Backlink(to: 'friends')
  final grandparentFriends = IsarLinks<Grandparent>();

  @Backlink(to: 'friends')
  final parentFriends = IsarLinks<Parent>();

  @Backlink(to: 'friends')
  final childFriends = IsarLinks<Child>();

  @Backlink(to: 'friends')
  final grandchildFriends = IsarLinks<Grandchild>();

  @Backlink(to: 'parents')
  final children = IsarLinks<FriendChild>();

  @override
  String toString() {
    return 'Friend{id: $id, nickname: $nickname}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is Friend &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nickname == other.nickname;
}

@Collection()
class FriendChild extends Friend {
  FriendChild({
    required super.nickname,
  });

  final parents = IsarLinks<Friend>();

  @override
  String toString() {
    return 'FriendChild{id: $id, nickname: $nickname}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is FriendChild &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nickname == other.nickname;
}

void main() {
  group('Inheritance', () {
    late Isar isar;

    late Grandparent grandparent0;
    late Grandparent grandparent1;
    late Grandparent grandparent2;

    late Parent parent0;
    late Parent parent1;
    late Parent parent2;

    late Child child0;
    late Child child1;
    late Child child2;
    late Child child3;
    late Child child4;

    late Grandchild grandchild0;
    late Grandchild grandchild1;
    late Grandchild grandchild2;

    late Friend friend0;
    late Friend friend1;
    late Friend friend2;
    late Friend friend3;
    late Friend friend4;

    late FriendChild friendChild0;
    late FriendChild friendChild1;
    late FriendChild friendChild2;

    setUp(() async {
      isar = await openTempIsar([
        GrandparentSchema,
        ParentSchema,
        ChildSchema,
        GrandchildSchema,
        FriendSchema,
        FriendChildSchema,
      ]);

      grandparent0 = Grandparent(name: 'Leonard', age: 101);
      grandparent1 = Grandparent(name: 'Bernard', age: 99);
      grandparent2 = Grandparent(name: 'Thomas', age: 110);

      parent0 = Parent(name: 'Rocky', age: 55, jobTitle: 'Lawyer');
      parent1 = Parent(name: 'Delbert', age: 50, jobTitle: 'Software engineer');
      parent2 = Parent(name: 'Elson', age: 49, jobTitle: 'Retail worker');

      child0 = Child(name: 'William', age: 21);
      child1 = Child(name: 'Billy', age: 24);
      child2 = Child(name: 'Patrick', age: 23);
      child3 = Child(name: 'Joe', age: 20);
      child4 = Child(name: 'Steve', age: 25);

      grandchild0 = Grandchild(
        name: 'Jake',
        age: 3,
        birthdate: DateTime(2020, 1, 5),
      );
      grandchild1 = Grandchild(
        name: 'Billie',
        age: 2,
        birthdate: DateTime(2021, 4, 22),
      );
      grandchild2 = Grandchild(
        name: 'Sydney',
        age: 1,
        birthdate: DateTime(2022, 5, 8),
      );

      friend0 = Friend(nickname: 'B.E.');
      friend1 = Friend(nickname: 'Joe');
      friend2 = Friend(nickname: 'T.K.');
      friend3 = Friend(nickname: 'S.B.');
      friend4 = Friend(nickname: 'Dude');

      friendChild0 = FriendChild(nickname: 'B.P.');
      friendChild1 = FriendChild(nickname: 'P.S.');
      friendChild2 = FriendChild(nickname: 'B.A.');

      await isar.tWriteTxn(
        () => Future.wait([
          isar.grandparents.tPutAll([grandparent0, grandparent1, grandparent2]),
          isar.parents.tPutAll([parent0, parent1, parent2]),
          isar.childs.tPutAll([child0, child1, child2, child3, child4]),
          isar.grandchilds.tPutAll([grandchild0, grandchild1, grandchild2]),
          isar.friends.tPutAll([friend0, friend1, friend2, friend3, friend4]),
          isar.friendChilds.tPutAll([friendChild0, friendChild1, friendChild2]),
        ]),
      );

      grandparent0.friends.add(friend0);
      // FIXME: Should adding child inheriting the target collection to link be allowed?
      grandparent0.friends.add(friendChild0);
      grandparent1.friends.addAll([friend1, friend2]);
      grandparent2.friends.addAll([friendChild2, friend2]);

      parent0.friends.addAll([friend2]);
      parent1.friends.addAll([friend3]);
      parent2.friends.addAll([]);

      child0.friends.addAll([friend0, friend1, friend3]);
      child1.friends.add(friend3);
      child2.friends.addAll([friend4, friend1]);

      grandchild0.friends.addAll([friend0, friendChild1]);
      grandchild1.friends.addAll([friendChild0]);
      grandchild2.friends.addAll([friend3, friend4]);

      friendChild0.parents.addAll([friend1, friend2]);
      friendChild1.parents.addAll([friend2, friend0]);
      friendChild2.parents.addAll([friend4, friend3]);

      friendChild0.friends.addAll([friend0]);
      friendChild1.friends.addAll([friend1]);
      friendChild2.friends.addAll([friend0, friend3]);

      await isar.tWriteTxn(
        () => Future.wait([
          grandparent0.friends.tSave(),
          grandparent1.friends.tSave(),
          grandparent2.friends.tSave(),
          parent0.friends.tSave(),
          parent1.friends.tSave(),
          parent2.friends.tSave(),
          child0.friends.tSave(),
          child1.friends.tSave(),
          child2.friends.tSave(),
          grandchild0.friends.tSave(),
          grandchild1.friends.tSave(),
          grandchild2.friends.tSave(),
          friendChild0.parents.tSave(),
          friendChild1.parents.tSave(),
          friendChild2.parents.tSave(),
          friendChild0.friends.tSave(),
          friendChild1.friends.tSave(),
          friendChild2.friends.tSave(),
        ]),
      );
    });

    tearDown(() => isar.close());

    isarTest('Query grandparent', () async {
      expect(
        GrandparentSchema.propertyIds.containsKey('ignoredFieldGrandparent'),
        false,
      );

      await qEqual(
        isar.grandparents.where().ageGreaterThan(100).tFindAll(),
        [grandparent0, grandparent2],
      );

      await qEqual(
        isar.grandparents.filter().nameContains('ard').tFindAll(),
        [grandparent0, grandparent1],
      );

      await qEqual(
        isar.grandparents
            .where()
            .ageLessThan(100)
            .filter()
            .nameStartsWith('Bern')
            .tFindAll(),
        [grandparent1],
      );

      await qEqual(
        isar.grandparents.filter().nameEndsWith('rd').tFindAll(),
        [grandparent0, grandparent1],
      );

      await qEqual(
        isar.grandparents.where().distinctByAge().tFindAll(),
        [grandparent0, grandparent1, grandparent2],
      );

      await qEqual(
        isar.grandparents.where().sortByNameDesc().tFindAll(),
        [grandparent2, grandparent0, grandparent1],
      );
    });

    isarTest('Query parent', () async {
      expect(
        ParentSchema.propertyIds.containsKey('ignoredFieldGrandparent'),
        false,
      );

      await qEqual(
        isar.parents.where().ageLessThan(50, include: true).tFindAll(),
        [parent2, parent1],
      );

      await qEqual(
        isar.parents.where().ageEqualTo(49).tFindAll(),
        [parent2],
      );

      await qEqual(
        isar.parents.where().ageIsNull().tFindAll(),
        [],
      );

      await qEqual(
        isar.parents
            .filter()
            .nameContains('e', caseSensitive: false)
            .tFindAll(),
        [parent1, parent2],
      );

      await qEqual(
        isar.parents.filter().nameStartsWith('n').tFindAll(),
        [],
      );

      await qEqual(
        isar.parents.filter().nameEndsWith('n').tFindAll(),
        [parent2],
      );

      await qEqual(
        isar.parents
            .filter()
            .jobTitleStartsWith('soft', caseSensitive: false)
            .tFindAll(),
        [parent1],
      );

      await qEqual(
        isar.parents.filter().jobTitleEndsWith('er').tFindAll(),
        [parent0, parent1, parent2],
      );

      await qEqual(
        isar.parents
            .filter()
            .jobTitleContains('WARE', caseSensitive: false)
            .tFindAll(),
        [parent1],
      );

      await qEqual(
        isar.parents.where().anyAge().tFindAll(),
        [parent2, parent1, parent0],
      );

      await qEqual(
        isar.parents.where().sortByNameDesc().tFindAll(),
        [parent0, parent2, parent1],
      );

      await qEqual(
        isar.parents.where().sortByJobTitleDesc().tFindAll(),
        [parent1, parent2, parent0],
      );
    });

    isarTest('Query child', () async {
      expect(
        ChildSchema.propertyIds.containsKey('ignoredFieldGrandparent'),
        false,
      );

      // FIXME: overriding a property and adding @ignore to it is not working
      // Query methods are also generated for the ignored property
      expect(
        ChildSchema.propertyIds.containsKey('jobTitle'),
        false,
      );

      await qEqual(
        isar.childs.where().ageEqualTo(101).tFindAll(),
        [],
      );

      await qEqual(
        isar.childs.where().ageEqualTo(55).tFindAll(),
        [],
      );

      await qEqual(
        isar.childs.where().ageEqualTo(20).tFindAll(),
        [child3],
      );

      await qEqual(
        isar.childs.where().ageGreaterThan(22).tFindAll(),
        [child2, child1, child4],
      );

      await qEqual(
        isar.childs.where().ageIsNull().tFindAll(),
        [],
      );

      await qEqual(
        isar.childs.where().ageLessThan(21, include: true).tFindAll(),
        [child3, child0],
      );

      await qEqual(
        isar.childs.filter().nameContains('ll').tFindAll(),
        [child0, child1],
      );

      await qEqual(
        isar.childs
            .filter()
            .nameStartsWith('p', caseSensitive: false)
            .tFindAll(),
        [child2],
      );

      await qEqual(
        isar.childs.filter().nameEndsWith('e').tFindAll(),
        [child3, child4],
      );

      await qEqual(
        isar.childs.where().anyAge().tFindAll(),
        [child3, child0, child2, child1, child4],
      );

      await qEqual(
        isar.childs.where().sortByAgeDesc().tFindAll(),
        [child4, child1, child2, child0, child3],
      );

      await qEqual(
        isar.childs.where().sortByNameDesc().tFindAll(),
        [child0, child4, child2, child3, child1],
      );
    });

    isarTest('Query grandchild', () async {
      expect(
        GrandchildSchema.propertyIds.containsKey('ignoredFieldGrandparent'),
        false,
      );

      // FIXME: Same as 'Query child' test
      expect(
        GrandchildSchema.propertyIds.containsKey('jobTitle'),
        false,
      );

      await qEqual(
        isar.grandchilds.where().ageEqualTo(49).tFindAll(),
        [],
      );

      await qEqual(
        isar.grandchilds.where().ageEqualTo(25).tFindAll(),
        [],
      );

      await qEqual(
        isar.grandchilds.where().ageIsNull().tFindAll(),
        [],
      );

      await qEqual(
        isar.grandchilds.where().ageGreaterThan(2).tFindAll(),
        [grandchild0],
      );

      await qEqual(
        isar.grandchilds.where().ageGreaterThan(2, include: true).tFindAll(),
        [grandchild1, grandchild0],
      );

      await qEqual(
        isar.grandchilds.where().ageEqualTo(1).tFindAll(),
        [grandchild2],
      );

      await qEqual(
        isar.grandchilds
            .filter()
            .nameStartsWith('bI', caseSensitive: false)
            .tFindAll(),
        [grandchild1],
      );

      await qEqual(
        isar.grandchilds.filter().nameEndsWith('ey').tFindAll(),
        [grandchild2],
      );

      await qEqual(
        isar.grandchilds.filter().nameEqualTo('Joe').tFindAll(),
        [],
      );

      await qEqual(
        isar.grandchilds
            .filter()
            .birthdateGreaterThan(DateTime(2021))
            .tFindAll(),
        [grandchild1, grandchild2],
      );

      await qEqual(
        isar.grandchilds
            .filter()
            .birthdateEqualTo(DateTime(2020, 1, 5))
            .tFindAll(),
        [grandchild0],
      );
    });

    isarTest('Query friend', () async {
      expect(FriendSchema.propertyIds.containsKey('name'), false);
      expect(FriendSchema.propertyIds.containsKey('age'), false);
      expect(FriendSchema.propertyIds.containsKey('jobTitle'), false);
      expect(
        FriendSchema.propertyIds.containsKey('ignoredFieldGrandparent'),
        false,
      );
      expect(FriendSchema.propertyIds.containsKey('nickname'), true);

      // FIXME: Query of parent properties are generated even tough `inheritance: false`
      // Crash with `IsarError: Unknown property "property"` if those methods
      // are used.

      await qEqual(
        isar.friends.where().nicknameStartsWith('jO').tFindAll(),
        [friend1],
      );

      await qEqual(
        isar.friends.where().nicknameEqualTo('Dude').tFindAll(),
        [friend4],
      );

      await qEqual(
        isar.friends.where().nicknameGreaterThan('Joe').tFindAll(),
        [friend3, friend2],
      );

      await qEqual(
        isar.friends.where().anyNickname().tFindAll(),
        [friend0, friend4, friend1, friend3, friend2],
      );

      /*
      FIXME: Loading backlinks crashes with
      'IsarError: IllegalArg: Link target collection does not match query 
      collection.'
      await Future.wait([
        for (final friend in [friend0, friend1, friend0]) ...[
          friend.grandparentFriends.load(),
          friend.parentFriends.load(),
          friend.childFriends.load(),
          friend.grandchildFriends.load(),
        ],
      ]);

      TODO(jtplouffe): Implement more link tests on inheritance collections once
      backlinking works.
      */
    });

    isarTest('Query friendChild', () async {
      // FIXME: A collection inheriting from a collection that is
      // `inheritance: false` will still inherit all the properties
      // from his parent's parent.
      // Is this case, `FriendChild` still has `Parent` properties, even
      // if `Friend` (being `FriendChild`'s parent) is `inheritance: false`.
      expect(FriendChildSchema.propertyIds.containsKey('name'), false);
      expect(FriendChildSchema.propertyIds.containsKey('age'), false);
      expect(FriendChildSchema.propertyIds.containsKey('jobTitle'), false);
      expect(
        FriendChildSchema.propertyIds.containsKey('ignoredFieldGrandparent'),
        false,
      );
      expect(FriendChildSchema.propertyIds.containsKey('nickname'), true);

      await qEqual(
        isar.friendChilds.where().nicknameEqualTo('Dude').tFindAll(),
        [],
      );

      await qEqual(
        isar.friendChilds.where().nicknameEqualTo('P.S.').tFindAll(),
        [friendChild1],
      );

      await qEqual(
        isar.friendChilds.where().nicknameStartsWith('B.').tFindAll(),
        [friendChild2, friendChild0],
      );

      await qEqual(
        isar.friendChilds.where().nicknameBetween('D', 'X').tFindAll(),
        [friendChild1],
      );

      await qEqual(
        isar.friendChilds
            .where()
            .nicknameStartsWith('B.A')
            .idProperty()
            .tFindAll(),
        [friendChild2.id],
      );

      await isar.tWriteTxn(
        () => Future.wait([
          friendChild0.parents.load(),
          friendChild1.parents.load(),
          friendChild2.parents.load(),
        ]),
      );

      expect(friendChild0.parents, {friend1, friend2});
      expect(friendChild1.parents, {friend2, friend0});
      expect(friendChild2.parents, {friend4, friend3});

      // TODO(jtplouffe): Implement more link tests on inheritance collections once backlinking works.
    });
  });
}
*/
