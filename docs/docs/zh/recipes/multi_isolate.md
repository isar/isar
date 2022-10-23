---
title: 多Isolate的用法
---

# 多Isolate的用法

所有的Dart代码都在isolate内运行，而不是线程。每个isolate都有自己的内存堆，以确保isolate中的任何状态都无法从其他isolate访问。

Isar可以同时从多个isolate被访问，甚至监听器也可以跨isolate工作。在本使用技巧中，我们将看看如何在多isolate环境中使用Isar。

## 何时使用多个isolate

即使Isar事务在同一个isolate中运行，它们也会以并行方式执行。在某些情况下，从多个isolate访问Isar仍然是有好处的。

原因是Isar在对Dart对象的数据进行编码和解码时花费了不少时间。你可以把它看作是对JSON的编码和解码（只是效率更高）。这些操作在访问数据的isolate内运行，自然会阻止isolate内的其他代码。换句话说。Isar在你的Dart isolate中执行一些工作。

如果你只需要一次读取或写入几百个对象，那么在UI isolate中进行操作是没有问题的。但是对于巨大的事务，或者如果UI线程已经很忙了，你应该考虑使用一个单独的isolate。

## 例子

我们需要做的第一件事是在新的isolate中打开Isar。由于Isar的实例已经在主isolate中打开，`Isar.open()`将返回相同的实例。

:::warning
请确保提供与主isolate中相同的模式（schema）。否则，你会得到一个错误。
:::

`compute()`在Flutter中启动一个新的isolate，并在其中运行指定的函数。

```dart
void main() {
  // 在UI isolate中打开Isar
  final isar = await Isar.open(
    [MessageSchema]
    name: 'myInstance',
  );

  // 监听数据库变化
  isar.messages.watchLazy(() {
    print('omg the messages changed!');
  });

  // 启动新的isolate并添加10000条消息
  compute(createDummyMessages, 10000).then(() {
    print('isolate finished');
  });

  // 过了一会之后打印:
  // > omg the messages changed!
  // > isolate finished
}

// 准备在新的isolate中执行的函数
Future createDummyMessages(int count) async {
  // 我们不需要path参数，因为Isar已经被打开过了
  final isar = await Isar.open(
    [PostSchema],
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Message $i');
  // 我们在isolate中使用同步方法
  isar.writeTxnSync(() {
    isar.messages.insertAllSync(messages);
  });
}
```

在上面的例子中，有几件有趣的事情需要注意。

- `isar.messages.watchLazy()`在UI isolate中被调用，并被通知来自另一个isolate的变化。
- 实例是通过名称来引用的。默认名称是`default`，但在本例中，我们将其设置为`myInstance`。
- 我们使用了一个同步事务来创建消息。我们的新的isolate被阻塞（blocked）是没有问题的，而且同步事务的速度也比较快。
