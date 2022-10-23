---
title: 快速开始
---

# 快速开始

我的天啊，你来了！让我们开始使用目前最酷的Flutter数据库吧……

在这个快速入门中，我们将用简洁的文字，尽可能直接使用代码来说明。

## 1. 添加依赖

在乐趣开始之前，我们需要在`pubspec.yaml`中添加一些依赖包。我们可以使用pub命令来为我们做这些繁琐的工作。

```bash
flutter pub add isar isar_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. 注解类

用`@collection`注解来标记你的集合类，并选择一个`Id`字段。

```dart
part 'email.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // 你也可以通过id = null来使用自增

  String? name;

  int? age;
}
```

ID 唯一地标识了集合中的对象，并允许你以后再次找到它们。

## 3. 运行代码生成器

执行以下命令来启动`build_runner`。

```
dart run build_runner build
```

如果你使用的是Flutter，请使用以下命令：

```
flutter pub run build_runner build
```

## 4. 打开Isar实例

打开一个新的Isar实例并传递你所有的集合模式。你可以选择指定一个实例名称和目录。

```dart
final isar = await Isar.open([EmailSchema]);
```

## 5. 写入和读取

一旦你的实例被打开，你就可以开始使用集合。

所有基本CRUD操作都可以通过`Isar集合`实现。

```dart
final newUser = User()..name = 'Jane Doe'..age = 36;

await isar.writeTxn(() async {
  await isar.users.put(newUser); // insert & update
});

final existingUser = await isar.users.get(newUser.id); // get

await isar.writeTxn(() async {
  await isar.users.delete(existingUser.id!); // delete
});
```

## 其它资源

你是一个习惯通过视频学习的人吗？请看这些视频来开始使用Isar吧。
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
