---
title: インデックス
---

# インデックス

インデックスは、Isar の最も強力な機能です。多くの組み込み型データベースは、"通常の"インデックスを提供していますが、Isar は複合インデックスやマルチエントリーインデックスも提供しています。
クエリのパフォーマンスを最適化するためには、インデックスがどのように機能するかを理解することが重要です。 Isar では、どのインデックスを、どのように使用するか事を選ぶ事が出来ます。

それではまず最初に、インデックスとは何かということを簡単に紹介します。

## インデックスとは？

コレクションにインデックスがない場合、行の順番はクエリによって最適化されていない可能性が高く、クエリはオブジェクトを直線的に検索しなければならなくなります。 言い換えれば、クエリはすべてのオブジェクトを検索して、条件にマッチするものを見つけなければならないのです。ご想像のとおり、これには時間がかかります。オブジェクトをひとつひとつ見ていくのは、あまり効率的ではありません。

例えば、この `Product` コレクションは完全に順不同です。

```dart
@collection
class Product {
  late int id;

  late String name;

  late int price;
}
```

**データ:**

| id  | name      | price |
| --- | --------- | ----- |
| 1   | Book      | 15    |
| 2   | Table     | 55    |
| 3   | Chair     | 25    |
| 4   | Pencil    | 3     |
| 5   | Lightbulb | 12    |
| 6   | Carpet    | 60    |
| 7   | Pillow    | 30    |
| 8   | Computer  | 650   |
| 9   | Soap      | 2     |

30 ユーロ以上の商品をすべて探そうとするクエリは、9 行すべてを検索しなければなりません。9 行では問題ないかもしれませんが、10 万行になると問題になるでしょう。

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

このクエリの性能を向上させるために、`price` プロパティにインデックスを付けます。インデックスとは、ソートされた検索テーブルのようなものです。:

```dart
@collection
class Product {
  late int id;

  late String name;

  @Index()
  late int price;
}
```

**生成されたインデックス:**

| price                | id                 |
| -------------------- | ------------------ |
| 2                    | 9                  |
| 3                    | 4                  |
| 12                   | 5                  |
| 15                   | 1                  |
| 25                   | 3                  |
| 30                   | 7                  |
| <mark>**55**</mark>  | <mark>**2**</mark> |
| <mark>**60**</mark>  | <mark>**6**</mark> |
| <mark>**650**</mark> | <mark>**8**</mark> |

これで、クエリの実行がかなり速くなりました。エクゼキュータは、最後の 3 つのインデックス行に直接ジャンプして、対応するオブジェクトをその ID で見つけることができます。

### ソート

もうひとつ素晴らしいのは、インデックスを使うと超高速でソートができることです。ソートを指示するクエリは、ソートをする前にデータベースが全ての結果をメモリにロードする必要があるため、コストがかかります。offset や limit を指定しても、それはソート後に適用されます。

例えば、最も安い商品を 4 つ見つけたいとします。次のようなクエリを使うことができます：

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

この例では、データベースはすべての(！)オブジェクトを読み込み、それらを価格順にソートして、最も安い価格の 4 つの製品を返さなければなりません。

想像がつくと思いますが、これは先ほどのインデックスを使えばもっと効率的に行えます。データベースはインデックスの最初の 4 行を受け取り、対応するオブジェクトを返します。なぜなら、これらはすでに適切な順番になっているからです。

インデックスをソートに使うには、次のようなクエリを書きます。

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

`.anyX()` という where 節は、Isar にソートのためだけにインデックスを使用するように指示します。また、`priceGreaterThan()`のような where 節を使用して、ソートされた結果を得ることもできます。

## ユニークインデックス

ユニークインデックス(一意な Index)は、インデックスが重複した値を含まないことを保証します。これは、1 つまたは複数のプロパティで構成されることがあります。ユニークインデックスが 1 つのプロパティを持つ場合、このプロパティの値は一意となります。ユニークインデックスが複数のプロパティを持つ場合、これらのプロパティの値の組み合わせは一意になります。

```dart
@collection
class User {
  late int id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

ユニークインデックスに重複を引き起こすデータを挿入または更新しようとすると、エラーになります:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> ok

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

// 同じユーザー名でユーザーを挿入しようとする。
await isar.users.put(user2); // -> エラー: 一意制約に反しています。
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## インデックスの置き換え

一意性制約に違反した場合にエラーを投げることが好ましくない場合もあります。エラーを投げる代わりに、既存のオブジェクトを新しいオブジェクトに置き換えたい場合があるかもしれまん。その場合は、インデックスの `replace` プロパティを `true` に設定することで実現できます。

```dart
@collection
class User {
  late int id;

  @Index(unique: true, replace: true)
  late String username;
}
```

これで、既存のユーザー名でユーザーを挿入しようとすると、Isar は既存のユーザーを新しいユーザーで置き換えます。

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1);
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
print(await isar.user.where().findAll());
// > [{id: 2, username: 'user1' age: 30}]
```

Replace インデックスは `putBy()` メソッドも生成し、オブジェクトを置き換えるのではなく、更新することができます。既存の ID は再利用され、リンクはそのまま反映されます。

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// ユーザーが存在しないので、put()と同じです。
await isar.users.putByUsername(user1);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

