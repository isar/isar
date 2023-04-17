---
title: Multi-Isolate 用法
---

# Multi-Isolate 用法

所有的 Dart 代码都是在 isolate 而不是线程中运行的。每个 isolate 都有它自己的内存，确保彼此之间互相隔离。

Isar 可同时用于多个 isolate，甚至观察者也支持跨多个 isolate。本专题将会探讨如何在多 isolate 环境下使用 Isar。

## 什么时候使用多个 isolate

Isar 事务即使在单 isolate 环境中也是并行运行的。但有些情况下，从多 isolate 环境访问 Isar 可能依然利大于弊。

因为 Isar 花费不少时间去对 Dart 对象进行编码和解码。你姑且可以将之类比成对 JSON 编码和解码（只不过实际性能更快）。这些操作都在读取数据的 isolate 中进行，当然会阻碍该 isolate 中其他代码的运行。也就是说：Isar 的确需要在你的 isolate 中做不少工作。

如果你同时需要读取或写入几百个对象数据，在 UI isolate 中这么做没有问题。但是如果 UI 已经很忙碌或事务操作量很大，你就应该考虑使用多个 isolate。

## 例子

首先我们在新的 isolate 中创建 Isar 实例。因为在主 isolate 中我们已经有一个 Isar 实例，所以调用方法 `Isar.open()` 会直接返回该实例。

:::warning
确保在主 isolate 中给实例传入相同的 Schema，否则会发生错误。
:::

`compute()` 创建一个新的 isolate，并运行传给它的函数。

```dart
void main() {
  // 在 UI isolate 中创建 Isar 实例
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [MessageSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  // 订阅数据库中消息表的变化
  isar.messages.watchLazy(() {
    print('omg the messages changed!');
  });

  // 创建一个新的 isolate，写入 10000 条讯息到数据库
  compute(createDummyMessages, 10000).then(() {
    print('isolate finished');
  });

  // 一段时间后，打印出：
  // > omg the messages changed!
  // > isolate finished
}

// 函数将会在新的 isolate 中被执行
Future createDummyMessages(int count) async {
  // 我们没必要在此指定路径，因为它已经被创建好了
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [PostSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Message $i');
  // 我们在 isolate 中使用了同步事务
  isar.writeTxnSync(() {
    isar.messages.insertAllSync(messages);
  });
}
```

上述例子中需要注意的几个点：

- `isar.messages.watchLazy()` 在 UI isolate 中被调用，接收来自另一个 isolate 中数据变化的通知。
- 实例之间用名称来辨别。默认实例名称为 `default`，但是在上面的示例中，我们将它命名为 `myInstance`。
- 我们在一个新 isolate 中使用了同步事务来写入讯息。阻塞这个 isolate 没什么问题，因为它不会影响到 UI isolate，而且同步事务相比异步更快。
