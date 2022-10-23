---
title: 索引
---

# 索引

索引是Isar最强大的功能。许多嵌入式数据库提供"普通"索引（如果有的话），但Isar还有复合和多条目索引。了解索引是如何工作的，对于优化查询性能至关重要。Isar让你选择你想使用的索引以及你想如何使用它。我们先来快速介绍一下什么是索引。

## 什么是索引？

当一个集合没有被索引时，行的顺序很可能无法被查询辨别出来，也无法通过任何方式对索引进行优化，因此你的查询将不得不线性地搜索这些对象。换句话说，查询将不得不搜索每一个对象来找到符合条件的对象。你可以想象，这可能需要一些时间。查找每一个对象的效率并不高。

例如，这个`产品'集合是完全无序的。

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

#### Data:

| id  | name      | price |
|-----|-----------|-------|
| 1   | Book      | 15    |
| 2   | Table     | 55    |
| 3   | Chair     | 25    |
| 4   | Pencil    | 3     |
| 5   | Lightbulb | 12    |
| 6   | Carpet    | 60    |
| 7   | Pillow    | 30    |
| 8   | Computer  | 650   |
| 9   | Soap      | 2     |

一个试图找到所有价格超过30欧元的产品的查询必须在所有9行中搜索。对于9行来说，这不是一个问题，但对于10万行来说，这可能成为一个问题。

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

为了提高这个查询的性能，我们对`price`字段进行索引。索引就像一个排序的查找表。

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

#### 生成的索引:

| price                | id                 |
|----------------------|--------------------|
| 2                    | 9                  |
| 3                    | 4                  |
| 12                   | 5                  |
| 15                   | 1                  |
| 25                   | 3                  |
| 30                   | 7                  |
| <mark>**55**</mark>  | <mark>**2**</mark> |
| <mark>**60**</mark>  | <mark>**6**</mark> |
| <mark>**650**</mark> | <mark>**8**</mark> |

现在，查询的执行速度可以快很多。执行器可以直接跳转到最后三条索引行，并通过其id找到相应的对象。

### 排序

另一件很酷的事情：索引可以做超快的排序。排序查询的成本很高，因为数据库在排序之前必须在内存中加载所有结果。即使你指定了一个偏移量或限制了返回数量，它们也是在排序后才被应用的。

让我们设想一下，我们想找到四个最便宜的产品。我们可以使用下面的查询：

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

在这个例子中，数据库将不得不加载所有对象！然后按价格排序，并返回价格最低的四个产品。

正如你所想，用前面的索引可以更有效地完成这个任务。数据库获取索引的前四行并返回相应的对象，因为它们已经有了正确的顺序。

要使用索引进行排序，我们要这样写查询：

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

`.anyX()`这个where语句告诉Isar使用一个索引，只是为了排序。你也可以使用`.priceGreaterThan()`这样的where语句，得到排序的结果。

## 唯一索引

唯一索引确保索引不包含任何重复的值。它可以由一个或多个字段组成。如果一个唯一索引有一个字段，那么这个字段中的值将是唯一的。如果唯一索引有一个以上的字段，这些字段中的值的组合是唯一的。

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

任何试图向唯一索引插入或更新数据而导致重复的行为都会导致错误：

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

// 尝试插入用户名重复的用户
await isar.users.put(user2); // -> error: unique constraint violated
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## 替换索引

有时，如果即便违反了唯一约束，抛出一个错误也是不可取的。你可能想用新的对象替换现有的对象。这可以通过设置索引的`replace`参数为`true`来实现：

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

现在，当我们试图用现有的用户名插入一个用户时，Isar将用新的用户替换现有的用户。

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

替换索引也会产生`putBy()`方法，允许你更新对象而不是替换它们。现有的id被重新使用，链接仍然有效。

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// 用户当前不存在，所以相当于put()
await isar.users.putByUsername(user1); 
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

正如你所看到的，第一个插入的用户的ID被复用了。

## 大小写敏感索引

所有关于`String`和`List<String>`类型字段的索引默认是大小写敏感的。如果你想创建一个不区分大小写的索引，你可以使用`caseSensitive`选项：

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

有不同类型的索引。大多数时候，你会想使用`IndexType.value`索引，但哈希索引效率更高。

### 值索引

值索引是默认的索引类型，也是所有非字符串或列表类型的字段所允许的唯一索引类型。字段值被用来建立索引。在列表的情况下，使用列表中的元素。它是三种索引类型中最灵活但也最耗费空间的一种。

:::tip
请对原生类型、需要`startsWith()`的where语句的字符串和需要搜索单个对象的列表使用`IndexType.value`。
:::

### 哈希索引

字符串和列表可以被哈希，以大大减少索引所需的存储空间。哈希索引的缺点是它们不能用于前缀扫描（`startsWith`的where语句）。

:::tip
如果你不需要`startsWith`和`elementEqualTo`的where语句，请对字符串和列表使用`IndexType.hash`。
:::

### 哈希元素索引

字符串列表可以作为一个整体被哈希（使用`IndexType.hash`），或者列表中的元素可以被单独哈希（使用`IndexType.hashElements`），能够有效地创建一个具有哈希元素的多条目索引。

:::tip
请在需要`elementEqualTo`的where语句的地方，为`List<String>`使用`IndexType.hashElements`。
:::

## 复合索引

复合索引是一个多字段的索引。Isar允许你创建最多三个字段的复合索引。

复合索引也被称为多列索引。

也许最好从一个例子开始。我们创建一个名为person的集合，并在年龄和名字字段上定义一个复合索引：

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

#### 数据:

| id  | name   | age | hometown  |
|-----|--------|-----|-----------|
| 1   | Daniel | 20  | Berlin    |
| 2   | Anne   | 20  | Paris     |
| 3   | Carl   | 24  | San Diego |
| 4   | Simon  | 24  | Munich    |
| 5   | David  | 20  | New York  |
| 6   | Carl   | 24  | London    |
| 7   | Audrey | 30  | Prague    |
| 8   | Anne   | 24  | Paris     |

#### 生成的索引

| age | name   | id  |
|-----|--------|-----|
| 20  | Anne   | 2   |
| 20  | Daniel | 1   |
| 20  | David  | 5   |
| 24  | Anne   | 8   |
| 24  | Carl   | 3   |
| 24  | Carl   | 6   |
| 24  | Simon  | 4   |
| 30  | Audrey | 7   |

生成的复合索引包含所有按年龄和姓名排序的人。

如果你想创建按多个字段排序的高效查询，复合索引就非常好。它们还可以实现具有多个字段的高级where语句：

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

复合索引的另外一个特性是支持`startsWith()`或`lessThan()`等条件：

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## 多条目索引

如果你使用`IndexType.value`对一个列表进行索引，Isar会自动创建一个多条目索引，列表中的每个条目都会被索引到该对象。它适用于所有类型的列表。

多条目索引的实际应用包括为一个标签（tag）列表建立索引或创建一个全文索引。

```dart
@collection
class Product {
  Id? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()`根据[Unicode Annex #29](https://unicode.org/reports/tr29/)规范将字符串分割成单词，所以它几乎对所有语言都能正确工作。

#### 数据:

| id  | description                  | descriptionWords             |
|-----|------------------------------|------------------------------|
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

有重复单词的条目在索引中只出现一次。

#### 生成的索引

| descriptionWords | id        |
|------------------|-----------|
| comfortable      | [1, 2]    |
| blue             | 1         |
| necktie          | 4         |
| plain            | 3         |
| pullover         | 2         |
| red              | [2, 3, 4] |
| super            | 4         |
| t-shirt          | [1, 3]    |

这个索引现在可以用于description中各个词的前缀（或完全相等）where语句。

:::tip
除了直接存储单词，还可以考虑使用像[Soundex](https://en.wikipedia.org/wiki/Soundex)这样的[语音算法](https://en.wikipedia.org/wiki/Phonetic_algorithm)的结果。
:::
