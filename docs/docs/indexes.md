---
title: Indexes
---

# Indexes

Indexes are Isar's most powerful feature. Many embedded databases offer "normal" indexes (if at all), but Isar also has composite and multi-entry indexes. Understanding how indexes work is essential to optimize query performance. Isar lets you choose which index you want to use and how you want to use it. We'll start with a quick introduction to what indexes are.

## What are indexes?

When a collection is unindexed, the order of the rows will likely not be discernible by the query as optimized in any way, and your query will therefore have to search through the objects linearly. In other words, the query will have to search through every object to find the ones matching the conditions. As you can imagine, that can take some time. Looking through every single object is not very efficient.

For example, this `Product` collection is entirely unordered.

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

**Data:**

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

A query that tries to find all products that cost more than €30 has to search through all nine rows. That's not an issue for nine rows, but it might become a problem for 100k rows.

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

To improve the performance of this query, we index the `price` property. An index is like a sorted lookup table:

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

**Generated index:**

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

Now, the query can be executed a lot faster. The executor can directly jump to the last three index rows and find the corresponding objects by their id.

### Sorting

Another cool thing: indexes can do super fast sorting. Sorted queries are costly because the database has to load all results in memory before sorting them. Even if you specify an offset or limit, they are applied after sorting.

Let's imagine we want to find the four cheapest products. We could use the following query:

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

In this example, the database would have to load all (!) objects, sort them by price, and return the four products with the lowest price.

As you can probably imagine, this can be done much more efficiently with the previous index. The database takes the first four rows of the index and returns the corresponding objects since they are already in the correct order.

To use the index for sorting, we would write the query like this:

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

The `.anyX()` where clause tells Isar to use an index just for sorting. You can also use a where clause like `.priceGreaterThan()` and get sorted results.

## Unique indexes

A unique index ensures the index does not contain any duplicate values. It may consist of one or multiple properties. If a unique index has one property, the values in this property will be unique. If the unique index has more than one property, the combination of values in these properties is unique.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

Any attempt to insert or update data into the unique index that causes a duplicate will result in an error:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> ok

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

// try to insert user with same username
await isar.users.put(user2); // -> error: unique constraint violated
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## Replace indexes

It is sometimes not preferable to throw an error if a unique constraint is violated. Instead, you may want to replace the existing object with the new one. This can be achieved by setting the `replace` property of the index to `true`.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

Now when we try to insert a user with an existing username, Isar will replace the existing user with the new one.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1);
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
print(await isar.user.where().findAll());
// > [{id: 2, username: 'user1' age: 30}]
```

Replace indexes also generate `putBy()` methods that allow you to update objects instead of replacing them. The existing id is reused, and links are still populated.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// user does not exist so this is the same as put()
await isar.users.putByUsername(user1);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

As you can see, the id of the first inserted user is reused.

## Case-insensitive indexes

All indexes on `String` and `List<String>` properties are case-sensitive by default. If you want to create a case-insensitive index, you can use the `caseSensitive` option:

```dart
@collection
class Person {
  Id? id;

  @Index(caseSensitive: false)
  late String name;

  @Index(caseSensitive: false)
  late List<String> tags;
}
```

## Index type

There are different types of indexes. Most of the time, you'll want to use an `IndexType.value` index, but hash indexes are more efficient.

### Value index

Value indexes are the default type and the only one allowed for all properties that don't hold Strings or Lists. Property values are used to build the index. In the case of lists, the elements of the list are used. It is the most flexible but also space-consuming of the three index types.

:::tip
Use `IndexType.value` for primitives, Strings where you need `startsWith()` where clauses, and Lists if you want to search for individual elements.
:::

### Hash index

Strings and Lists can be hashed to reduce the storage required by the index significantly. The disadvantage of hash indexes is that they can't be used for prefix scans (`startsWith` where clauses).

:::tip
Use `IndexType.hash` for Strings and Lists if you don't need `startsWith`, and `elementEqualTo` where clauses.
:::

### HashElements index

String lists can be hashed as a whole (using `IndexType.hash`), or the elements of the list can be hashed separately (using `IndexType.hashElements`), effectively creating a multi-entry index with hashed elements.

:::tip
Use `IndexType.hashElements` for `List<String>` where you need `elementEqualTo` where clauses.
:::

## Composite indexes

A composite index is an index on multiple properties. Isar allows you to create composite indexes of up to three properties.

Composite indexes are also known as multiple-column indexes.

It's probably best to start with an example. We create a person collection and define a composite index on the age and name properties:

```dart
@collection
class Person {
  Id? id;

  late String name;

  @Index(composite: [CompositeIndex('name')])
  late int age;

  late String hometown;
}
```

**Data:**

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

**Generated index:**

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

The generated composite index contains all persons sorted by their age their name.

Composite indexes are great if you want to create efficient queries sorted by multiple properties. They also enable advanced where clauses with multiple properties:

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

If you index a list using `IndexType.value`, Isar will automatically create a multi-entry index, and each item in the list is indexed toward the object. It works for all types of lists.

Practical applications for multi-entry indexes include indexing a list of tags or creating a full-text index.

```dart
@collection
class Product {
  Id? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` splits a string into words according to the [Unicode Annex #29](https://unicode.org/reports/tr29/) specification, so it works for almost all languages correctly.

**Data:**

| id  | description                  | descriptionWords             |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

Entries with duplicate words only appear once in the index.

**Generated index:**

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

This index can now be used for prefix (or equality) where clauses of the individual words of the description.

:::tip
Instead of storing the words directly, also consider using the result of a [phonetic algorithm](https://en.wikipedia.org/wiki/Phonetic_algorithm) like [Soundex](https://en.wikipedia.org/wiki/Soundex).
:::
