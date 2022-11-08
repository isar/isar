---
title: 查询
---

# 查询

查询是指你如何查找匹配指定条件的数据。例如：

- 查找所有被收藏的联系人
- 查找联系人列表中名（不是姓）不同的人
- 删除那些没有写明姓氏的联系人

因为查询是在数据库中而不是在 Dart 中执行的，所以它们非常快。当你巧妙地运用索引，性能将会更大幅度地被提高。下面你将学习如何来查询数据，以及如何提升查询性能。

有两种方法来过滤数据：过滤器 Filter 和 Where 子句。我们先来看 Filter 的用法。

## Filter

Filter 很好理解也很容易使用。Isar Generator 会根据 Collection 中字段的类型来生成多种 Filter，其中大部分 Filter 的名称也解释了它们的用途。

Filter 通过特定条件表达式来匹配 Collection 中每一个待查询对象。如果该表达式返回 `true`，那么 Isar 就会将该对象纳入查询结果中。Filter 不会影响查询结果的排列顺序。

我们通过下方 Collection 作为例子来说明：

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

根据上述 Collection 的字段类型，我们会有以下几种条件表达式可选择：

| 条件                     | 描述                                                                                     |
| ------------------------ | ---------------------------------------------------------------------------------------- |
| `.equalTo(value)`        | 匹配等于给定 `value` 的值.                                                               |
| `.between(lower, upper)` | 匹配介于 `lower` 和 `upper` 之间的值                                                     |
| `.greaterThan(bound)`    | 匹配大于 `bound` 的值.                                                                   |
| `.lessThan(bound)`       | 匹配小于 `bound` 的值。 默认情况下 `null` 也会被纳入其中，因为 `null` 被认为小于任何值。 |
| `.isNull()`              | 匹配为 `null` 的值                                                                       |
| `.isNotNull()`           | 匹配不为 `null` 的值                                                                     |
| `.length()`              | 对于数组 List、字符串 String 和关联 Link 的长度查询是基于数组或关联中对象的数量的。      |

假设数据库包含四双鞋的数据，分别为尺码 39、40、46 和一双未知尺码（`null`）。除非你对它们进行排序，不然返回的结果是按照 Id 来排列的。

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

### 逻辑运算符

你可以自行组合下方逻辑运算符来进行查询：

| 运算符     | 描述                                                |
| ---------- | --------------------------------------------------- |
| `.and()`   | 如果左右两边的表达式同时为 `true` 则返回 `true`。   |
| `.or()`    | 如果两侧表达式至少有一个为 `true` 则返回 `true`。   |
| `.xor()`   | 如果两侧表达式有且只有一个为 `true` 则返回 `true`。 |
| `.not()`   | 否定随后紧跟表达式的结果。                          |
| `.group()` | 给条件分组，允许指定运算顺序。                      |

如果你想要查找所有尺码为 46 的鞋子，你可以使用以下代码：

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

如果你想要使用多个条件，你可以用逻辑**与** `.and()`、逻辑**或** `.or()` 和逻辑**异或** `.xor()` 来组合多个 Filter。

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // 可选的。 因为 Filter 之间已经隐式使用了逻辑与。
  .isUnisexEqualTo(true)
  .findAll();
