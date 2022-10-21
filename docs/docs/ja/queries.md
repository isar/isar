---
title: クエリ
---

# クエリ

クエリとは、ある条件に合致するレコードを探し出す方法です。例えば:

- 星付きの連絡先をすべて検索
- 連絡先の名前を個別に検索する
- 姓が定義されていないすべての連絡先を削除する

クエリはDart内ではなくデータベース上で実行されるため、非常に速く実行することができます。インデックスを巧みに使えば、クエリの性能をさらに向上させることができます。
以降では、クエリの記述方法と、クエリを可能な限り高速化する方法について学びます。

レコードを絞り込むには、2種類の方法があります。フィルタとWHERE節です。まず、フィルターがどのように機能するかを見てみましょう。

## フィルタ

フィルタは使いやすく、わかりやすいです。プロパティの種類に応じて、さまざまなフィルタリング処理が用意されており、そのほとんどが一目でわかるような名前になっています。

フィルタは、フィルタリングされるコレクション内のすべてのオブジェクトに対して評価式を適用することで動作します。式の結果が `true` であった場合、Isar はそのオブジェクトを結果に含めます。フィルタは結果の順序に影響を与えません。

これから紹介する例では、次のようなモデルを使用します:

```dart
@collection
class Shoe {
  Id? id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### クエリの条件

フィールドの種類に応じて、利用可能な条件が異なります。

| Condition | Description |
| ----------| ------------|
| `.equalTo(value)` | 指定した `value` と等しい値に一致する。 |
| `.between(lower, upper)` | `lower` と `upper` の間にある値に一致する。 |
| `.greaterThan(bound)` | `bound` よりも大きい値に一致する。 |
| `.lessThan(bound)` | `bound` よりも小さい値に一致する。デフォルトでは `null` の値も含まれる。なぜなら `null` は他のどの値よりも小さいとみなされるからである。 |
| `.isNull()` | `null` に一致する。|
| `.isNotNull()` | `null` ではない値に一致する。|
| `.length()` | List、String、linkの長さのクエリは、Listやlinkの要素数に基づいてオブジェクトをフィルタリングする。 |

ここでは、データベースにsizeが39、40、46のshoeとサイズが設定されていない（`null`）1つのshoeの合計４つが含まれていると仮定します。ソートを行わない限り、値は id でソートされて返されます。

```dart

isar.shoes.filter()
  .sizeLessThan(40)
  .findAll() // -> [39, null]

isar.shoes.filter()
  .sizeLessThan(40, include: true)
  .findAll() // -> [39, null, 40]

isar.shoes.filter()
  .sizeBetween(39, 46, includeLower: false)
  .findAll() // -> [40, 46]

```

### 論理演算子

以下の論理演算子を使って述語を合成することもできます:

| Operator   | Description |
| ---------- | ----------- |
| `.and()`   | 左側と右側の式の両方が `true` と評価された場合、`true` と評価される。|
| `.or()`    | どちらかの式が `true` と評価された場合、`true` と評価される。|
| `.xor()`   | ちょうど1つの式が `true` と評価される場合に、 `true` と評価される。 |
| `.not()`   | 次の式の結果を否定する。 |
| `.group()` | 条件をグループ化し、評価順序を指定できるようにする。|

sizeが46のshoesをすべて見つけたい場合は、次のようなクエリを使用します。

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

複数の条件を使用したい場合は、 **論理積** `.and()` や,  **論理和** `.or()` 、 **排他的論理和** `.xor()`を組み合わせることが出来ます。

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // オプション。 フィルターは暗黙的に論理積で結合される.
  .isUnisexEqualTo(true)
  .findAll();
```

このクエリは次の式と同等です： `size == 46 && isUnisex == true`.

また、`.group()` を使って条件をグループ化することもできます：

```dart
final result = await isar.shoes.filter()
  .sizeBetween(43, 46)
  .and()
  .group((q) => q
    .modelNameContains('Nike')
    .or()
    .isUnisexEqualTo(false)
  )
  .findAll()
```

