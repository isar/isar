---
title: 监听器（Watchers）
---

# 监听器（Watchers）

Isar允许你订阅数据库中的变化。你可以"监听"特定对象、整个集合或查询中的变化。

监听器使你能够对数据库中的变化做出有效的反应。例如，当一个联系人被添加时，你可以重建你的用户界面，当一个文件被更新时，发送一个网络请求，等等。

监听器在事务提交成功和目标实际发生变化后被触发。

## 监听对象

如果你想在一个特定的对象被创建、更新或删除时得到通知，你应该监听一个对象：

```dart
Stream<User> userChanged = isar.users.watchObject(5);
userChanged.listen((newUser) {
  print('User changed: ${newUser?.name}');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User changed: David

final user2 = User(id: 5)..name = 'Mark';
await isar.users.put(user);
// prints: User changed: Mark

await isar.users.delete(5);
// prints: User changed: null
```

正如你在上面的例子中看到的，这个对象还不需要存在。当它被创建时，监听器将被触发。

有一个额外的参数`fireImmediately`。如果你把它设置为`true`，Isar将立即把对象的当前值添加到流中。

### 惰性监听

也许你不需要接收新的值，而只是被通知有变化。这样就省去了Isar获取对象的麻烦：

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User 5 changed
```

## 监听集合

除了监听单个对象，你还可以观察整个集合，并在任何对象被添加、更新或删除时获得通知：

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// prints: A User changed
```

## 监听查询

我们甚至可以监听整个查询。Isar尽力只在查询结果实际改变时通知你。如果链接导致查询发生变化，你将不会得到通知。如果你需要得到链接变化的通知，请使用集合监听器。

```dart
Query<User> usersWithA = isar.users.filter()
    .nameStartsWith('A')
    .build();

Stream<List<User>> queryChanged = usersWithA.watch(fireImmediately: true);
queryChanged.listen((users) {
  print('Users with A are: $users');
});
// prints: Users with A are: []

await isar.users.put(User()..name = 'Albert');
// prints: Users with A are: [User(name: Albert)]

await isar.users.put(User()..name = 'Monika');
// no print

awaited isar.users.put(User()..name = 'Antonia');
// prints: Users with A are: [User(name: Albert), User(name: Antonia)]
```

:::warning
如果你使用了偏移量、限制返回数量和去重查询，即使当对象符合过滤条件但在查询返回列表之外，结果发生变化时，Isar也会通知你。
:::

就像`watchObject()`一样，你可以使用`watchLazy()`在查询结果改变时得到通知，但不获取结果。

:::danger
为每一个变化重新运行查询是非常低效的。最好是使用惰性的集合监听器。
:::
