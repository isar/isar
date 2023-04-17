---
title: Data migration
---

# Data Migration

Isar automatically migrates your database schemas if you add or remove collections, fields, or indexes. Sometimes you might want to migrate your data as well. Isar does not offer a built-in solution because it would impose arbitrary migration restrictions. It is easy to implement migration logic that fits your needs.

We want to use a single version for the entire database in this example. We use shared preferences to store the current version and compare it to the version we want to migrate to. If the versions do not match, we migrate the data and update the version.

:::tip
You could also give each collection its own version and migrate them individually.
:::

Imagine we have a user collection with a birthday field. In version 2 of our app, we need an additional birth year field to query users based on age.

Version 1:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;
}
```

Version 2:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

The problem is the existing user models will have an empty `birthYear` field because it did not exist in version 1. We need to migrate the data to set the `birthYear` field.

```dart
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [UserSchema],
    directory: dir.path,
  );

  await performMigrationIfNeeded(isar);

  runApp(MyApp(isar: isar));
}

Future<void> performMigrationIfNeeded(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  final currentVersion = prefs.getInt('version') ?? 2;
  switch(currentVersion) {
    case 1:
      await migrateV1ToV2(isar);
      break;
    case 2:
      // If the version is not set (new installation) or already 2, we do not need to migrate
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // Update version
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // We paginate through the users to avoid loading all users into memory at once
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // We don't need to update anything since the birthYear getter is used
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
If you have to migrate a lot of data, consider using a background isolate to prevent strain on the UI thread.
:::
