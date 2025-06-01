---
title: Multi-Isolateの使用法
---

# Multi-Isolate の使用法

スレッドの代わりに、すべての Dart のコードはアイソレートの内部で実行されます。それぞれのアイソレートは独自のメモリヒープを持ち、アイソレート内のどのステートも他のアイソレートからアクセスできないことを保証しています。

Isar は同時に複数のアイソレートからアクセスすることができ、ウォッチャーもアイソレートをまたいで動作します。このレシピでは、複数のアイソレート環境で Isar を使用する方法を確認します。

## いつ Multi-Isolate を使用すべきか

Isar のトランザクションは、同じアイソレートで実行されても並列に実行されます。そうだとしても、場合によっては、複数のアイソレートから Isar にアクセスすることが 有益なこともあります。

その理由は、Isar は Dart オブジェクトとの間でデータのエンコードとデコードにかなりの時間を費やしているからです。これは JSON のエンコードとデコードのようなものだと考えることができます。（ただ、より効率的です）これらの操作は、データがアクセスされるアイソレートの内部で実行され、当然アイソレート内の他のコードをブロックします。言い換えれば Isar はあなたの Dart アイソレートで作業の一部を実行します。

一度に数百のオブジェクトを読み書きする必要があるだけなら、UI アイソレートで行うことは問題ではありません。しかし、巨大なトランザクションや、UI スレッドがすでに Busy 状態である場合は、別のアイソレートを使用することを検討する必要があります。

## 具体例

まず最初に行うべきことは、新しいアイソレートで Isar をオープンすることです。Isar のインスタンスは既にメインとなるアイソレートで開かれているので、 `Isar.open()` は同じインスタンスを返します。

:::warning
メインアイソレートと同じスキーマを提供することを忘れないでください。そうでない場合は、エラーになります。
:::

`compute()` は Flutter で新しいアイソレートを開始し、その中で与えられた関数を実行します。

```dart
void main() {
  // UIアイソレートでIsarを開く
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.openAsync(
    schemas: [MessageSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  // データベースの変更を監視する
  isar.messages.watchLazy(() {
    print('omg the messages changed!');
  });

  // 新しいアイソレートを開始し、10000メッセージを作成します。
  compute(createDummyMessages, 10000).then(() {
    print('isolate finished');
  });

  // しばらくすると:
  // > omg the messages changed!
  // > isolate finished
}

// 新しいアイソレート内で実行される関数
Future createDummyMessages(int count) async {
  // インスタンスはすでに開かれているので、ここではPathは必要ありません。
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.openAsync(
    schemas: [PostSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Message $i');
  // アイソレート内で同期トランザクションを使用する。
  isar.writeTxnSync(() {
    isar.messages.insertAllSync(messages);
  });
}
```

上記の例の中で、いくつか興味深い点があります:

- `isar.messages.watchLazy()` は UI アイソレートで呼び出されていますが、他のアイソレートからの変更についても通知されている。
- インスタンスは名前(name)で参照されます。デフォルトの名前は `default` ですが、この例では `myInstance` に設定しました。
- メッセージを作成するために同期トランザクションを使用しました。新しいアイソレートをブロックすることは問題ありませんし、同期トランザクションは少し速くなります。
