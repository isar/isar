---
title: 增删改查
---

# 增删改查（CRUD）

当你已经定义了 Collection，现在来学习如何对其操作。

## 创建一个 Isar 实例

首先我们必须创建一个 Isar 实例。每一个实例需要一个可写的路径来保存数据库文件。倘若你未指定路径，Isar 会根据当前设备所属平台来自动选择合适的默认路径。

将你想要使用的所有 Collection 的 Schema 作为参数传入到创建实例的方法中。如果你有多个实例，你仍然需要给每个实例配置相同的 Schema（即各个实例的 Schema 必须一致）。

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [RecipeSchema],
  directory: dir.path,
);
```

你可以使用默认配置，也可以根据下表修改参数：

| 参数配置            | 描述                                                                                                                              |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `name`              | 以不同名称创建多个实例。默认情况下，`"default"` 会被用作实例名称。                                                                |
| `directory`         | 该实例数据库文件的存储路径。默认情况下，iOS 是 `NSDocumentDirectory`，而 Android 则用 `getDataDirectory` 返回的结果，Web 端可选。 |
| `relaxedDurability` | 放宽可靠性来提高写入性能。倘若应用遇到系统崩溃（不是 App 的崩溃），允许丢弃最后一次提交的事务操作结果。数据库文件损毁是不可能的。 |
| `compactOnLaunch`   | 是否以数据库压缩的形式来启用实例。                                                                                                |
| `inspector`         | 在开发调试阶段启用检查器 Inspector。 对于 profile 和 release 版本，该参数会被忽略。                                               |

倘若一个实例已经被创建，调用 `Isar.open()` 会无视传入的参数，直接返回该实例。这使得在单一 isolate 内使用 Isar 会很有用。

:::tip
考虑使用 [path_provider](https://pub.dev/packages/path_provider) 来获取所有平台的有效路径。
:::

数据库文件的路径在 `directory/name.isar`。

## 从数据库中读取数据

对于给定类型，通过调用 `IsarCollection` 来查找、查询以及创建新的对象。

在下方的例子中，我们假定有一个 `Recipe` Collection，其定义如下：

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### 获取 Collection

你声明的所有 Collection 都存在于 Isar 实例中（只要它们的 Schema 在创建实例的时候被传入了）。你可以通过下面代码来读取菜单数据：

```dart
final recipes = isar.recipes;
```

就这么简单！如果你不想用 Collection 的访问名（这里即 recipes），也可以调用 `collection()` 方法：

```dart
final recipes = isar.collection<Recipe>();
```

### 通过 Id 来获取数据对象

我们的 Collection 中还没有数据。但是假设已有数据，我们可以通过以下代码来访问 Id 为 `123` 的菜单。

```dart
final recipe = await isar.recipes.get(123);
```

`get()` 返回一个包含对象的 `Future`，如果对象不存在，则返回 `null`。 默认情况下 Isar 所有的操作均为异步，而大部分操作也有其对应的同步处理方法，如：

```dart
final recipe = isar.recipes.getSync(123);
```

:::tip
因为 Isar 已经足够快了，所以你应该在 UI isolate 中尽可能使用默认的异步方法。当然使用对应的同步方法也是可接受的。
:::

如果你想要同时获取多个对象数据， 使用 `getAll()` 或 `getAllSync()`：

```dart
final recipe = await isar.recipes.getAll([1, 2]);
```

### 查询对象

除了通过 Id 来获取对象数据，你也可以通过 `.where()` 和 `.filter()` 来查询匹配指定条件的多个对象，其返回的是数组 List:

```dart
final allRecipes = await isar.recipes.where().findAll();

final favouires = await isar.recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ 学习更多：[查询](queries)

## 修改数据库

终于到了修改数据的时候了！ 在一个写入事务（Write Transaction）中使用对应的操作序列来创建、修改和删除对象：

```dart
await isar.writeTxn(() async {
  final recipe = await isar.recipes.get(123)

  recipe.isFavorite = false;
  await isar.recipes.put(recipe); // 修改数据

  await isar.recipes.delete(123); // 或者删除数据
});
```

➡️ 学习更多：[事务](transactions)

### 插入对象

通过插入对象到 Collection，即可保存其数据到 Isar 数据库中。 Isar 的`put()` 方法会创建或者覆盖对象数据，取决于该对象是否已经存在于数据库里。

如果一个字段是 `null` 或 `Isar.autoIncrement`，Isar 则会分配一个自增 Id 来表示。

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await isar.recipes.put(pancakes);
})
```

如果 `id` 不为 final， 那么 Isar 会自动将这个 Id 分配给该对象。

同时插入多个对象也很简单：

```dart
await isar.writeTxn(() async {
  await isar.recipes.putAll([pancakes, pizza]);
})
```

### 修改对象

`collection.put(object)` 方法兼有创建和修改的功能。如果一个对象的 Id 是 `null` （或者不存在），它就会被创建；否则，它就会被修改。

所以如果我们想要取消喜欢煎饼的话，可以做以下操作：

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await isar.recipes.put(recipe);
});
```

### 删除对象

想要从 Isar 数据库中删除一个对象？用 `collection.delete(id)` 方法。这个方法会返回指定对象是否被删除（即返回布尔值）。如果你想通过 Id 来删除指定菜单，比如其 Id 为 `123`，你可以用下方代码：

```dart
await isar.writeTxn(() async {
  final success = await isar.recipes.delete(123);
  print('Recipe deleted: $success');
});
```

相似地，也有对应的批量删除方法，其返回结果是被删除对象的数量：

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

如果你不知道你想删除对象的 Id，你可以先通过指定条件来查询：

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