このクエリは次の式と同等です： `size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)`.

条件やグループを否定するには、**論理否定** `.not()` を使用します:

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

このクエリは次の式と同等です： `size != 46 && isUnisex != true`.

### 文字列の条件

上記のクエリ条件に加えて、文字列値にはさらにいくつかの条件を使用することができます。たとえば、正規表現に似たワイルドカードを使用すると、より柔軟な検索が可能になります。

| Condition            | Description                                                       |
| -------------------- | ----------------------------------------------------------------- |
| `.startsWith(value)` | 指定した `value` で始まる文字列値に一致する。          |
| `.contains(value)`   | 指定した `value` を含む文字列値に一致する。          |
| `.endsWith(value)`   | 指定した `value` で終わる文字列値に一致する。         |
| `.matches(wildcard)` | 指定した `wildcard` パターンに適合する文字列値に一致する。 |

**大文字小文字を区別する**  
すべての文字列操作には、オプションで `caseSensitive` パラメータがあり、デフォルトは `true` です。

**ワイルドカード:**  
[ワイルドカード文字列表現](https://en.wikipedia.org/wiki/Wildcard_character) は、通常の文字に2つの特殊なワイルドカード文字を使用した文字列です。:

- ワイルドカードの `*` は、0個以上の任意の文字に一致します。
- ワイルドカードの `?` は、任意の文字に一致します。
  たとえば, ワイルドカード文字列 `"d?g"` は `"dog"`, `"dig"`, および `"dug"` にマッチするが、 `"ding"`, `"dg"`, および `"a dog"` にマッチしません。

### クエリ修飾子

時には、ある条件や異なる値に基づいてクエリを作成することが必要な場合があります。Isarは、条件付きクエリを作成するための非常に強力な機能を持っています。:

| Modifier              | Description                                          |
| --------------------- | ---------------------------------------------------- |
| `.optional(cond, qb)` | 条件が `true` の場合のみ、クエリを拡張する。 これは、クエリ内のほぼすべての場所で使用することが出来ます。条件付きでソートしたり絞り込む為に用いるなどが使用例です。 |
| `.anyOf(list, qb)`    | `values` の各値に対してクエリを拡張し、 **論理和** を用いて条件を組み合わせる。 |
| `.allOf(list, qb)`    | `values` の各値に対してクエリを拡張し、 **論理積** を用いて条件を組み合わせる。 |

このサンプルでは、optionalを使用してShoesを見つけることができるメソッドを構築しています：

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // sizeFilter != null の場合のみ、フィルタを適用する。
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

複数の靴のサイズのいずれかを持つ靴をすべて見つけたい場合は、従来のクエリを書くか、 `anyOf()` 修飾子を使うことができます:

```dart
final shoes1 = await isar.shoes.filter()
  .sizeEqualTo(38)
  .or()
  .sizeEqualTo(40)
  .or()
  .sizeEqualTo(42)
  .findAll();

final shoes2 = await isar.shoes.filter()
  .anyOf(
    [38, 40, 42],
    (q, int size) => q.sizeEqualTo(size)
  ).findAll();

// shoes1 == shoes2
```

クエリ修飾子は、動的なクエリを構築したい場合に特に有効です。

### リスト

Listにおいてもクエリが可能です:

```dart
class Tweet {
  Id? id;

  String? text;

  List<String> hashtags = [];
}
```

Listの長さ(length)に基づいてクエリを実行できます:

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

これらは、Dartのコード `tweets.where((t) => t.hashtags.isEmpty);` や `tweets.where((t) => t.hashtags.length > 5);` に相当します。また、リストの要素をもとに問い合わせることもできます：

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

これはDartのコード `tweets.where((t) => t.hashtags.contains('flutter'));` に相当します。

### 埋め込みオブジェクト

組み込みオブジェクトは、Isarの最も便利な機能の一つです。トップレベルオブジェクトと同じ条件で非常に効率的に問い合わせることができます。例えば、次のようなモデルがあるとします：

```dart
@collection
class Car {
  Id? id;

  Brand? brand;
}

@embedded
class Brand {
  String? name;

  String? country;
}
```

ブランド名が `"BMW"` で、国名が `"Germany"` である車をすべて問い合わせたいとします。これは以下のクエリで実現できます：

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

ネストされたクエリは常にグループ化するようにしましょう。上記のクエリは以下のクエリと結果は同じですが、上記のクエリの方がより効率的に動作します:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### リンク

モデルに[リンクもしくはバックリンク](links)が含まれている場合、リンクされたオブジェクトまたはリンクされたオブジェクトの数に基づいてクエリをフィルタリングすることができます。

:::warning
リンククエリは、Isarがリンクされたオブジェクトを検索する必要があるため、コストがかかることに留意してください。また、代わりに埋め込みオブジェクトを使用することを検討してみてください。
:::

```dart
@collection
class Teacher {
  Id? id;

  late String subject;
}

@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

数学または英語の先生を持つ全ての生徒を見つけたいとします:

```dart
final result = await isar.students.filter()
  .teachers((q) {
    return q.subjectEqualTo('Math')
      .or()
      .subjectEqualTo('English');
  }).findAll();
```

リンクフィルターは、少なくとも1つのリンクオブジェクトが条件にマッチすれば、`true`と評価されます。

教師を持たない全ての生徒を検索してみましょう。:
  
```dart
final result = await isar.students.filter().teachersLengthEqualTo(0).findAll();
```

もしくは:

```dart
final result = await isar.students.filter().teachersIsEmpty().findAll();
```

## Where節

Where節は非常に強力な機能ですが、正しく使用するのは少し難しいかもしれません。

フィルターとは対照的に、where節はスキーマで定義したインデックスを使用してクエリ条件を確認しています。各レコードを個別にフィルタリングするより、インデックスを用いる方がはるかに高速です。

➡️ 詳しくはこちら: [インデックス](indexes)

:::tip
基本的なルールとして、Where節を使用してレコードをできる限り減らし、残りのフィルタリングはフィルタを使用して行うようにすることをお勧めします。
:::

where節を組み合わせるには、**論理和**しか使えません。言い換えると、複数のwhere節を合計することはできますが、複数のwhere節の交差部分を照会することはできません。

それではShoeコレクションにインデックスを追加してみましょう:

```dart
@collection
class Shoe with IsarObject {
  Id? id;

  @Index()
  Id? size;

  late String model;

  @Index(composite: [CompositeIndex('size')])
  late bool isUnisex;
}
```

ここではインデックスが2つあります。`size` のインデックスは、 `.sizeEqualTo()` のような where 節を使用可能にしています。`isUnisex` の複合インデックス(CompositeIndex)は、 `isUnisexSizeEqualTo()` のような where 節を使用できるようにしています。そしてまた、インデックスの接頭辞は常に任意のものを使用できる為、 `isUnisexEqualTo()` のような事も可能です。

これでサイズ46のユニセックスの靴を検索する以前見たクエリを、複合インデックスを使用して書き換えることができます。このクエリは前記で述べたクエリよりも高速に動作します:

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

Where節には、さらに2つの強力な機能があります。
Where節は"Free"なソートと、超高速なDISTINCT命令を保持しています。

### where節とフィルタの組み合わせ

`shoes.filter()` というクエリを覚えていますか？

実はこれは `shoes.where().filter()` の短縮形なのです。where節とfilterを同じクエリで組み合わせて、両方の利点を利用することができます（そして、そうすべきです）：

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

まず、where 節が適用され、フィルタリングされるオブジェクトの数が減ります。その後、残りのオブジェクトにフィルタが適用されます。

## ソート

クエリ実行結果のソート方法は、`.sortBy()`, `.sortByDesc()`, `.thenBy()`, `.thenByDesc()` メソッドを用いて定めることが可能です。

インデックスを使わずに、すべての靴をModel名の昇順とSizeの降順でソートして検索する方法です:

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

特に、ソートは offset と limit の前に行われるため、たくさんの結果をソートするのはコストがかかります。上記のソートメソッドでは、インデックスを使用することはありません。幸いなことに、Where節によるソートを使えば、100万個のオブジェクトをソートする場合でもクエリを高速に実行することができます。

### Where節のソート

クエリで **単一(single)** の where 節を使用した場合、結果はすでにインデックスでソートされています。これは非常に重要です。

例えば、サイズ `[43, 39, 48, 40, 42, 45]` の靴があり、サイズが `42` より大きい靴をすべて検索し、サイズ順に並べたいとしましょう。

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // 加えて、結果がSizeでソートされる
  .findAll(); // -> [43, 45, 48]
```

見ての通り、結果は `size` インデックスでソートされています。where 節のソート順を逆にしたい場合は、 `sort` に `Sort.desc` をセットします：

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

時には where 節を使いたくないけれども、暗黙のうちにソートが行われるという恩恵を受けたいこともあるでしょう。そのような場合には、 `any` という where 節を使用します：

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

もし、あなたが複合インデックスを使用した場合、結果はそのインデックス内のすべてのフィールドでソートされます。

:::tip
結果をソートする必要がある場合は、インデックスを使用することを検討してください。`offset()` や `limit()` を使っている場合は特にそうです。
:::

時には、ソートのためにインデックスを使用することが出来なかったり、有用ではない場合もあるかもしれません。そのような場合は、インデックスを使用して結果の項目数をできるだけ減らすのが良いでしょう。

## ユニーク値

一意な値を持つ項目のみを返すには、distinct述語を使用します。たとえば、Isar データベースに何種類の異なる靴のModelがあるかを調べるには、 以下のようにします：

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

また、複数のdistinctの条件を繋げて、異なるModelとSizeの組み合わせである全ての靴を検索することができます。

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

異なる組み合わせの最初の結果のみが返されます。これをコントロールするために、where句とソート操作を使用することも可能です。

### WHERE節のdistinct

一意でないインデックスがある場合、それの全ての異なる値を取得したい時があると思います。前のセクションで紹介した `distinctBy` オペレーションを使うこともできますが、ソートやフィルタの後に実行されるため、若干のオーバーヘッドが発生します。
WHERE節を1つだけ使用するのであれば、代わりにインデックスに依拠してdistinct処理を実行することができます。

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
理論・仕組み的には、ソートとdistinctのために複数のwhere節を使うこともできます。複数のwhere節を使う唯一の制限は、これらのwhere節が重複しておらず、同じインデックスを使用していることです。正しいソートを行うには、ソート順で適用する必要があります。十分に注意をしてください。
:::

## OffsetとLimit

遅延(lazy)リストビューのために、クエリ結果の数を制限することは良い方法だと思います。これを行うには、 `limit()` を設定します。

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

`offset()` を設定することで、クエリの結果をページネイト(取得開始位置の指定)することもできます。

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

Dartオブジェクトのインスタンス化は、クエリ実行の中で最もコストのかかる部分であることが多いので、必要なオブジェクトだけを読み込むのが良いでしょう。

## 実行順序

Isarは常に同じ順序でクエリーを実行します：

1. プライマリまたはセカンダリインデックスを走査してオブジェクトを見つける（where節の適用）
2. オブジェクトのフィルタリング
3. 結果のソート
4. distinct操作の適用
5. 結果のoffset と limit
6. 結果の返却

## クエリの操作

これまでの例では、`.findAll()` を使ってマッチするオブジェクトをすべて取得しました。しかし、利用できる操作は他にも沢山あります。

| Operation        | Description                                                                                                         |
| ---------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.findFirst()`   | 最初にマッチしたオブジェクトのみを取得し、マッチしない場合は `null` を取得する。                                                  |
| `.findAll()`     | マッチしたオブジェクトを全て取得する。                                                                        |
| `.count()`       | クエリにマッチするオブジェクトの数を数える。                                                                             |
| `.deleteFirst()` | コレクションから、最初にマッチしたオブジェクトを削除する。                                                               |
| `.deleteAll()`   | コレクションから、一致するすべてのオブジェクトを削除する。                                                                    |
| `.build()`       | クエリをコンパイルして、後で再利用することが出来る。これにより、クエリを複数回実行したい場合に、そのクエリを構築するためのコストを節約する事が出来る。 |

## プロパティクエリ

単一プロパティの値にしか関心が無く必要の無い場合、プロパティクエリを使用することができます。通常のクエリを構築し、プロパティを選択するだけです:

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

単一プロパティのみを使用することで、逆シリアル化の時間を節約できます。プロパティクエリは、埋め込みオブジェクトやリストに対しても機能します。

## アグリゲーション(集約)

Isarはプロパティクエリの値を集約する機能を持っています。以下の集約操作が可能です：

| Operation    | Description                                                    |
| ------------ | -------------------------------------------------------------- |
| `.min()`     | 最小値を探す。該当するものがなければ `null` となる。             |
| `.max()`     | 最大値を探す。該当するものがなければ `null` となる。            |
| `.sum()`     | 全ての値を合計する。                                               |
| `.average()` | すべての値の平均を計算し、一致するものがない場合は `NaN` を計算する。 |

一致するオブジェクトをすべて見つけて手動で集約するよりも、アグリゲーションを使用する方が、はるかに高速になります。

## 動的なクエリ

:::danger
このセクションは、おそらくほとんどの方には関係ないでしょう。ダイナミッククエリの使用は、どうしても必要な場合（ほぼ無いです）を除き、お勧めしません。
:::

今まで述べて来たすべての例は、QueryBuilderと生成された静的な拡張メソッドを使用しています。もしかしたら、動的なクエリや（Isar Inspectorのような）カスタムクエリ言語を作りたいかもしれません。その場合は、`buildQuery()` メソッドを使うことができます：

| Parameter       | Description                                                                                 |
| --------------- | ------------------------------------------------------------------------------------------- |
| `whereClauses`  | クエリのwhere節                                                             |
| `whereDistinct` | where 節が個別の値を返すかどうか（単一の where 節の場合のみ有効） |
| `whereSort`     | where節のトラバース(巡回)順序（単一のwhere節にのみ有効）             |
| `filter`        | 結果に適用するフィル                                                         |
| `sortBy`        | ソートするプロパティの一覧                                                            |
| `distinctBy`    | 区別するプロパティの一覧                                     |
| `offset`        | 結果のoffset                                                                  |
| `limit`         | 返送する結果の最大数                                                 |
| `property`      | nullで無い場合、このプロパティの値のみが返される。                                |

それでは動的なクエリを作成してみましょう:

```dart
final shoes = await isar.shoes.buildQuery(
  whereClauses: [
    WhereClause(
      indexName: 'size',
      lower: [42],
      includeLower: true,
      upper: [46],
      includeUpper: true,
    )
  ],
  filter: FilterGroup.and([
    FilterCondition(
      type: ConditionType.contains,
      property: 'model',
      value: 'nike',
      caseSensitive: false,
    ),
    FilterGroup.not(
      FilterCondition(
        type: ConditionType.contains,
        property: 'model',
        value: 'adidas',
        caseSensitive: false,
      ),
    ),
  ]),
  sortBy: [
    SortProperty(
      property: 'model',
      sort: Sort.desc,
    )
  ],
  offset: 10,
  limit: 10,
).findAll();
```

これらは以下のクエリに相当します。:

```dart
final shoes = await isar.shoes.where()
  .sizeBetween(42, 46)
  .filter()
  .modelContains('nike', caseSensitive: false)
  .not()
  .modelContains('adidas', caseSensitive: false)
  .sortByModelDesc()
  .offset(10).limit(10)
  .findAll();
```
