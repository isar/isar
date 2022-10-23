---
title: 数据迁移
---

# 数据迁移

如果你添加或删除集合、字段或索引，Isar会自动迁移你的数据库模式。有时你可能也想迁移你的数据。Isar没有提供一个内置的解决方案，因为它将施加很多迁移限制。实现符合你需求的迁移逻辑是很容易的。

在这个例子中，我们想对整个数据库使用单一的版本。我们使用共享首选项（shared preferences）来存储当前版本，并将其与我们想要迁移的版本进行比较。如果两个版本不匹配，我们就迁移数据并更新版本。

:::tip
你也可以给每个集合以自己的版本，并单独迁移它们。
:::

想象一下，我们有一个带有生日字段的用户集合。在我们应用程序的第二版中，我们需要一个额外的出生年份字段，以便根据年龄查询用户。

版本1:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;
}
```

版本2:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

问题是现有的用户模型将有一个空的`birthYear`字段，因为它在版本1中不存在。我们需要迁移数据以设置`birthYear'字段。

```dart
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final isar = await Isar.open([UserSchema]);

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
      // 如果版本没有设置（新数据）或已经是2，我们不需要迁移。
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // 更新版本
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // 我们对用户进行分页处理，以避免一次性将所有用户加载到内存中。
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // 因为birthYear的getter的存在，我们不需要更新任何东西。
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
如果你必须迁移大量的数据，可以考虑使用一个后台isolate来防止对UI线程的压力。
:::
