---
title: Indexes
---

# Indexes

Indexes are Isars most powerful feature. Many embedded databases offer "normal" indexes (if at all). Understanding how indexes work is essential to optimize query performance. Isar lets you choose which index you want to use and how you want to use it. We'll start with a quick introduction what indexes are.

## What are indexes?

When a collection is unindexed, the order of the rows will likely not be discernible by the query as optimized in any way, and your query will therefore have to search through the objects linearly. In other words, the query will have to search through every object to find the ones matching the conditions. As you can imagine, that can take a long time. Looking through every single object is not very efficient.

For example, this `Product` collection is completely unordered.

```dart
@Collection()
class Product {
  int? id;

  late String name;

  late int price;
}
```

#### Data:

| id  | name      | price |
| --- | --------- | ----- |
| 1   | Book      | 15    |
| 2   | Table     | 55    |
| 3   | Chair     | 25    |
| 4   | Pencil    | 3     |
| 5   | Lightbulb | 12    |
| 6   | Carpet    | 60    |
| 7   | Pillow    | 30    |
| 8   | Computer  | 650   |
| 9   | Soap      | 2     |

A query that tries to find all products that cost more than €30 has to search through all nine rows. That's not an issue for nine rows but it will become a problem for 100k rows.

```dart
final expensiveProducts = await isar.products..filter()
  .priceGreaterThan(30)
  .findAll();
```

To improve the performance of this query we index the `price` property. An index is like a sorted lookup table:

```dart
@Collection()
class Product {
  int? id;

  late String name;

  @Index()
  late int price;
}
```

#### Generated index:

| price                | id                 |
| -------------------- | ------------------ |
| 2                    | 9                  |
| 3                    | 4                  |
| 12                   | 5                  |
| 15                   | 1                  |
| 25                   | 3                  |
| 30                   | 7                  |
| <mark>**55**</mark>  | <mark>**2**</mark> |
| <mark>**60**</mark>  | <mark>**6**</mark> |
| <mark>**650**</mark> | <mark>**8**</mark> |

Now the query can be executed a lot faster. The executer can directly jump to the last three index rows and find the corresponding objects by their id.

### Sorting

Another cool thing indexes can do is super fast sorting. Sorted queries are very expensive because the database has to load all results in memory before sorting them. Even if you specify an offset or limit because they are applied after sorting.

Let's imagine we want to find the four cheapest products. We could use the following query:

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

In this example the database would have to load all (!) objects, sort them by price and return the four products with the lowest price.

As you can probably imagine, this can be done a lot more efficient with the index from before. The database takes the first four rows of the index and returns the corresponding objects since they are already in the correct order.

To use the index for sorting we would write the query like this:

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

The `.anyX()` where clause tells Isar to use an index just for sorting. You can also use a where clause like `.priceGreaterThan()` and still get sorted results.

## Index type

There are different types of indexes. Most of the time you'll want to use a `IndexType.value` index.

### Value index

This is the default type and also the only allowed type for all properties that don't hold Strings or Lists. Property values are used to build the index. In case of lists, the elements of the list are used. It is the most flexible but also space consuming of the three index types.

:::tip
Use `IndexType.value` for primitives, Strings where you need `startsWith` where clauses and Lists if you want to search for individual elements.
:::

### Hash index

Strings and Lists can be hashed to reduce the storage required by the index. The disadvantage of hash indexes is that they can't be used for prefix scans (`startsWith` where clauses).

:::tip
Use `IndexType.hash` for Strings and lists if you don't need `startsWith` and `anyEqualTo` where clauses.
:::

### HashElements index

String lists can either be hashed completely (using `IndexType.hash`) or the elements of the list can be hashed (using `IndexType.hashElements`) effectively creating a multi-entry index with hashed elements.

:::tip
Use `IndexType.hashElements` for `List<String>` where you need `anyEqualTo` where clauses.
:::

## Composite indexes

A composite index is an index on multiple properties. Isar allows you to create composite indexes that consist of up to three properties.

