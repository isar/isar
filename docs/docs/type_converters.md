---
title: Type Converters
---

# Type Converters

Isar only supports storing basic `database types` like numbers and lists but you can use type converters to use other `Dart types` like Enums with Isar.

## Creating a `TypeConverter`

Let's assume we want to store the following enum in Isar:

```dart
enum Relationship {
  single,
  married,
  itIsComplicated,
}
```

Writing a converter is easy, just map the enum to a supported type. For enums it is recommended to use the enum index for mapping.

```dart
class RelationshipConverter extends TypeConverter<Relationship, int> {
  const RelationshipConverter(); // Converters need to have an empty const constructor

  @override
  Relationship fromIsar(int relationshipIndex) {
    return Relationship.values[relationshipIndex];
  }

  @override
  int toIsar(Relationship relationship) {
    return relationship.index;
  }
}
```

As you can see, just two methods are required. `fromIsar()` converts the database value to the Dart representation and `toIsar()` does the opposite.

## Using a `TypeConverter`

Once you created a type adapter, the hardest part is done. Using `TypeAdapters` is super easy. Just annotate the fields you want to convert and you're done.

```dart
@Collection()
class Person {
  int? id;

  late String name;

  @RelationshipConverter()
  late Relationship relationship;
}
```

Now let's try to query all the people in our database that are married:

```dart
final marriedPersons = await isar.persons
  .where()
  .filter()
  .relationshipEqualTo(Relationship.married)
  .findAll();
```

There is only one very important thing to keep in mind: You may change the converter for an existing field but the `database type` **MUST BE THE SAME**. Otherwise the schema migration will fail.