```

上述查询条件等同于： `size == 46 && isUnisex == true`。

你也可以通过 `.group()` 对其进行分组：

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

上述查询条件等同于 `size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)`。

使用逻辑**非** `.not()` 来否定一个条件或一个条件组：

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

上述查询条件等同于 `size != 46 && isUnisex != true`。

### 字符串条件

除了上述查询条件，还有下表若干个针对字符串查询的条件表达式可供使用。 例如，类似正则的通配符在搜索时提供了更多灵活性。

| 条件                 | 描述                               |
| -------------------- | ---------------------------------- |
| `.startsWith(value)` | 匹配以 `value` 开头的字符串。      |
| `.contains(value)`   | 匹配包含 `value` 的字符串。        |
| `.endsWith(value)`   | 匹配以 `value` 结尾的字符串。      |
| `.matches(wildcard)` | 匹配符合 `wildcard` 正则的字符串。 |

**大小写敏感**  
所有字符串操作都有一个可选的参数 `caseSensitive`，默认情况下为 `true`。

**通配符：**  
一个[通配符字符串表达式](https://en.wikipedia.org/wiki/Wildcard_character)是指一段使用了两个特殊通配符的普通字符串：

- `*` 通配符匹配零个或多个任意字符。
- `?` 通配符匹配任意一个字符。
  例如，通配符字符串 `"d?g"` 匹配 `"dog"`、`"dig"`、和 `"dug"`，但不匹配 `"ding"`、`"dg"` 或`"a dog"`。

### 查询修改器

有时候，基于某些特定条件的查询或针对不同值的查询是有必要的。Isar 通过内置强大的修改器功能来实现这些条件查询：

| 修改器                | 描述                                                                                                                  |
| --------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `.optional(cond, qb)` | 当且仅当 `condition` 为 `true` 时扩充查询条件。该修改器可被用于查询表达式的任意位置，比如有条件地排序或限制查询个数。 |
| `.anyOf(list, qb)`    | 为 `values` 中每个值扩充查询条件，然后将它们作逻辑**或**运算。                                                        |
| `.allOf(list, qb)`    | 为 `values` 中的每个值扩充查询条件，然后将它们作逻辑**与**运算。                                                      |

在下方例子中，我们创建了一个函数，该函数通过一个可选的 Filter 来查找鞋子：

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // 当且仅当 sizeFilter != null 时，才会执行 q.sizeEqualTo(sizeFilter!)
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

如果你想要搜寻某些尺码的鞋子时，如 38、40 或 42 码的鞋子，你要么可以使用传统的方式，要么可以使用修改器，代码如下：

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

当你想要动态查询时，修改器特别有用。

### 数组 List

甚至也可以查询数组 List：

```dart
class Tweet {
  Id? id;

  String? text;

  List<String> hashtags = [];
}
```

你可以根据数组的长度来查询：

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

这分别等同于 `tweets.where((t) => t.hashtags.isEmpty);` 和 `tweets.where((t) => t.hashtags.length > 5);`。 你亦可基于其包含的元素来查询：

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

这等同于 `tweets.where((t) => t.hashtags.contains('flutter'));`。

### 嵌套对象

嵌套对象是 Isar 中最有用的功能之一。可以使用同样适用于顶层对象的查询条件来高效查询它们。假定我们有以下数据模型：

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

我们想要查询品牌名为 `"BMW"` 且品牌国家为 `"Germany"` 的所有车辆。我们可以执行以下代码：

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

永远试着给嵌套查询分组。上述查询比下方的例子性能更好。尽管查询结果是相同的：

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### 关联（Link）

如果你的数据模型含有[关联或反向关联](links)，你可以根据被关联的对象或被关联对象的数量来进行查询。

:::tip
记住，关联查询的效率相对更低。因为 Isar 需要查询相关联的对象。考虑尽量使用嵌套对象来代替关联。
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

我们想要找到所有修数学或英语的学生：

```dart
final result = await isar.students.filter()
  .teachers((q) {
    return q.subjectEqualTo('Math')
      .or()
      .subjectEqualTo('English');
  }).findAll();
