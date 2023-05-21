---
title: 인덱스
---

# 인덱스

인덱스는 Isar 의 가장 강력한 기능입니다. 대부분의 내장 데이터베이스는 "일반적인" 인덱스만을 제공하지만(인덱스가 있다면요), Isar 에는 복합 및 다중 항목 인덱스도 있습니다. 쿼리 성능을 최적화하려면 인덱스 작동 방식을 이해하는 것이 필수적입니다. Isar 를 사용하면 사용할 인덱스와 인덱스 사용 방법을 선택할 수 있습니다. 인덱스가 무엇인지에 대한 간단한 소개로 시작하겠습니다.

## 인덱스가 뭔가요?

컬렉션이 인덱싱되지 않은 경우, 쿼리 입장에서는 행의 순서가 전혀 최적화 되지 않은 것으로 식별되지 않을 수 있습니다. 그래서 쿼리는 객체를 선형으로 검색해야만 합니다. 즉, 쿼리는 조건과 일치하는 객체를 찾기 위해서 모든 객체를 검색해야 합니다. 예상한대로, 그건 시간이 오래 걸립니다. 모든 객체를 하나하나 훑어보는 것은 그다지 효율적이지 않습니다.

예를 들어 이 `Product` 컬렉션에는 전혀 순서가 없습니다.

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

#### 데이터:

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

가격이 30 유로 이상인 모든 제품을 찾는 쿼리는 9개 행을 모두 검색해야 합니다. 9개 행은 문제가 없지만, 10만 행이 되면 문제가 될 수 있습니다.

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

이 쿼리 성능을 개선하기 위해서 우리는 `price` 속성을 인덱스해야 합니다. 인덱스는 정렬된 룩업 테이블과 같습니다.

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

#### 생선된 인덱스:

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

이제 쿼리는 훨씬 빠르게 실행할 수 있습니다. 실행자(executor) 는 마지막 3 개의 인덱스 행으로 바로 이동해서 ID 로 해당 객체를 찾을 수 있습니다.

### 정렬

또 다른 멋진 점은 인덱스가 매우 빠른 정렬을 할 수 있다는 것입니다. 정렬된 쿼리는 정렬하기 전에 데이터베이스가 모든 결과를 메모리에 로드해야 하므로 비용이 많이 듭니다. 오프셋이나 제한을 지정하더라도 정렬 이후에 적용됩니다.

가장 싼 4개의 제품을 찾고 싶다고 가정해 보겠습니다. 다음 쿼리를 사용할 수 있습니다.

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

이 예에서 데이터베이스는 모든 (!) 객체를 로드하고 가격별로 정렬한 다음 가장 낮은 가격으로 4개의 제품을 반환해야 합니다.

예상대로, 전의 인덱스를 사용하면 훨씬 효율적으로 작업을 수행할 수 있습니다. 데이터베이스는 인덱스의 처음 4개 행을 사용하고 해당 객체가 이미 올바른 순서에 있으므로 해당 객체를 반환합니다.

정렬에 인덱스를 사용하려면 다음과 같이 쿼리를 작성합니다.

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

`.anyX()` 여기서 절은 Isar 에 정렬에만 인덱스를 사용하도록 지시합니다. `.priceGreaterThan()` 과 같은 where 절을 사용해서 정렬된 결과를 얻을 수도 있습니다.

## 고유 인덱스(Unique indexes)

고유 인덱스는 인덱스에 중복된 값이 포함되지 않게 합니다. 고유 인덱스는 하나 이상의 속성으로 이루어 집니다. 고유한 인덱스에 속성이 하나 있으면 이 속성의 값이 고유하게 됩니다(중복이 허용되지 않게 됩니다). 고유 인덱스에 둘 이상의 속성이 있는 경우 이러한 속성의 값 조합은 고유합니다.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

중복을 유발하는 데이터 삽입이나 업데이트를 시도하면 오류가 발생합니다:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> 괜찮습니다.

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

// 같은 유저 이름으로 유저 삽입을 시도
await isar.users.put(user2); // -> 에러: 고유 제약조건 위반
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## 인덱스 대체 (replace indexes)

고유 제약조건을 위반할 경우에 에러가 발생하는 것이 좋지 않을 수도 있습니다. 대신에 기존 객체를 새로운 객체로 대체할 수 있습니다. 이는 인덱스의 `replace` 속성을 `true` 로 설정해서 수행할 수 있습니다.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

이제 기존 사용자 이름을 가진 사용자를 삽입하려고 하면 Isar 가 기존 사용자를 새 사용자로 대체합니다.

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

인덱스 대체는 객체를 바꾸는 대신 업데이트할 수 있는 `putBy()` 메서드를 생성합니다. 기존 ID 는 재사용되고 링크는 여전히 채워집니다.

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

## 인덱스 유형

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

This index can now be used for prefix (or equality) where clauses of the individual words of the description.

:::tip
Instead of storing the words directly, also consider using the result of a [phonetic algorithm](https://en.wikipedia.org/wiki/Phonetic_algorithm) like [Soundex](https://en.wikipedia.org/wiki/Soundex).
:::
