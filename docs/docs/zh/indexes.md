---
title: 索引
---

# 索引（Index）

索引是 Isar 最重要的功能。所有嵌入式数据库都提供了“普通”索引功能（如果有的话），但是 Isar 支持组合搜索引和多条目索引。理解索引的工作原理是优化查询性能的基本前提。你可以选择使用哪种索引以及如何使用它们。我们先从索引的简介开始。

## 什么是索引？

当一个 Collection 未被索引时，数据行的顺序很大可能无法被查询所识别，也就无从优化查询性能。因此查询不得不线性地搜索所有对象。也就是说，必须对每个对象进行查询，看它是否符合查询条件。你可以想象，这会耗费不少时间。对每个对象进行查询不是很高效。

举例来说，这个 `Product` Collection 是完全无序的。

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

**数据：**

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

如果要找出价格超过 30 欧元的商品时，就需要查询 9 行数据。虽然 9 行数据不多问题不大，但是如果需要查询十万行那就是很大的问题了。

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

为了改善查询性能，我们对 `price` 属性进行了索引。一个索引就像是一张有序的查询表：

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

**生成的索引表:**

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

现在查询就会快多了。Isar 会直接从底下三行通过 Id 找出它们对应的对象。

### 排序

另一个比较酷的是：索引支持超快的排序。对查询结果排序往往很耗性能，因为数据库必须加载所有的数据，将它们暂时放在内存，然后对它们排序。即使你指定了偏移量或限制，但它俩是在排序完成后才会被执行的。

假定我们想要找出四个最便宜的商品。我们可以使用下方查询代码：

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

在这个例子中，数据库必须加载所有（！）商品数据，按照价格给它们排序，然后返回四个价格最低的商品。

你或许会想到，用之前的索引来做应该会更高效。数据库直接读取索引表的前四行，然后返回它们所对应的商品数据，因为索引表默认是已经按照索引属性的大小顺序排好了的。

我们通过下方代码来实现：

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

这个 `.anyX()` Where 子句告诉 Isar 索引只是用来排序。你同样也可以使用如 `.priceGreaterThan()` 这样的 Where 子句来获取相同结果。

## 唯一索引

唯一索引能保证索引不含重复的值。它可以由一个或多个属性构成。如果一个唯一索引仅包含一个属性，那么其对应的属性值就是唯一的。如果唯一索引由多个属性构成，那这些属性值的组合是唯一的。

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

所有对唯一索引会造成数据重复的写入操作都会造成错误：

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> 没问题

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

// 试着写入一个和上面相同用户名的用户数据
await isar.users.put(user2); // -> 错误：违反了唯一性约束
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## 替换索引

有时候你可能不愿抛出唯一性约束错误，而是想要用新数据覆盖掉原有数据。那么你可以将对应属性的索引设置为 `replace: true` 来实现。

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

现在如果我们试着插入一个同用户名的用户数据，Isar 会直接使用新数据覆盖原有数据（这里的原有数据 user1 被新数据 user2 覆盖了，因为属性 username 必须是唯一的）。

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

替换索引也提供了 `putBy()` 方法，允许你只更新对象数据，而不是直接覆盖它们。那么现有的 Id 将会被复用，所有关联也会被保留。

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// user1 是第一次被写入数据库，因此这里效果等同于 put() 方法
await isar.users.putByUsername(user1);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

你可以看到，此处 Id 被复用了，对象始终是同一个，只是更改了 age 属性。

## 大小写不敏感的索引

所有针对 `String` 和 `List<String>` 属性的索引默认情况下对大小写敏感。如果你想创建一个对大小写不敏感的索引，你可以设置 `caseSensitive` 选项为 `false`：

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

## 索引类型

索引有三种不同类型。大多数情况下，你会使用 `IndexType.value` 的值索引，但是哈希索引会更高效。

### 值索引

值索引是默认的索引类型，是唯一可被用于非字符串或非数组类型属性的索引。属性的值将会被用于创建索引。对于数组 List，其包含的元素会被用来创建索引。值索引是三种类型中最灵活但同时也是最占存储空间的索引。

:::tip
对于原生数据类型（如 Int）的属性，或字符串类型的属性，但需要用到 `startsWith()` Where 子句，亦或是数组类型的属性，需要对其单一元素查询，那么你可以使用 `IndexType.value`。
:::

### 哈希索引

字符串和数组可以通过散列化索引来大幅度减小存储空间。哈希索引的缺点是它无法通过前缀匹配来搜寻（如使用 `startsWith` 的 Where 子句）。

:::tip
对于类型为数组或字符串的属性，如果你不会用到 `startsWith` 和 `elementEqualTo` 的 Where 子句，可以使用 `IndexType.hash`。
:::

### 哈希元素索引

我们可以使用 `IndexType.hash` 来对整个数组或字符串散列化处理，也可以使用 `IndexType.hashElements` 分别对数组中单个元素做散列化，来高效地创建多条目的索引。

:::tip
对于 `List<String>` 类型的属性，如果你需要用到 `elementEqualTo`的 Where 子句，可以使用 `IndexType.hashElements`。
:::

## 组合索引

组合索引是指包含多个属性的索引。Isar 允许你创建最多三个属性的组合索引。

组合索引也就是所谓的多列索引。

让我们从示例学习组合索引。我们先创建了一个 Person Collection，然后基于 age 和 name 属性定义了一个组合索引：

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

**数据：**

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

**生成的索引表:**

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

生成的组合索引表包含了所有人的信息，并默认按照他们的年龄和姓名排序。

如果你想要高效地使用多个属性来进行排序并查询，组合索引能帮你轻松实现。它也提供了可同时查询多个属性的进阶版 Where 子句：

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

组合索引中的最后一个属性也支持查询条件语句如 `startsWith()` 或 `lessThan()`：

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## 多条目索引（全文检索）

如果你用 `IndexType.value` 对一个数组进行索引，Isar 会自动创建多条目索引，数组中每一个元素都会被索引。这适用于所有类型的数组。

多条目索引的实际应用包括对标签数组的索引或者创建全文检索的索引。

```dart
@collection
class Product {
  Id? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` 能将字符串按照 [Unicode Annex #29](https://unicode.org/reports/tr29/) 分解成一个个单词，所以它几乎适用于所有人类语言。

**数据：**

| id  | 字符串                       | 分解结果                     |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

相同的字符只会在索引中出现一次。

**生成的索引表:**

| 单词        | id        |
| ----------- | --------- |
| comfortable | [1, 2]    |
| blue        | 1         |
| necktie     | 4         |
| plain       | 3         |
| pullover    | 2         |
| red         | [2, 3, 4] |
| super       | 4         |
| t-shirt     | [1, 3]    |

现在这个索引可以使用每个单词的前缀匹配（或等同比较）的 Where 子句了。

:::tip
你应该也要考虑使用[语音算法](https://en.wikipedia.org/wiki/Phonetic_algorithm)如 [Soundex](https://en.wikipedia.org/wiki/Soundex) 返回的结果，而不是直接存储单词。
:::
