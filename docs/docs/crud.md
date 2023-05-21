---
title: Create, Read, Update, Delete
---

# Create, Read, Update, Delete

When you have your collections defined, learn how to manipulate them!

## Opening Isar

Before you can do anything, we need an Isar instance. Each instance requires a directory with write permission where the database file can be stored. If you don't specify a directory, Isar will find a suitable default directory for the current platform.

Provide all the schemas you want to use with the Isar instance. If you open multiple instances, you still have to provide the same schemas to each instance.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [RecipeSchema],
  directory: dir.path,
);
```

You can use the default config or provide some of the following parameters:

| Config              | Description                                                                                                                                                                                                                                                                                  |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`              | Open multiple instances with distinct names. By default, `"default"` is used.                                                                                                                                                                                                                |
| `directory`         | The storage location for this instance. Not required for web.                                                                                                                                                                                                                                |
| `maxSizeMib`        | The maximum size of the database file in MiB. Isar uses virtual memory which is not an endless resource so be mindful with the value here. If you open multiple instances they share the available virtual memory so each instance should have a smaller `maxSizeMib` . The default is 2048. |
| `relaxedDurability` | Relaxes the durability guarantee to increase write performance. In case of a system crash (not app crash), it is possible to lose the last committed transaction. Corruption is not possible                                                                                                 |
| `compactOnLaunch`   | Conditions to check whether the database should be compacted when the instance is opened.                                                                                                                                                                                                    |
| `inspector`         | Enabled the Inspector for debug builds. For profile and release builds this option is ignored.                                                                                                                                                                                               |

If an instance is already open, calling `Isar.open()` will yield the existing instance regardless of the specified parameters. That's useful for using Isar in an isolate.

:::tip
Consider using the [path_provider](https://pub.dev/packages/path_provider) package to get a valid path on all platforms.
:::

The storage location of the database file is `directory/name.isar`

## Reading from the database

Use `IsarCollection` instances to find, query, and create new objects of a given type in Isar.

For the examples below, we assume that we have a collection `Recipe` defined as follows:

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### Get a collection

All your collections live in the Isar instance. You can get the recipes collection with:

```dart
final recipes = isar.recipes;
```

That was easy! If you don't want to use collection accessors, you can also use the `collection()` method:

```dart
final recipes = isar.collection<Recipe>();
```

### Get an object (by id)

We don't have data in the collection yet but let's pretend we do so we can get an imaginary object by the id `123`

```dart
final recipe = await isar.recipes.get(123);
```

`get()` returns a `Future` with either the object or `null` if it does not exist. All Isar operations are asynchronous by default, and most of them have a synchronous counterpart:

```dart
final recipe = isar.recipes.getSync(123);
```

:::warning
You should default to the asynchronous version of methods in your UI isolate. Since Isar is very fast, it is often acceptable to use the synchronous version.
:::

If you want to get multiple objects at once, use `getAll()` or `getAllSync()`:

```dart
final recipe = await isar.recipes.getAll([1, 2]);
```

### Query objects

Instead of getting objects by id you can also query a list of objects matching certain conditions using `.where()` and `.filter()`:

```dart
final allRecipes = await isar.recipes.where().findAll();

final favorites = await isar.recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ Learn more: [Queries](queries)

## Modifying the database

It's finally time to modify our collection! To create, update, or delete objects, use the respective operations wrapped in a write transaction:

```dart
await isar.writeTxn(() async {
  final recipe = await isar.recipes.get(123)

  recipe.isFavorite = false;
  await isar.recipes.put(recipe); // perform update operations

  await isar.recipes.delete(123); // or delete operations
});
```

➡️ Learn more: [Transactions](transactions)

### Insert object

To persist an object in Isar, insert it into a collection. Isar's `put()` method will either insert or update the object depending on whether it already exists in the collection.

If the id field is `null` or `Isar.autoIncrement`, Isar will use an auto-increment id.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await isar.recipes.put(pancakes);
})
```

Isar will automatically assign the id to the object if the `id` field is non-final.

Inserting multiple objects at once is just as easy:

```dart
await isar.writeTxn(() async {
  await isar.recipes.putAll([pancakes, pizza]);
})
```

### Update object

Both creating and updating works with `collection.put(object)`. If the id is `null` (or does not exist), the object is inserted; otherwise, it is updated.

So if we want to unfavorite our pancakes, we can do the following:

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await isar.recipes.put(pancakes);
});
```

### Delete object

Want to get rid of an object in Isar? Use `collection.delete(id)`. The delete method returns whether an object with the specified id was found and deleted. If you want to delete the object with id `123`, for example, you can do:

```dart
await isar.writeTxn(() async {
  final success = await isar.recipes.delete(123);
  print('Recipe deleted: $success');
});
```

Similarly to get and put, there is also a bulk delete operation that returns the number of deleted objects:

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

If you don't know the ids of the objects you want to delete, you can use a query:

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