```

只要至少一个相关联对象符合条件，查询条件就会为 `true` 。

让我们搜索所有没有老师的学生：

```dart
final result = await isar.students.filter().teachersLengthEqualTo(0).findAll();
```

或者：

```dart
final result = await isar.students.filter().teachersIsEmpty().findAll();
```

## Where 子句

Where 子句很强大，但是用对可能有点困难。

相对于 Filter， Where 子句利用你在 Schema 中定义的索引来作为查询条件。对索引进行查询比对单条数据查询可快多了。

➡️ 学习更多：[索引](indexes)

:::tip
一条基本的规则是你应该永远尽可能多地使用 Where 子句来进行索引查询，然后用 Filter 对未被索引的数据进行查询。
:::

你只能用逻辑**与**来对多个 Where 子句做逻辑运算。换句话说，你可以叠加多个 Where 子句，但不能查询多个 Where 子句的交集。

让我们给下面 Collection 添加索引：

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

这里有俩个索引。 `size` 上的索引允许我们使用像 `.sizeEqualTo()` 的 Where 子句，`isUnisex` 上的组合索引则允许我们可以使用像 `isUnisexSizeEqualTo()` 这样的 Where 子句，当然也可以使用 `isUnisexEqualTo()`，因为永远可以使用索引的任何前缀查询语句。

我们可以用组合索引重写之前的查询尺码 46 鞋子的代码。这次查询会比之前快很多：

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

Where 子句还有两个强大特性：它允许你“自由”排序和超快去重操作。

### 将 Where 子句和 Filter 相结合

还记得 `shoes.filter()` 查询吗？实际上它是 `shoes.where().filter()` 的简写。你可以（也应该）在同一查询中同时运用 Where 子句和 Filter 来最大限度地提升查询性能：

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

先用 Where 子句来过滤出部分对象，减少了查询对象数量。然后用 Filter 来查询剩下的对象。

## 排序

你可以在查询中使用 `.sortBy()`、`.sortByDesc()`、 `.thenBy()` 和 `.thenByDesc()` 等方法来给待查询数据进行排序。

下方代码演示了不用索引来查询鞋子，查询结果以鞋款名正序和鞋码倒序来排列：

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

对诸多结果进行排序可是非常消耗性能的，尤其是因为排序发生在偏移量（Offset）和限制（Limit）之前。上述排序的方法也从未利用到索引。幸运的是，我们可以再次使用 Where 子句来进行排序以提升性能，这样即使对上百万的结果进行排序也毫无问题。

### 使用 Where 子句来排序

如果你在查询中使用**单个** Where 子句， 那么查询结果就已经通过索引被排列好了。这很重要！

假设我们有鞋码分别为 `[43, 39, 48, 40, 42, 45]` 的鞋子。我们想查询所有鞋码大于 42 的鞋子，然后将它们按鞋码大小排序：

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // 也将结果按鞋码大小排序
  .findAll(); // -> [43, 45, 48]
```

如你所见，此处结果是按照索引 `size` 来排序的。如果你想要倒序排列，可以将 `sort` 设置为 `Sort.desc`：

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

有些时候你不想过滤数据，只是想对全部数据排序，但是也可以受益于这种隐式排序。你可以使用 `any` Where 子句：

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

如果你使用组合索引，查询结果会根据索引内所有字段进行排序。

:::tip
如果你需要对结果进行排序，考虑使用索引。尤其是如果你需要用到 `offset()` 和 `limit()`。
:::

然而有时候使用索引来排序变得不太方便或不容易实现。对于这种情况，你应该尽可能通过索引来减少待查询结果的数量。

## 唯一值

使用 distinct 断言来返回含有唯一值的对象数据。 例如，在 Isar 数据库中找出有多少种不同鞋款：

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

你也可以链式地调用多个 distinct 条件来找出所有不同鞋码且不同鞋款的鞋子：

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

只有每种不同条件组合的第一个对象会被返回。 你可以用 Where 子句和排序操作来控制它。

### Where 子句去重化

如果你有一个索引，它对应的字段可能出现相同值，你可能希望对该字段进行去重化。你可以使用前面部分提到的 `distinctBy` 方法，但它在排序和 Filter 之后执行，所以有些许额外的性能开销。

而如果你只用到一个 Where 子句，你可以只依赖索引来实现去重化。

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
理论上，你甚至可以使用多个 Where 子句来排序和去重。唯一的限制是那些 Where 子句不能彼此有重叠（即上面提到的交集）且不能使用相同的索引。它们需要按照顺序来使用，以便正确排序。因此如果依赖于这种用法，你必须要细心谨慎。
:::

