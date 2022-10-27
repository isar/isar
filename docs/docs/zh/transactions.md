---
title: 事务
---

# 事务（Transaction）

在 Isar 中，事务将多条数据库操作序列合并成单个逻辑单位。大多数与 Isar 的交互都隐式用到了事务。Isar 的读写操作是兼容 [ACID](http://en.wikipedia.org/wiki/ACID) 特性的。倘若错误发生，事务会自动回滚。

## 显式事务

在显式事务中，你会得到连续的数据库快照。尝试缩短事务的持续时长。禁止在事务中访问网络或做其他需长时间运行的操作。

事务（特别是写入事务）的确有性能损耗，你应该尽可能将连续的操作序列并入到单一事务。

事务要么是同步的，要么是异步的。在同步事务中，你只能使用同步操作。类似地，在异步事务中只能使用异步操作。

|      | 读取         | 读写              |
| ---- | ------------ | ----------------- |
| 同步 | `.txnSync()` | `.writeTxnSync()` |
| 异步 | `.txn()`     | `.writeTxn()`     |

### 读取事务

显式的读取事务是可选的，但是它们可以让你进行原子化读取并且依赖于事务执行过程中数据库的一致性。对于所有的读取操作，Isar 内部总是使用隐式的读取事务。

:::tip
异步的读取事务和其他读写事务是并行运行的。很酷，对吧？
:::

### 写入事务

不同于读取事务，在 Isar 中必须显式使用写入事务。

当一个写入事务成功完成后，它会自动提交，将所有修改写入到磁盘。如果有错误发生，事务就会被终止，所有修改会被回滚。事务就是“应用所有修改或什么都不修改”：在一个成功执行的事务里执行所有修改，或什么都不修改来保证数据的一致性。

:::warning
当数据操作失败时，该事务会被终止。即使你在 Dart 中捕获到了错误，也不要再次使用该事务。
:::

```dart
@collection
class Contact {
  Id? id;

  String? name;
}

// 良好
await isar.writeTxn(() async {
  for (var contact in getContacts()) {
    await isar.contacts.put(contact);
  }
});

// 不好：要将循环放到事务里面
for (var contact in getContacts()) {
  await isar.writeTxn(() async {
    await isar.contacts.put(contact);
  });
}
```
