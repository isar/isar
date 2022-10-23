---
title: CRUD操作
---

# CRUD操作

当你定义了你的集合后，让我们来学习如何操作它们!

## 打开Isar

在你开始之前，我们需要一个Isar实例。每个实例都需要一个有写入权限的目录，用来存放数据库文件。如果你没有指定一个目录，Isar将为当前平台（platform）找到一个合适的默认目录。

接着你需要提供所有想在Isar实例中使用的模式（schema）。如果你打开了多个实例，你仍需要向每个实例提供相同的模式列表。

```dart
final isar = await Isar.open([RecipeSchema]);
```

你可以使用默认配置或提供以下参数：

| 配置 | 描述 |
| --| -------------|
| `name` | 用不同的名字打开多个实例。默认情况下，使用`"default"`。 |
| `directory` | 该实例的存储位置。默认情况下，iOS使用`NSDocumentDirectory`，Android使用`getDataDirectory`。而网页则不是必须的。 |
| `relaxedDurability` | 放宽持久性保证以提高写入性能。在系统崩溃（不是应用程序崩溃）的情况下，有可能丢失最后提交的事务。但并不会发生数据损坏。  |
| `compactOnLaunch` | 该选项控制是否在打开实例时压缩（compacted）数据库。 |
| `inspector` | 启用调试（debug）构建（build）的检查器（Inspector）。对于性能调试（profile）和发布（release）版本的构建，这个选项会被忽略。 |

如果一个实例已经被打开，调用`Isar.open()`将返回现有的实例，且不论指定的参数是什么。这对在isolate中使用Isar很有帮助。

:::tip
请考虑使用[path_provider](https://pub.dev/packages/path_provider)软件包来获得所有平台上的有效路径。
:::

数据库文件的存储位置是`directory/name.isar`。

## 从数据库中读取

请使用`IsarCollection`实例来在Isar中查询和创建某一类型的对象。

在以下例子中，假设我们有一个集合`Recipe`，定义如下：

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### 获取集合

你所有的集合都在Isar实例中。你可以通过以下方式获得Recipe集合：

```dart
final recipes = isar.recipes;
```

多简单! 如果你不想使用集合访问器（accessor），你也可以使用`collection()`方法：

```dart
final recipes = isar.collection<Recipe>();
```

### 通过id获取单个对象

目前我们的集合中还没有数据，但假装我们有的话，我们可以通过id`123`获得一个假想的对象。

```dart
final recipe = await isar.recipes.get(123);
```

`get()`返回一个含有该对象的`Future`，如果该对象不存在则返回`null`。所有的Isar操作默认都是异步的，而且大部分对应都有一个同步的操作：

```dart
final recipe = isar.recipes.getSync(123);
```

:::warning
在UI isolate中，你应该默认使用异步版本的方法。不过由于Isar的速度非常快，使用同步版本通常也是可以接受的。
:::

如果你想一次获得多个对象，使用`getAll()`或`getAllSync()`。

```dart
final recipe = await isar.recipes.getAll([1, 2]);
```

### 查询多个对象

除了按id获取对象外，你也可以使用`.where()`和`.filter()`查询符合特定条件的对象列表。

```dart
final allRecipes = await isar.recipes.where().findAll();

final favouires = await isar.recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ 学习更多知识：[查询](queries)

## 修改数据库

终于到了修改我们的集合的时候了! 要创建、更新或删除对象，请把相关的操作包含在一个写事务中。

```dart
await isar.writeTxn(() async {
  final recipe = await isar.recipes.get(123)

  recipe.isFavorite = false;
  await isar.recipes.put(recipe); // 执行更新操作

  await isar.recipes.delete(123); // 或者删除操作
});
```

➡️ 学习更多知识：[事务](transactions)

### 插入对象

想要在Isar中持久化一个对象，则需要把它插入一个集合中。Isar的`put()`方法将插入或更新该对象，这取决于它是否已经存在于集合中。

如果id字段是`null`或`Isar.autoIncrement`，Isar会使用自增的id。

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await isar.recipes.put(pancakes);
})
```

如果`id`字段不是final的，则Isar将自动为该对象分配id。

一次插入多个对象也同样简单。

```dart
await isar.writeTxn(() async {
  await isar.recipes.putAll([pancakes, pizza]);
})
```

### 更新对象

创建和更新都是通过`collection.put(object)`进行的。如果id是`null`（或不存在）则插入对象，否则更新对象。

因此，如果我们想取消对煎饼菜谱的收藏，我们可以这样做：

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await isar.recipes.put(recipe);
});
```

### 删除对象

想在Isar中删除一个对象？请使用`collection.delete(id)`。删除方法返回是否找到并删除了对应id的对象。例如你想删除id为`123`的对象，你可以这样做：

```dart
await isar.writeTxn(() async {
  final success = await isar.recipes.delete(123);
  print('Recipe deleted: $success');
});
```

与get和put类似，也有一个批量返回删除对象的数量的删除操作。

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

如果你不知道你要删除的对象的ID，你可以使用查询：

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