## 偏移量（Offset）和限制（Limit）

对于一个懒加载列表组件来说，限制显示的个数通常是很好的办法。你可以使用 `limit()` 对查询结果的数量进行限制：

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

而借用 `offset()` 你也可以对查询结果进行分页。

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

因为初始化 Dart 对象往往是执行查询过程中最消耗性能的部分，因此只加载你所需要的对象是一个不错的做法。

## 执行顺序

Isar 总是按照下面顺序执行查询：

1. 遍历索引来查询对象（即使用 Where 子句）
2. 对对象进行过滤
3. 对结果进行排序
4. 去重化（若有）
5. 偏移量和限制（若有）
6. 返回查询结果

## 查询操作方法

在之前的例子中，我们使用方法 `.findAll()` 来获取所有匹配对象。然而，还有其他几种查询操作方法：

| 方法             | 描述                                                                                                 |
| ---------------- | ---------------------------------------------------------------------------------------------------- |
| `.findFirst()`   | 返回第一个匹配条件的对象，若无匹配，则返回 `null`。                                                  |
| `.findAll()`     | 返回所有匹配条件的对象。                                                                             |
| `.count()`       | 返回匹配条件的对象数量。                                                                             |
| `.deleteFirst()` | 从 Collection 中删除第一个匹配条件的对象。                                                           |
| `.deleteAll()`   | 从 Collection 中删除所有匹配条件的对象。                                                             |
| `.build()`       | 将查询条件语句编译，以便重复使用。倘若你想要多次用到同一查询条件，你可以使用这个方法来避免重复代码。 |

## 查询属性

如果你只对单条属性的值感兴趣，你可以使用属性查询。创建一个查询然后选择想要的属性即可：

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

使用单个属性在反序列化中节省了很多时间。属性查询同样适用于嵌套对象和数组。

## 聚合查询（Aggregation）

Isar 支持对单个属性的聚合查询，为此提供了下表几种聚合查询操作方法：

| 操作         | 描述                                         |
| ------------ | -------------------------------------------- |
| `.min()`     | 返回最小值，若无匹配，则返回 `null`。        |
| `.max()`     | 返回最大值，若无匹配，则返回 `null`。        |
| `.sum()`     | 返回所有值的总和。                           |
| `.average()` | 返回所有值的平均值，若无匹配，则返回 `NaN`。 |

直接使用聚合查询比先找出对象，再做聚合运算快多了。

## 动态查询

:::danger
这部分很大可能与你无关。不鼓励使用动态查询，除非你绝对需要（往往你很少需要）。
:::

所有上述例子都使用了查询构造器 QueryBuilder 和由 Isar Generator 自动生成的静态扩充方法。你可能想要创建一个动态查询，或自定义的查询语言（就像 Isar Inspector 做的那样）。在这种情况下，你可以使用方法 `buildQuery()`：

| 参数            | 描述                                                                     |
| --------------- | ------------------------------------------------------------------------ |
| `whereClauses`  | 查询语句所需的 Where 子句                                                |
| `whereDistinct` | 是否设置 Where 子句对返回结果去重化（只有在使用单个 Where 子句时有用）。 |
| `whereSort`     | Where 子句的遍历顺序（只有在使用单个 Where 子句时有用）。                |
| `filter`        | 用来过滤查询结果的 Filter。                                              |
| `sortBy`        | 需要用来排序的属性列表。                                                 |
| `distinctBy`    | 需要用来去重化的属性列表。                                               |
| `offset`        | 查询结果的偏移量。                                                       |
| `limit`         | 返回查询结果的最大数量。                                                 |
| `property`      | 若非空，则只返回该属性的值。                                             |

让我们创建一个动态查询：

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

上述代码等价于以下代码：

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
