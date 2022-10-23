---
title: 查询
---

# 查询

你可以通过查询找到符合某些条件的记录，例如：

- 查找所有打星标的联系人
- 查找所有联系人的名字并去重
- 删除所有没有定义姓氏的联系人

因为查询不是在Dart中执行，而是在数据库里执行的，所以它们真的非常快。当你巧妙地使用索引时，你可以进一步提高查询的性能。在下文中，你将学习如何编写查询，以及如何让它变得尽可能快。

有两种不同的方法来过滤（filtering）你的数据。过滤器和where语句。我们先来看看过滤器是如何工作的。

## 过滤器（Filters）

过滤器很容易使用和理解。根据你的字段类型，有不同的过滤器操作可用，其中大部分都具有不言自明的名称。

过滤器的工作方式是对被过滤的集合中的每个对象执行一个表达式。如果表达式的结果为 "true"，Isar将该对象包括在结果中。过滤器不影响结果的排序。

我们将在以下例子中使用这样的模型：

```dart
@collection
class Shoe {
  Id? id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### 查询条件

根据不同的字段类型，有不同的查询条件可用。

| 条件                       | 说明                                                      |
|--------------------------|---------------------------------------------------------|
| `.equalTo(value)`        | 匹配与指定`value`相等的值。                                       |
| `.between(lower, upper)` | 匹配介于`lower`和`upper`之间的值。                                |
| `.greaterThan(bound)`    | 匹配大于`bound`的值。                                          |
| `.lessThan(bound)`       | 匹配小于`bound`的值。默认情况下，空值`null`将被包括在内，因为`null`被认为比任何其他值都小。 |
| `.isNull()`              | 匹配为`null`的值。                                            |
| `.isNotNull()`           | 匹配非`null`的值。                                            |
| `.length()`              | 列表、字符串和链接(link)类型可以根据列表或链接中的元素数量来过滤对象。                  |

我们假设数据库中包含四只鞋，尺寸分别为39、40、46，还有一只鞋的尺寸没有设定（`null`）。除非你指定了排序，否则这些值将按id排序后返回。

```dart

isar.shoes.filter()
  .sizeLessThan(40)
  .findAll() // -> [39, null]

isar.shoes.filter()
  .sizeLessThan(40, include: true)
  .findAll() // -> [39, null, 40]

isar.shoes.filter()
  .sizeBetween(39, 46, includeLower: false)
  .findAll() // -> [40, 46]

```

### 逻辑操作符

您可以使用以下逻辑运算符组成谓词（predicates）：

| 运算符        | 描述                                    |
|------------|---------------------------------------|
| `.and()`   | 如果左右两边的表达式的值都为`true`，则值为`true`。       |
| `.or()`    | 如果任何一个表达式的值都是`true`，那么该表达式的值就是`true`。 |
| `.xor()`   | 如果正好有一个表达式的值是`true`，则值为`true`。        |
| `.not()`   | 否定表达式的结果。                             |
| `.group()` | 将条件分组，并允许指定条件执行顺序。                    |

如果你想找到所有46码的鞋子，你可以使用以下查询：

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

如果你想使用一个以上的条件，你可以使用**与**`.and()`、**或**`.or()`和**异或**`.xor()`组合多个过滤器。

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // 这一步是可选的，因为过滤器默认使用逻辑与（and）相连。
  .isUnisexEqualTo(true)
  .findAll();
```

这个查询相当于`size == 46 && isUnisex == true`。

你也可以使用`.group()`对条件进行分组：

```dart
final result = await isar.shoes.filter()
  .sizeBetween(43, 46)
  .and()
  .group((q) => q
    .modelNameContains('Nike')
    .or()
    .isUnisexEqualTo(false)
  )
  .findAll()
```

这个查询相当于`size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)`。

要否定一个条件或组，请使用**非**`.not()`：

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

该查询相当于`size != 46 && isUnisex != true`。

### 字符串条件

除了以上查询条件外，字符串类型还额外提供了一些你可以使用的条件。例如，类似Regex的通配符，这能使搜索更加灵活。

| 条件                   | 说明                    |
|----------------------|-----------------------|
| `.startsWith(value)` | 匹配以`value`开头的字符串。     |
| `.contains(value)`   | 匹配包含`value`的字符串。      |
| `.endWith(value)`    | 匹配以`value`结束的字符串。     |
| `.matches(wildcard)` | 匹配符合`wildcard`模式的字符串。 |

