---
title: 全文检索
---

# 全文检索

全文检索是一种从数据库中搜索文本的强大功能。你现在应该已经熟悉[索引](../indexes.md)的工作原理了，但还是让我们先了解一些基本知识。

索引就像一张查询表，允许快速地根据给定值查找数据。例如，如果你的对象含有一个 `title` 字段，你可以以该字段创建一张索引表，以此根据给定的标题来快速查询。

## 为什么全文检索很有用？

你本可以轻松通过 Filter 来搜索文本。Isar 为你提供了许多字符串查询方法，例如 `.startsWith()`、`.contains()` 和 `.matches()`。但问题在于 Filter 的复杂度是 `O(n)`，其中 `n` 是 Collection 中对象的个数，像 `.matches()` 这样的字符串操作就格外消耗性能。

:::tip
全文检索比 Filter 快多了，但是索引也有局限的地方。在本专题中，我们将探寻如何解决这些局限性。
:::

## 基本示例

想法依然不变：我们对文本中的单词进行索引，而不是对整个文本索引，这样我们可以对单个单词进行搜索。

让我们先创建一个基本的全文检索索引：

```dart
class Message {
  Id? id;

  late String content;

  @Index()
  List<String> get contentWords => content.split(' ');
}
```

现在我们可以通过内容中某些指定词汇来搜索讯息：

```dart
final posts = await isar.messages
  .where()
  .contentWordsAnyEqualTo('hello')
  .findAll();
```

这条查询非常快，但是有几个问题：

1. 我们只能搜索整个词汇
2. 我们没考虑标点符号
3. 我们不支持其他空白字符

## 正确分割文本

让我们完善上述例子。我们可以用一个复杂的正则来正确分割文本，但是在某些少数情况下它很可能会出错且导致查询变得很慢。

[Unicode Annex #29](https://unicode.org/reports/tr29/) 为几乎所有人类语言定义了如何正确分割文本。它很复杂，但是幸运的是，Isar 内部已经帮我们实现了：

```dart
Isar.splitWords('hello world'); // -> ['hello', 'world']

Isar.splitWords('The quick (“brown”) fox can’t jump 32.3 feet, right?');
// -> ['The', 'quick', 'brown', 'fox', 'can’t', 'jump', '32.3', 'feet', 'right']
```

## 我想要更多控制

很简单！我们可以修改索引配置，让它支持前缀匹配和大小写匹配：

```dart
class Post {
  Id? id;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get titleWords => title.split(' ');
}
```

默认情况下，Isar 会将单词散列化，这么做性能很快且节省存储空间。但是这样就无法使用前缀匹配查询。我们改变了索引类型，使用 `IndexType.value` 而不是 `IndexType.hash`，来直接使用那些单词。借此我们就可以使用 `.titleWordsAnyStartsWith()` 的 Where 子句：

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

## 我也需要 `.endsWith()` 方法

没问题！我们会用一个小技巧来实现 `.endsWith()` 匹配：

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

不要忘记倒序排列查询的结果：

```dart
final posts = await isar.posts
  .where()
  .revTitleWordsAnyStartsWith('lcome'.reversed)
  .findAll();
```

## 词干提取算法

不幸的是，索引不支持 `.contains()` 匹配（其他数据库也如此）。但是还有几个备选方案值得我们研究一番。选择何种方式完全取决于你的使用场景。举个例子，你可以对词干进行索引，而不是对整个单词索引。

词干提取算法指的是自然语言处理领域里去除词缀得到词根的过程，即得到单词最一般的写法：

```
connection
connections
connective          --->   connect
connected
connecting
```

常见的算法有 [Porter 词干提取算法](https://tartarus.org/martin/PorterStemmer/) 和 [Snowball 词干提取算法](https://snowballstem.org/algorithms/)。

还有将单词复杂形态转变成最基础形态的[词形还原](https://en.wikipedia.org/wiki/Lemmatisation)。

## 语音算法

[语音算法](https://en.wikipedia.org/wiki/Phonetic_algorithm) 是指根据发音来检索单词的算法。也就是说，它可以根据发音接近程度来帮你查询结果。

:::warning
大部分语音算法通常只支持单一语言，一般是英语。
:::

### Soundex

[Soundex](https://en.wikipedia.org/wiki/Soundex) 是一种语音算法，它通过英文发音来检索名字。它的目的是将同音词用同一编码表示，虽然发音略有差异，但可达到模糊匹配的效果。这是个非常直接明了的算法，也有若干改进版本。

若是用这个算法，那么单词 `"Robert"` 和 `"Rupert"` 都会返回编码 `"R163"`，而单词 `"Rubin"` 则返回 `"R150"`。 同音词 `"Ashcraft"` 和 `"Ashcroft"` 则都会返回 `"A261"`。

### Double Metaphone

[Double Metaphone](https://en.wikipedia.org/wiki/Metaphone) 也是一种语音算法，是 Metaphone 的二代版本。它在前代基础上改进了不少基本设计。

Double Metaphone 加入了对大量来自外来语如斯拉夫语、德语、凯尔特语、希腊语、法语、意大利语、西班牙语、中文等的不规则英文单词发音的支持。
