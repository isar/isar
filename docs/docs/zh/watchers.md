---
title: 观察者
---

# 观察者（Watcher）

Isar 允许你订阅数据库中的变化。你可以“观察”单个对象、整个 Collection 或单个查询的变化。

观察者可以让你针对数据库中的变化高效地做出回应。例如，当一个联系人被添加之后，你可以重建 UI；或当一个文件被修改后，发送一个网络请求等等。

当事务成功被执行后，目标被修改，然后就会通知观察者。

## 观察对象

如果你想在某个对象被创建、修改或删除时收到通知，你可以通过下面代码观察该对象：

```dart
Stream<User> userChanged = isar.users.watchObject(5);
userChanged.listen((newUser) {
  print('User changed: ${newUser?.name}');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// 打印出：User changed: David

final user2 = User(id: 5)..name = 'Mark';
await isar.users.put(user);
// 打印出：User changed: Mark

await isar.users.delete(5);
// 打印出：User changed: null
```

如你所见，声明观察者的时候，Id 为 5 的对象还未被创建。一旦被创建，观察者就会收到通知。

还有一个参数 `fireImmediately`，如果你设置为 `true`，Isar 会立刻将该对象的当前值添加到 Stream 中。

### 懒观察

也许你不需要知道一个对象的最新值，只需了解其是否被修改过，那么可以用懒观察，这样 Isar 无需去读取该对象的值：

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// 打印出：User 5 changed
```

## 观察 Collection

除了观察单个对象，你也可以观察整个 Collection 中是否有对象被添加、修改或删除：

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// 打印出： A User changed
```

## 观察查询

甚至你也可以观察整个查询的结果是否发生变化。Isar 尽力只在查询结果真正发生变化时通知你。但是当由关联造成查询结果发生变化时，你不会收到任何通知。针对关联变化，你可以观察 Collection。

```dart
Query<User> usersWithA = isar.users.filter()
    .nameStartsWith('A')
    .build();

Stream<List<User>> queryChanged = usersWithA.watch(fireImmediately: true);
queryChanged.listen((users) {
  print('Users with A are: $users');
});
// 打印出：Users with A are: []

await isar.users.put(User()..name = 'Albert');
// 打印出：Users with A are: [User(name: Albert)]

await isar.users.put(User()..name = 'Monika');
// 无任何打印输出

awaited isar.users.put(User()..name = 'Antonia');
// 打印出：Users with A are: [User(name: Albert), User(name: Antonia)]
```

:::warning
如果你的查询使用了偏移量和限制，或者进行了去重化，即使是在查询结果范围之外的对象，若符合该查询条件，Isar 也会通知你查询结果发生了变化。
:::

就像观察对象的懒观察一样，你也可以使用 `watchLazy()` 来懒观察一条查询结果是否有变化，而无需去读取查询的结果。

:::danger
观察查询时返回每一个变动是十分低效的。尽量使用懒观察 Collection 来代替。
:::