**大小写敏感**  
所有字符串操作都有一个可选的`caseSensitive`参数，默认为`true`。

**通配符**  
一个[通配符字符串表达式](https://en.wikipedia.org/wiki/Wildcard_character)是包含正常字符和两个特殊通配符字符的字符串。

- 通配符`*`匹配零个或更多的任何字符。
- `?`通配符匹配任何字符。
  例如，通配符字符串`"d?g"`匹配`"dog"`、`"dig"`和`"dug"`，但不匹配`"ding"`、`"dg"`或`"a dog"`。

### 查询修饰符（modifiers）

有时需要根据某些条件或针对不同的值构建查询。Isar有非常强大的工具来构建条件查询：

| 修饰符                   | 说明                                                         |  
|-----------------------|------------------------------------------------------------|
| `.optional(cond, qb)` | 仅当`condition`为`true`时才扩展查询。这几乎可以在查询中的任何地方使用，例如条件排序或限制取回数量。 |
| `.anyOf(list, qb)`    | 扩展对`values`中每个值的查询，并使用**或**组合条件。                           |
| `.allOf(list, qb)`    | 扩展对`values`中每个值的查询，并使用**与**组合条件。                           |

在这个例子中，我们构建了一个可以使用optional过滤器查找鞋子的方法：

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // 仅当sizeFilter != null的时候应用过滤器
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

如果你想找到某个鞋码的所有鞋子，你可以使用传统的查询方法，或者使用`anyOf()`修饰符。

```dart
final shoes1 = await isar.shoes.filter()
  .sizeEqualTo(38)
  .or()
  .sizeEqualTo(40)
  .or()
  .sizeEqualTo(42)
  .findAll();

final shoes2 = await isar.shoes.filter()
  .anyOf(
    [38, 40, 42],
    (q, int size) => q.sizeEqualTo(size)
  ).findAll();

// shoes1 == shoes2
```

当你想建立动态查询时，查询修饰符特别有用。

### 列表

甚至列表也可以被查询：

```dart
class Tweet {
  Id? id;

  String? text;

  List<String> hashtags = [];
}
```

你可以根据列表的长度来查询：

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

这些相当于Dart代码`tweets.where((t) => t.hashtags.isEmpty);`和`tweets.where((t) => t.hashtags.length > 5);`。你也可以基于列表元素进行查询：

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

这相当于Dart代码`tweets.where((t) => t.hashtags.contains('flutter'))；`。

### 嵌套对象

嵌套对象是Isar最有用的功能特性之一。我们可以非常高效地使用和顶层对象相同的条件对嵌套对象进行查询。让我们假设有以下的模型：

```dart
@collection
class Car {
  Id? id;

  Brand? brand;
}

@embedded
class Brand {
  String? name;

  String? country;
}
```

我们想查询所有品牌为`"BMW"`和国家为`"Germany"`的汽车。我们可以使用这样的查询来达成：

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

针对嵌套的查询请尽可能地进行分组（group）。上面的查询比下面的查询更有效。尽管结果是一样的。

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### 链接

如果你的模型包含[链接或反向链接](links)，你可以根据链接对象或链接对象的数量来过滤你的查询：

:::warning
请记住，由于Isar需要查找链接对象，链接查询可能是很昂贵的。请考虑使用嵌入式对象来代替。
:::

```dart
@collection
class Teacher {
  Id? id;

  late String subject;
}

@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

如果我们想找到有数学或英语老师的所有学生：

```dart
final result = await isar.students.filter()
  .teachers((q) {
    return q.subjectEqualTo('Math')
      .or()
      .subjectEqualTo('English');
  }).findAll();
```

如果至少有一个链接对象符合条件，则链接过滤器评估为`true`。

让我们来搜索所有没有老师的学生：
  
```dart
final result = await isar.students.filter().teachersLengthEqualTo(0).findAll();
```

或者也可以这样做:

```dart
final result = await isar.students.filter().teachersIsEmpty().findAll();
```

## where语句

where语句是一个非常强大的工具，但要把它用好，还是有一点挑战。

与过滤器不同的是，where语句通过你在模式（schema）中定义的索引（index）来检查查询条件。通过索引查询比单独过滤每条记录要快得多。

➡️ 学习更多知识: [索引](indexes)

:::tip
作为一条基本规则，你应该尽可能地使用where语句来过滤数据，在其它不合适的情况下才考虑用过滤器。
:::

你只能使用**或（or）**组合where语句。换句话说，你可以把多个where语句聚合在一起，但你不能查询多个where语句的交集。

让我们给鞋子集合添加索引：

```dart
@collection
class Shoe with IsarObject {
  Id? id;

  @Index()
  Id? size;

  late String model;

  @Index(composite: [CompositeIndex('size')])
  late bool isUnisex;
}
```

以上有两个索引。`size`上的索引允许我们使用`.sizeEqualTo()`这样的where语句。`isUnisex`上的复合索引允许使用`isUnisexSizeEqualTo()`这样的where语句。但也可以是`isUnisexEqualTo()`，因为你可以使用索引的任何前缀（prefix）。

现在我们可以重写之前的查询，使用复合索引找到46码的中性鞋。这个查询将比之前的查询快很多：

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

where语句还有另外两个超能力：它们为你提供了"免费"的排序和超快的去重操作。

### 结合where语句和过滤器

还记得`shoes.filter()`查询吗？它实际上只是`shoes.where().filter()`的一个快捷写法。你可以（而且也应该）在同一个查询中结合where语句和过滤器，这样一来可以同时享受两者的给你带来的好处：

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

where语句会先被应用以减少要被过滤的对象的数量。然后过滤器会被应用于剩余的对象。

## 排序

你可以使用`.sortBy()`、`.sortByDesc()`、`.thenBy()`和`.thenByDesc()`方法定义执行查询时的结果排序方式。

在不使用索引的情况下，想要找到所有按型号名称升序排序和按尺寸降序排序的鞋子：

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

对许多结果进行排序的代价会很昂贵，特别是在偏移（offset）和限制返回数量（limit）之前发生的排序。上面提到的排序方法没有使用索引。幸运的是，我们可以再次使用where语句进行排序，即使我们需要对一百万个对象进行排序，我们的查询也能快如闪电。

### where语句排序

如果你在查询中使用了**单一的**where语句，那么返回结果就已经按索引排序了。这很好！

让我们假设有尺寸为`[43, 39, 48, 40, 42, 45]`的鞋子，我们想找到所有尺寸大于`42`的鞋子，并让它们按尺寸排序：

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // 同时会按尺寸大小对结果进行排序
  .findAll(); // -> [43, 45, 48]
```

正如你所见，结果是按照`size`索引排序的。如果你想颠倒where语句的排序顺序，你可以将`sort`设置为`Sort.desc`：

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

有时你不想使用where语句进行过滤，但仍然可以从中受益。你可以使用where语句中的`any`语句。

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

如果你使用了复合索引，结果将按索引中的所有字段进行排序。

:::tip
如果你需要对结果进行排序，可以考虑使用索引来达到这个目的。特别是当你用到`offset()`和`limit()`时。
:::

有时可能会不能使用索引进行排序，又或者是使用后没有收益。对于这种情况，你应该使用索引来尽可能地减少结果条目的数量。

## 唯一值（Unique values）

要想只返回具有唯一值的条目，请使用distinct谓词。例如，要找出你的Isar数据库中有多少种不同的鞋子型号：

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

你也可以串联多个不同的条件，找到所有具有不同型号和尺寸组合的鞋子：

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

只有每个不同组合的第一个结果会被返回。你可以使用where语句和排序操作来控制它。

### distinct语句

如果你有一个非唯一的索引，你可能想得到它所有的唯一值。你可以使用上一节中的`distinctBy`操作，但是它是在排序和过滤之后执行的，所以会有一些额外开销。
如果你只使用一个where语句，你可以依靠索引来执行去重操作。

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
理论上，你甚至可以使用多个where语句来进行排序和去重。唯一的限制是，这些where语句不能重叠使用相同的索引。如果要获得正确的排序，这些语句也需要按照排序顺序应用。如果你依赖这一点，要非常小心！
:::

## 偏移量和限制取回数量

对于延迟列表视图来说，限制查询结果的数量往往是一个好主意。你可以通过设置`limit()`来做到这一点。

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

通过设置`offset()`，你也可以将你的查询结果分页。

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

由于实例化Dart对象通常是执行查询时代价最高的部分，所以只加载你需要的对象是一个好主意。

## 执行顺序

Isar总是以相同的顺序执行查询：

1. 遍历主索引或次索引来寻找对象（应用where语句）
2. 通过过滤器过滤对象
3. 对结果进行排序
4. 应用去重操作
5. 偏移量和限制返回结果数量
6. 返回结果

## 查询操作

在前面的例子中，我们使用`.findAll()`来检索所有匹配的对象。这里还有更多的操作可用：

| 操作               | 说明                                        |
|------------------|-------------------------------------------|
| `.findFirst()`   | 只返回第一个匹配的对象，如果没有匹配，则返回`null`。             |
| `.findAll()`     | 返回所有匹配的对象。                                |
| `.count()`       | 计算有多少对象符合查询条件。                            |
| `.deleteFirst()` | 从集合中删除第一个匹配的对象。                           |
| `.deleteAll()`   | 从集合中删除所有匹配的对象。                            |
| `.build()`       | 编译查询以便以后重复使用。如果你想多次执行同一个查询，这样可以节省构建查询的成本。 |

## 字段查询

如果你只对单个字段的值感兴趣，你可以使用字段查询。只要建立一个常规的查询并选择一个字段：

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

在反序列化过程中，只使用单一字段可以节省时间。字段查询也适用于嵌套对象和列表。

## 聚合

Isar支持对字段查询的值进行聚合。以下聚合操作是可用的：

| 操作           | 说明                          |
|--------------|-----------------------------|
| `.min()`     | 查找最小值，如果没有匹配，则返回`null`。     |
| `.max()`     | 查找最大值，如果没有匹配，则返回`null`。     |
| `.sum()`     | 将所有数值相加。                    |
| `.average()` | 计算所有数值的平均值，如果没有匹配，则计算`NaN`。 |

使用聚合比取回所有匹配对象并手动聚合要快得多。

## 动态查询

:::danger
本节内容很可能与你无关。我们不鼓励使用动态查询，除非你绝对需要（而你很少需要这样做）。
:::

上面所有的例子都使用了QueryBuilder和生成静态扩展方法。也许你想创建动态查询或自定义查询语言（如Isar Inspector）。那么在这种情况下，你可以使用`buildQuery()`方法：

| 参数              | 说明                                |
|-----------------|-----------------------------------|
| `whereClauses`  | 查询的where语句。                       |
| `whereDistinct` | where语句是否应该返回去重的值（只适用于单个where语句）。 |
| `whereSort`     | where语句的遍历顺序(只适用于单个where语句)。      |
| `filter`        | 应用于结果的过滤器。                        |
| `sortBy`        | 一个要排序的字段列表。                       |
| `distinctBy`    | 一个要去重的字段列表。                       |
| `offset`        | 结果的偏移量。                           |
| `limit`         | 要返回的最大结果数。                        |
| `property`      | 如果非null，只返回该字段的值。                 |

我们来创建一个动态查询：

```dart
final shoes = await isar.shoes.buildQuery(
  whereClauses: [
    WhereClause(
      indexName: 'size',
      lower: [42],
      includeLower: true,
      upper: [46],
      includeUpper: true,
    )
  ],
  filter: FilterGroup.and([
    FilterCondition(
      type: ConditionType.contains,
      property: 'model',
      value: 'nike',
      caseSensitive: false,
    ),
    FilterGroup.not(
      FilterCondition(
        type: ConditionType.contains,
        property: 'model',
        value: 'adidas',
        caseSensitive: false,
      ),
    ),
  ]),
  sortBy: [
    SortProperty(
      property: 'model',
      sort: Sort.desc,
    )
  ],
  offset: 10,
  limit: 10,
).findAll();
```

下面的查询是等效的：

```dart
final shoes = await isar.shoes.where()
  .sizeBetween(42, 46)
  .filter()
  .modelContains('nike', caseSensitive: false)
  .not()
  .modelContains('adidas', caseSensitive: false)
  .sortByModelDesc()
  .offset(10).limit(10)
  .findAll();
```
