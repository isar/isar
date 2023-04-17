---
title: 快速开始
---

# 快速开始

嗨，你可终于来啦！让我们开始使用 Flutter 生态中最酷的数据库吧...

废话不多说，让我们来看代码。

## 1. 添加依赖

在开始之前，我们需要在 `pubspec.yaml` 文件中添加若干依赖，可以运行以下命令帮助我们完成：

```bash
flutter pub add isar isar_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. 给类添加注解

用 `@collection` 给你的 Collection 类添加注解，并指定一个 `Id` 字段。

```dart
part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // 你也可以用 id = null 来表示 id 是自增的

  String? name;

  int? age;
}
```

Id 唯一指向了 Collection 中的对象，之后我们可通过 Id 来查询这些对象。

## 3. 运行代码生成器

对于纯 Dart 项目，通过以下命令来执行 `build_runner`：

```
dart run build_runner build
```

倘若你的项目用到了 Flutter，可用下方命令来代替：

```
flutter pub run build_runner build
```

## 4. 创建一个 Isar 实例

创建一个新的 Isar 实例，并将你想保存到 Isar 的所有 collection 的 schema（它在上一步由 Isar Generator 根据你定义的 collection 自动生成） 作为参数传入。你还可以指定实例的名称以及它所存储数据的文件路径。

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [UserSchema],
  directory: dir.path,
);
```

## 5. 读写操作

当实例被创建后，我们就可以使用它了。

可以通过 `IsarCollection` 来调用所有 CRUD 方法。

```dart
final newUser = User()..name = 'Jane Doe'..age = 36;

await isar.writeTxn(() async {
  await isar.users.put(newUser); // 将新用户数据写入到 Isar
});

final existingUser = await isar.users.get(newUser.id); // 通过 Id 读取用户数据

await isar.writeTxn(() async {
  await isar.users.delete(existingUser.id!); // 通过 Id 删除指定用户
});
```

## 其他资源

你倾向于通过视频来学习？不妨查看下方一些资源吧：

<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/CwC9-a9hJv4" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/videoseries?list=PLKKf8l1ne4_hMBtRykh9GCC4MMyteUTyf" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/pdKb8HLCXOA " title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
