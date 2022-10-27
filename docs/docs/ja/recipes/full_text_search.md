---
title: 全文検索
---

# 全文検索

全文検索は、データベース内のテキストを検索する強力な方法です。[インデックス](../indexes.md)がどのように機能するかについては既にご存じだとは思いますが、基本的なことを説明します。

インデックスはルックアップテーブルのように機能し、特定の値を持つレコードをクエリエンジンがすばやく検索できるようにします。たとえば、オブジェクトに `title` フィールドがある場合、そのフィールドにインデックスを作成することで、指定したタイトルを持つオブジェクトをより速く見つけることができます。

## なぜ全文検索が便利なのか

IsarDB ではフィルタを使って簡単にテキストを検索することができます。例えば、 `.startsWith()`, `.contains()`, `.matches()` のような様々な文字列操作があります。フィルタの問題は、その実行時間が `O(n)` (ここで `n` はコレクション内のレコードの数) であることです。特に、 `.matches()` のような文字列演算は時間がかかります。

:::tip
全文検索はフィルタよりはるかに高速ですが、インデックスにはいくつかの制限があります。このレシピでは、これらの制限を回避する方法を探ります。
:::

## 基本例

考え方としては常に同じです：テキスト全体をインデックス化するのではなく、テキスト中の単語をインデックス化し、個別に検索できるようにします。

それではさっそく、基本的な全文インデックスを作成してみましょう:

```dart
class Message {
  Id? id;

  late String content;

  @Index()
  List<String> get contentWords => content.split(' ');
}
```

これで、content 内の特定の単語を検索できるようになりました:

```dart
final posts = await isar.messages
  .where()
  .contentWordsAnyEqualTo('hello')
  .findAll();
```

このクエリは高速に動作しますが、いくつかの問題があります：

1. 単語全体しか検索できない
2. 句読点は考慮しない
3. 他の空白文字の検索に対応していない

## テキストを正しく分割する

先ほどの例を改善してみましょう。単語分割を修正するために複雑な正規表現を開発しようとすることもできますが、おそらく時間がかかり、エッジケースで間違ってしまう可能性もあります。

[Unicode Annex #29](https://unicode.org/reports/tr29/)では、ほぼ全ての言語について、テキストを単語に正しく分割する方法を定義しています。これは非常に複雑ですが、幸いなことに、Isar は重い仕事を代わりにやってくれます。

```dart
Isar.splitWords('hello world'); // -> ['hello', 'world']

Isar.splitWords('The quick (“brown”) fox can’t jump 32.3 feet, right?');
// -> ['The', 'quick', 'brown', 'fox', 'can’t', 'jump', '32.3', 'feet', 'right']
```

## 他の機能の追加

他の機能も簡単に実装できますよ！プレフィックスマッチングや大文字小文字を区別しないマッチングをサポートするようにインデックスを変更することもできます。

```dart
class Post {
  Id? id;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get titleWords => title.split(' ');
}
```

デフォルトでは、Isar は単語をハッシュ値として保存します。これは高速で容量効率のよい方法です。 しかし、ハッシュ値はプレフィックスマッチングに使用することはできません。インデックスを変更して、`IndexType.value` を使用すると、単語を直接利用することができます。これによって `.titleWordsAnyStartsWith()` という where 節を提供します。

```dart
final posts = await isar.posts
  .where()
  .titleWordsAnyStartsWith('hel')
  .or()
  .titleWordsAnyStartsWith('welco')
  .or()
  .titleWordsAnyStartsWith('howd')
  .findAll();
```

## `.endsWith()` の実装

`.endsWith()` の実装も、勿論可能です！ここでは、`.endsWith()`のマッチングを実現するためのちょっとしたテクニックをお見せします。

```dart
class Post {
    Id? id;

    late String title;

    @Index(type: IndexType.value, caseSensitive: false)
    List<String> get revTitleWords {
        return Isar.splitWords(title).map(
          (word) => word.reversed).toList()
        );
    }
}
```

検索したい語尾を反転(reversed)させることを忘れないようにしてください。

```dart
final posts = await isar.posts
  .where()
  .revTitleWordsAnyStartsWith('lcome'.reversed)
  .findAll();
```

## ステミングアルゴリズム

残念ながら、インデックスは `.contains()` マッチングをサポートしていません (これは他のデータベースでも同様です)。しかし、いくつかの代替手段があり、検討する価値はあります。その選択肢は、用途に大きく依存します。その一例として、単語全体ではなく、単語の語幹をインデックス化する方法があります。

ステミングアルゴリズムは、言語の正規化プロセスで、単語のさまざまな形式を共通の形式に変換します：

```
connection
connections
connective          --->   connect
connected
connecting
```

一般的なアルゴリズムは、[Porter stemming algorithm](https://tartarus.org/martin/PorterStemmer/) と [Snowball stemming algorithms](https://snowballstem.org/algorithms/) です。

また、[lemmatization](https://en.wikipedia.org/wiki/Lemmatisation) のような、より高度な形式もあります。

## 音声学的アルゴリズム

[音声アルゴリズム](https://en.wikipedia.org/wiki/Phonetic_algorithm)とは、発音によって単語を割り出すためのアルゴリズムです。つまり、探している単語と似た音の単語を見つけることができるのです。

:::warning
音声アルゴリズムの多くは、単一言語しかサポートしていません。
:::

### Soundex

[Soundex](https://en.wikipedia.org/wiki/Soundex)は、英語の発音で人名を索引付けするための音声アルゴリズムです。同音異義語が同じ表現にエンコードされ、スペルが多少違ってもマッチングできるようにすることが目的で作られています。これは簡単なアルゴリズムであり、複数の改良版が存在する。

このアルゴリズムを使うと、`"Robert"` と `"Rupert"` はともに `"R163"` という文字列を返し、 `"Rubin"` は `"R150"` を返します。`Ashcraft"` と `"Ashcroft"` は共に `"A261"` を返します。

### Double Metaphone

[Double Metaphone](https://en.wikipedia.org/wiki/Metaphone) 音素符号化アルゴリズムは、このアルゴリズムの第二世代です。このアルゴリズムは、オリジナルの Metaphone アルゴリズムと比較して、いくつかの基本的な設計上の改良がなされています。

Double Metaphone は、スラブ語、ゲルマン語、ケルト語、ギリシャ語、フランス語、イタリア語、スペイン語、中国語、およびその他の起源の英語におけるさまざまな不規則性を考慮しています。