Composite indexes are also known as a multiple-column indexes.

It's probably best to start with an example. We create a person collection and define a composite index on the age and name properties:

```dart
@Collection()
class Person {
  int? id;

  late String name;

  @Index(composite: [CompositeIndex('name')])
  late int age;

  late String hometown;
}
```

#### Data:

| id  | name   | age | hometown  |
| --- | ------ | --- | --------- |
| 1   | Daniel | 20  | Berlin    |
| 2   | Anne   | 20  | Paris     |
| 3   | Carl   | 24  | San Diego |
| 4   | Simon  | 24  | Munich    |
| 5   | David  | 20  | New York  |
| 6   | Carl   | 24  | London    |
| 7   | Audrey | 30  | Prague    |
| 8   | Anne   | 24  | Paris     |

#### Generated index

| age | name   | id  |
| --- | ------ | --- |
| 20  | Anne   | 2   |
| 20  | Daniel | 1   |
| 20  | David  | 5   |
| 24  | Anne   | 8   |
| 24  | Carl   | 3   |
| 24  | Carl   | 6   |
| 24  | Simon  | 4   |
| 30  | Audrey | 7   |

The generated composite index contains all persons sorted by their age and then by their name.

Obviously composite indexes are great if you want to create efficient queries that are sorted by multiple properties.

But composite indexes also allow advanced where clauses with multiple properties:

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

The last property of a composite index also supports conditions like `startsWith()` or `lessThan()`:

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## Multi-entry indexes

If you index a list using `IndexType.value`, Isar will automatically create a multi-entry index and each item in the array is indexed towards the object. It works for all types of lists.

Useful applications for multi-entry indexes are for example to index a list of tags or to create a full text index.

```dart
@Collection()
class Product {
  int? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` splits a string into words according to the [Unicode Annex #29](https://unicode.org/reports/tr29/) specification so it works for almost all languages correctly.

#### Data:

| id  | description                  | descriptionWords             |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

Entries with duplicate words only appear once in the index.

#### Generated index

| descriptionWords | id        |
| ---------------- | --------- |
| comfortable      | [1, 2]    |
| blue             | 1         |
| necktie          | 4         |
| plain            | 3         |
| pullover         | 2         |
| red              | [2, 3, 4] |
| super            | 4         |
| t-shirt          | [1, 3]    |

This index can now be used for prefix (or equality) where clauses on the individual words of the description.

:::tip
Instead of storing the words directly, you can also use the result of a [phonectic algorithm](https://en.wikipedia.org/wiki/Phonetic_algorithm) like [Soundex](https://en.wikipedia.org/wiki/Soundex).
:::

## Unique indexes

A unique index ensures the index does not contain any duplicate values. It may consist of one or multiple properties. If a unique index has one property, the values in this property will be unique. In case the unique index has multiple properties, the combination of values in these properties is unique.

```dart
@Collection()
class User {
  int? id;

  @Index(unique: true)
  late String username;
}
```

Any attempt to insert or update data into the unique index that causes a duplicate will result in an error. There is an option however to replace existing entries instead of failing:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1';

await isar.users.put(user1); // -> ok

final user2 = User()
  ..id = 2;
  ..username = 'user1';

// try to insert user with same username
await isar.users.put(user2); // -> error: unique constraint violated
print(await isar.user.where().findAll()); // -> [user1]

// replace user1 with user2
await isar.users.put(user2, replaceOnConflict: true); // -> ok
print(await isar.user.where().findAll()); // -> [user2]
```

## Case-insensitive indexes

By default, all indexes on `String` and `List<String>` properties are case-sensitive. This means that the index will only contain entries where the property value is exactly the same as the index value. If you want to create a case-insensitive index, you can use the `caseSensitive` option:

```dart
@Collection()
class Person {
  int? id;

  @Index(caseSensitive: false)
  late String name;

  @Index(caseSensitive: false)
  late List<String> tags;
}
```
