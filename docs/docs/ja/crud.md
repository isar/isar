---
title: CRUD操作
---

# CRUD操作

コレクションを定義したら、それを操作する方法を学びましょう。

## Isarを開く

何をするにしても、まずはIsarのインスタンスが必要です。各インスタンスには、データベースファイルを格納することができる書き込み権限のあるディレクトリが必要になります。ディレクトリを指定しない場合、Isarは現在のプラットフォームに適したデフォルトのディレクトリを見つけます。

Isarインスタンスで使用したいすべてのスキーマを指定します。複数のインスタンスを開いている場合でも、それぞれのインスタンスに同じスキーマを与える必要があります。

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [ContactSchema],
  directory: dir.path,
);
```

加えて、デフォルト設定を使用するか、もしくは以下のいくつかのパラメータを指定することができます:

| Config |  Description |
| -------| -------------|
| `name` | 複数のインスタンスを別々の名前で開きます。デフォルトでは、`"default"` が使用されます。 |
| `directory` | このインスタンスの保存場所です。相対パスまたは絶対パスを渡すことができます。デフォルトでは、iOS では `NSDocumentDirectory` が、Android では `getDataDirectory` が使用されます。Webにおいては必要ありません。 |
| `relaxedDurability` | 書き込み性能を向上させるために耐久性保証を緩和します。 アプリケーションのクラッシュではなく、システムクラッシュの場合、最後にコミットしたトランザクションが失われる可能性があります。破損する可能性はありません。 |
| `compactOnLaunch` | インスタンスを開く際にデータベースの圧縮を行うかどうかを確認するための条件です。 |
| `inspector` | デバッグビルドでインスペクターを有効にします。プロファイルとリリースビルドでは、このオプションは無視されます。 |

既にインスタンスが開かれている場合に `Isar.open()` を呼び出すと、指定したパラメータに関係なく既存のインスタンスを取得します。これはIsarをアイソレートで使用する場合に便利です。

:::tip
すべてのプラットフォームで有効なパスを取得するために、[path_provider](https://pub.dev/packages/path_provider)パッケージの使用を検討してください。
:::

データベースファイルの保存場所は `directory/name.isar` です。

## データベースからの読み込み

`IsarCollection` インスタンスを使用して、Isar で指定した型のオブジェクトを検索したり、照会したり、新規に作成したりすることができます。

これ以降のサンプルコードでは、コレクション `Recipe` が以下のように定義されていると仮定した上で述べて行きます。

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### コレクションの取得

すべてのコレクションは、Isarインスタンスに格納されています。あなたはrecipesコレクションを次のように取得できます:

```dart
final recipes = isar.recipes;
```

簡単ですよね？ コレクションアクセサを使いたくない場合は、`collection()` メソッドを使うこともできます:

```dart
final recipes = isar.collection<Recipe>();
```

### idを用いたオブジェクトの取得

まだコレクションにデータはありませんが、あるものと仮定して、 `123` という ID の架空のオブジェクトを取得してみましょう。

```dart
final recipe = await recipes.get(123);
```

`get()` はオブジェクトを含む `Future` を返しますが、オブジェクトが存在しない場合は `null` を返します。 Isar のすべての操作はデフォルトでは非同期ですが、ほとんどの操作には同期処理も対応しています:

```dart
final recipe = recipes.getSync(123);
```

:::warning
UIアイソレートでは、非同期バージョンのメソッドをデフォルトで使用する必要があります。ちなみに、Isarは非常に高速なので、多くの場合において同期バージョンを使用しても問題ありません。
:::

複数のオブジェクトを一度に取得したい場合は、 `getAll()` または `getAllSync()` を使用してください：

```dart
final recipe = await recipes.getAll([1, 2]);
```

### オブジェクトのクエリ

IDでオブジェクトを取得する代わりに、 `.where()` と `.filter()` を使って特定の条件に一致するオブジェクトのリストを取得することもできます:

```dart
final allRecipes = await recipes.where().findAll();

final favouires = await recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ 詳しくはこちら: [クエリ](queries)

## データベースの書き換え

いよいよコレクションを書き換えるときがやってきました！ オブジェクトを作成、更新、削除するには、それぞれの操作をWriteトランザクション内でラップして使用します:

```dart
await isar.writeTxn(() async {
  final recipe = await recipes.get(123)

  recipe.isFavorite = false;
  await recipes.put(recipe); // 更新操作の実行

  await recipes.delete(123); // 削除操作の実行
});
```

➡️ 詳しくはこちら: [トランザクション](transactions)

### オブジェクトの挿入

Isar でオブジェクトを永続化するには、コレクションにオブジェクトを挿入(put)します。

Isar の `put()` メソッドは、そのオブジェクトが既にコレクションに存在するかどうかに応じて、オブジェクトの挿入もしくは更新を行います。

この時、id フィールドが `null` または `Isar.autoIncrement` の場合、Isar はオートインクリメントの id を使用します。

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await recipes.put(pancakes);
})
```

Isarは `id` フィールドがfinalでは無い場合、オブジェクトに自動的にidを割り当てます。

複数のオブジェクトを一度に挿入することも簡単です。

```dart
await isar.writeTxn(() async {
  await recipes.putAll([pancakes, pizza]);
})
```

### オブジェクトの更新

作成と更新の両方は `collection.put(object)` で行います。id が `null` (または存在しない) 場合はオブジェクトは挿入され、そうでない時は更新されます。

つまり、pancakesをunfavoriteにしたい場合は、以下のようになります:

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await recipes.put(recipe);
});
```

### オブジェクトの削除

オブジェクトを削除したい場合は、`collection.delete(id)`を使用してください. delete メソッドは、指定された id を持つオブジェクトを見つけて、それを削除したかどうかを返します。例えば、id が `123` のオブジェクトを削除したい場合、以下のようになります。

```dart
await isar.writeTxn(() async {
  final success = await recipes.delete(123);
  print('Recipe deleted: $success');
});
```

getやputと同様に、削除されたオブジェクトの数を返す一括削除命令も存在します：

```dart
await isar.writeTxn(() async {
  final count = await recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

削除したいオブジェクトのidが分からない場合は、クエリを使用することができます:

```dart
await isar.writeTxn(() async {
  final count = await recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
