---
title: 事务
---

# 事务

在Isar中，事务将多个数据库操作结合在一个工作单元中。大多数与Isar的交互都隐含事务的使用。Isar的读写访问符合[ACID](http://en.wikipedia.org/wiki/ACID)。如果发生错误，事务会自动回滚。

## 显式事务

在一个显式事务中，你会得到一个具有一致性的（consistent）数据库快照。为了尽量减少事务的持续时间，禁止在事务中进行网络调用或其他耗时长的操作。

事务（尤其是写事务）是有成本的，你应该总是尝试将连续的操作统一归入单个事务。

事务可以是同步的，也可以是异步的。在同步事务中，你只能使用同步操作。在异步事务中，只能使用异步操作。

|     | 读            | 读和写               |
|-----|--------------|-------------------|
| 同步  | `.txnSync()` | `.writeTxnSync()` |
| 异步  | `.txn()`     | `.writeTxn()`     |


### 读事务

显式读事务是可选的，但它允许你进行原子式读，并依赖于事务内的数据库一致状态。在内部实现过程中，Isar总是对所有的读操作使用隐式读事务。

:::tip
异步读事务与其他读写事务并行运行。很酷，对吗？
:::

### 写事务

与读操作不同，Isar的写操作必须被包在一个显式事务中。

当一个写事务成功完成时，它被自动提交（commit），所有的改变都被写入磁盘。如果发生错误，事务就会被中止，所有的变化都会回滚。事务是 "全有或全无 "的：要么一个事务中的所有写入都成功，要么一个都不生效以保证数据的一致性。

:::warning
当数据库操作失败时，事务就会被中止，并且不得再被使用。即使你在Dart中捕捉了错误也不行。
:::

```dart
@collection
class Contact {
  Id? id;

  String? name;
}

// GOOD
await isar.writeTxn(() async {
  for (var contact in getContacts()) {
    await isar.contacts.put(contact);
  }
});

// BAD: move loop inside transaction
for (var contact in getContacts()) {
  await isar.writeTxn(() async {
    await isar.contacts.put(contact);
  });
}
```
