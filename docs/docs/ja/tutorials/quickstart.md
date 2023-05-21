---
title: クイックスタート
---

# クイックスタート

お待たせしました。さあ、最高にクールなFlutterのデータベースを使い始めましょう！

この記事では、簡潔にコードを書いていきます。


## 1. 依存関係を追加する

Isarを使用する前に、いくつかのパッケージを `pubspec.yaml` に追加する必要があります。pubを使用する事で、面倒な作業を簡単に済ませることが出来ます。

```bash
flutter pub add isar isar_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. クラスの注釈(アノテーション)

あなたの使用するコレクションクラスに `@collection` でアノテーションを付け、`Id` フィールドを設定します。

```dart
part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // id = nullでも自動インクリメントされます。

  String? name;

  int? age;
}
```

idはコレクション内のオブジェクトを一意に識別して、後で再び見つけられるようにします。

## 3. コード生成ツールの実行

以下のコマンドを実行して、`build_runner`を起動します。:

```
dart run build_runner build
```

Flutterを使用している場合は、代わりに次のコマンドを使用してください:

```
flutter pub run build_runner build
```

## 4. Isarインスタンスを開く

新規のIsarインスタンスを開き、コレクションのスキーマを渡します。必要に応じて、インスタンス名とディレクトリを指定することができます。

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [UserSchema],
  directory: dir.path,
);
```

## 5. 書き込みと読み込み

Isarインスタンスを開いたら, コレクションを利用することができます.

基本的なCRUD操作は、全て `IsarCollection` を介して行う事が出来ます。

```dart
final newUser = User()..name = 'Jane Doe'..age = 36;

await isar.writeTxn(() async {
  await isar.users.put(newUser); // 挿入と更新
});

final existingUser = await isar.users.get(newUser.id); // 取得

await isar.writeTxn(() async {
  await isar.users.delete(existingUser.id!); // 削除
});
```

## その他の資料

視覚的に学ぶ方が好みであれば、Isarを始めるためにこれらの動画をぜひご覧ください:
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
