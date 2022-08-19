---
title: Create, Read, Update, Delete
---

# Create, Read, Update, Delete

When you have your Collections defined, learn how to manipulate them!

## Opening Isar

Before you can do anything, you have to open an Isar instance. Each instance needs a directory with write permission.

```dart
final isar = await Isar.open(
  schemas: [ContactSchema],
  directory: 'some/directory',
);
```

You can use the default config or provide some of the following parameters.

| Config              | Description                                                                                                                                                                                                                      |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`              | You can open multiple instances with distinct names. By default, `"isar"` is used.                                                                                                                                               |
| `schemas`           | A list of all collection schemas you want to use. All instances need to use the same schemas.                                                                                                                                    |
| `directory`         | The storage location for this instance. You can pass a relative or absolute path. By default, `NSDocumentDirectory` is used for iOS and `getDataDirectory` for Android. The final location is `path/name`. Not required for web. |
| `relaxedDurability` | Relaxes the durability guarantee to increase write performance. In case of a system crash (not app crash), it is possible to lose the last committed transaction. Corruption is not possible                                     |

You can either store the Isar instance in a global variable or use your favorite dependency injection package to manage it.

If an instance is already open, calling `Isar.open()` will yield the existing instance regardless of the specified parameters. That's useful for using isar in an isolate.

:::tip
Consider using the [path_provider](https://pub.dev/packages/path_provider) package to get a valid path on all platforms.
:::

## Collections

The Collection object is how you find, query, and create new records of a given type.

### Get a collection

All your collections live in the Isar instance. Remember the `Contact` class we annotated before with `@Collection()`. You can get the contacts collection with:

```dart
final contacts = isar.contacts;
```

That was easy!

### Get a record (by id)

```dart
final contact = await contacts.get(someId);
```

`get()` returns a `Future`. All Isar operations are asynchronous by default. Most operations have a synchronous counterpart:

```dart
final contact = contacts.getSync(someId);
```

:::tip
It is recommended to use the asynchronous version of the method in your UI isolate. Since Isar is very fast, it is often fine to use the synchronous version.
:::

### Query records

Find a list of records matching given conditions using `.where()` and `.filter()`:

```dart
final allContacts = await contacts.where().findAll();

final starredContacts = await contacts.filter()
  .isStarredEqualTo(true)
  .findAll();
```

➡️ Learn more: [Queries](queries)

## Modifying the database

To create, update, or delete records, use the respective operations wrapped in a write transaction:

```dart
await isar.writeTxn(() async {
  final contact = await contacts.get(someId)

  contact.isStarred = false;
  await contacts.put(contact); // perform update operations

  await contacts.delete(contact.id); // or delete operations
});
```

➡️ Learn more: [Transactions](transactions)

### Create a new record

When an object is not yet managed by Isar, you need to `.put()` it into a collection. If the id field is `null`, Isar will use an auto-increment id.

```dart
final newContact = Contact()
  ..firstName = "Albert"
  ..lastName = "Einstein"
  ..isStarred = true;
await isar.writeTxn(() async {
  await contacts.put(newContact);
})
```

Isar will automatically assign the new id to the object if the `id` field is not read-only.

### Update a record

Both creating and updating works with `yourCollection.put(yourObject)`. If the id is null (or does not exist), the object is inserted, otherwise it is updated.

### Delete records

```dart
await isar.writeTxn(() async {
  contacts.delete(contact.id);
});
```

or:

```dart
await isar.writeTxn(() async {
  final idsOfUnstarredContacts = await contacts.filter()
    .isStarredEqualTo(false)
    .idProperty()
    .findAll();

  contacts.deleteAll(idsOfUnstarredContacts);
});
```
