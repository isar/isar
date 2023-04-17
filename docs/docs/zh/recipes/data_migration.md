---
title: 数据迁移
---

# 数据迁移

当你添加或删除 Collection、或其字段或索引时，Isar 会自动为你的数据库 Schema 做数据迁移。有时候你可能想要自行迁移。Isar 没有提供相关函数，因为这么做会给数据迁移强行加了限制。根据自己的需求来自由实现迁移功能其实很简单。

在下方的例子中，我们希望使用整个数据库的单一版本。我们用 shared_preferences 这个库来保存当下的版本，然后跟我们要迁移的版本做比较。如果两个版本不匹配，那么就迁移数据，更新版本。

:::tip
你也可以给每个 Collection 分配单独的版本，然后单独为它们各自做数据迁移。
:::

假设我们有一个用户 Collection，它包含一个出生日 birthday 字段。在我们第二版 App 中，我们需要根据用户年龄来查询用户，就必须添加额外的出生年份字段。

版本 1：

```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;
}
```

版本 2：

```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

可问题是现有的用户数据中不会有 `birthYear` 这个字段的信息，因为它在版本 1 中不存在。我们需要借用数据迁移来为 `birthYear` 字段赋值。

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
      // 如果版本未设置（新建的时候）或已经是版本 2，我们就不做处理
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // 更新版本
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // 我们对用户数据进行分页读写，避免同时将所有数据存放到内存
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // 我们不需要更新任何信息，因为 birthYear 的 getter 已经被使用
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
如果你需要迁移大量数据，考虑在后台使用另一个 isolate 来处理，以防止对 UI 进程造成阻塞。
:::