見ての通り、最初に挿入されたユーザーの id が再利用されています。

## 大文字小文字を区別しないインデックス

`String` と `List<String>` プロパティに対するすべてのインデックスは、デフォルトで大文字と小文字を区別して表示されます。大文字小文字を区別しないインデックスを作成したい場合は、 `caseSensitive` オプションを使用することができます。

```dart
@collection
class Person {
  late int id;

  @Index(caseSensitive: false)
  late String name;

  @Index(caseSensitive: false)
  late List<String> tags;
}
```

## インデックスの種類

インデックスにはさまざまな種類があります。ほとんどの場合、 `IndexType.value` インデックスを使用することになるでしょうが、Hash インデックスを使用するとより効率的です。

### Value インデックス

Value インデックスは既定の型であり、String や List を保持しないすべてのプロパティで許可される唯一のものです。インデックスを構築するために、プロパティの値が使用されます。List の場合は、List の要素が使用されます。これは、3 つのインデックスタイプの中で最も柔軟性がありますが、ストレージも消費します。

:::tip
基本データ型や、Strings(※where 節において `startsWith()` を使いたい場合)、そして Lists（※個別の要素を検索したい場合)においては IndexType.value を使用しましょう。
:::

### Hash インデックス

文字列や List をハッシュ化することで、インデックスに必要なストレージを大幅に削減することができます。Hash インデックスの欠点は、接頭辞の走査 (where 節における `startsWith` ) に使用できないことです。

:::tip
文字列や List に対して、 `startsWith` や `elementEqualTo` という where 節が必要ない場合は、 `IndexType.hash` を使用しましょう。
:::

### HashElements インデックス

文字列 List は、全体を (`IndexType.hash` を用いて) ハッシュ化することができますし、List の要素を個別に (`IndexType.hashElements` を用いて) ハッシュ化して、効率的に要素をハッシュ化したマルチエントリーインデックスを作成することができます。

:::tip
`List<String>` で `elementEqualTo` の where 節が必要な場合は、 `IndexType.hashElements` を使用します。
:::

## 複合インデックス

複合インデックスとは、複数のプロパティに対するインデックスのことです。Isar では、最大 3 つのプロパティのコンポジットインデックスを作成することができます。

複合インデックスは、複数列インデックスとも呼ばれます。

まず、例から始めるのが一番でしょう。person コレクションを作成し、age プロパティと name プロパティに複合インデックスを定義します。

```dart
@collection
class Person {
  late int id;

  late String name;

  @Index(composite: [CompositeIndex('name')])
  late int age;

  late String hometown;
}
```

**データ：**

| id  | name   | age | hometown  |
| --- | ------ | --- | --------- |
| 1   | Daniel | 20  | Berlin    |
| 2   | Anne   | 20  | Paris     |
| 3   | Carl   | 24  | San Diego |
| 4   | Simon  | 24  | Munich    |
| 5   | David  | 20  | New York  |
| 6   | Carl   | 24  | London    |
| 7   | Audrey | 30  | Prague    |
| 8   | Anne   | 24  | Paris     |

**生成されたインデックス：**

| age | name   | id  |
| --- | ------ | --- |
| 20  | Anne   | 2   |
| 20  | Daniel | 1   |
| 20  | David  | 5   |
| 24  | Anne   | 8   |
| 24  | Carl   | 3   |
| 24  | Carl   | 6   |
| 24  | Simon  | 4   |
| 30  | Audrey | 7   |

生成された複合インデックスは、年齢と名前でソートされたすべての人物を含んでいます。

複合インデックスは、複数のプロパティでソートされた効率的なクエリを作成したい場合に最適です。また、複数のプロパティを持つ高度な where 節も作成できます。

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

複合インデックスの末尾のプロパティは、 `startsWith()` や `lessThan()` といった条件もサポートします。

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## マルチエントリーインデックス

IndexType.value を使って List のインデックスを作成すると、Isar は自動的にマルチエントリーのインデックスを作成し、List 内の各項目がオブジェクトに対してインデックスされます。これはすべての型の List に対して機能します。

マルチエントリーインデックスの実用的な用途としては、タグの List のインデックス化や全文インデックスの作成などが挙げられます。

```dart
@collection
class Product {
  late int id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` は [Unicode Annex #29](https://unicode.org/reports/tr29/) の仕様に従って文字列を単語に分割するので、ほとんどすべての言語に対して正しく動作します。

**データ:**

| id  | description                  | descriptionWords             |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

重複する単語を含むエントリは、インデックスに一度だけ表示されます。

**生成されたインデックス:**

| descriptionWords | id        |
| ---------------- | --------- |
| comfortable      | [1, 2]    |
| blue             | 1         |
| necktie          | 4         |
| plain            | 3         |
| pullover         | 2         |
| red              | [2, 3, 4] |
| super            | 4         |
| t-shirt          | [1, 3]    |

これで、このインデックスは、個々の単語の接頭辞（または等号）を where 節に使用できるようになりました。

:::tip
単語を直接保存する代わりに、[Soundex](https://en.wikipedia.org/wiki/Soundex) のような [音声アルゴリズム](https://en.wikipedia.org/wiki/Phonetic_algorithm) を使用する事も候補に入れてみてください。
:::
