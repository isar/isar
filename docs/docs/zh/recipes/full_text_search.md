---
title: 全文搜索
---

# 全文搜索

全文搜索是一种在数据库中搜索文本的强大方式。你应该已经熟悉了[索引](/indexes)的工作原理，不过让我们再回顾一下基础知识。

索引的工作方式就像一个查询表，允许查询引擎快速找到具有给定值的记录。例如，如果你的对象中有一个`title`字段，你可以在这个字段上创建一个索引，以使它更快地找到具有给定标题的对象。

## 为什么全文搜索是有用的？

你可以使用过滤器轻松搜索文本。过滤器里有各种字符串操作，例如`.startsWith()`, `.contains()`和`.matches()`。过滤器的问题是它们的运行时间是`O(n)`，其中`n`是集合中记录的数量。像`.matches()`这样的字符串操作尤其昂贵。

:::tip
全文搜索比过滤器快得多，但索引有一些限制。在本使用技巧中，我们将探讨如何绕过这些限制。
:::

## 基础例子

解决方法总是类似的：我们不是对整个文本进行索引，而是对文本中的词进行索引，这样我们就可以对它们进行单独搜索。

让我们创建一个最基本的全文索引：

```dart
class Message {
  Id? id;

  late String content;

  @Index()
  List<String> get contentWords => content.split(' ');
}
```

我们现在可以搜索内容中含有特定词汇的信息。

```dart
final posts = await isar.messages
  .where()
  .contentWordsAnyEqualTo('hello')
  .findAll();
```

这个查询是超级快的，但也有一些问题：

1. 我们只能搜索整个单词
2. 我们不考虑标点符号
3. 我们不支持其他空白字符

## 以正确的方式拆分文本

让我们试着改进前面的例子。我们可以尝试开发一个复杂的正则表达式来解决分词问题，但这很可能会很慢，而且对边界情况来说很可能是错误的。

[Unicode Annex #29](https://unicode.org/reports/tr29/)为几乎所有语言定义了如何正确地将文本分割成单词。它是相当复杂的，但幸运的是，Isar为我们做了大量的准备工作：

```dart
Isar.splitWords('hello world'); // -> ['hello', 'world']

Isar.splitWords('The quick (“brown”) fox can’t jump 32.3 feet, right?');
// -> ['The', 'quick', 'brown', 'fox', 'can’t', 'jump', '32.3', 'feet', 'right']
```

## 我想要更多控制

小菜一碟！我们还可以改变我们的索引，以支持前缀匹配和不区分大小写的匹配：

```dart
class Post {
  Id? id;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get titleWords => title.split(' ');
}
```

默认情况下，Isar将以哈希值的形式存储单词，这既快速又节省空间。但是哈希值不能用于前缀匹配。使用`IndexType.value`，我们可以改变索引，直接使用单词来代替。它为我们提供了`.titleWordsAnyStartsWith()`的where语句。

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

## 我还想要`.endsWith()`

当然可以！我们将使用一个技巧来实现`.endsWith()`的匹配：

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

不要忘了把你的搜索结果反过来：

```dart
final posts = await isar.posts
  .where()
  .revTitleWordsAnyStartsWith('lcome'.reversed)
  .findAll();
```

## 词根算法

不幸的是，索引不支持`.contains()`匹配（其它数据库也是如此）。但是有一些替代方法值得探索。选择在很大程度上取决于你的用途。比如索引词干而不是整个词。

词干算法是一个语言规范化的过程，在这个过程中，一个词的不同形式被减少到一个共同形式：

```
connection
connections
connective          --->   connect
connected
connecting
```

流行的算法是[Porter词根算法](https://tartarus.org/martin/PorterStemmer/)和[Snowball词根算法](https://snowballstem.org/algorithms/)。

也有更高级的形式，如[词形还原](https://en.wikipedia.org/wiki/Lemmatisation)。

## 语音算法

[语音算法](https://en.wikipedia.org/wiki/Phonetic_algorithm)是一种按发音索引单词的算法。换句话说，它可以让你找到与你要找的单词发音相似的单词。

:::warning
大多数语音算法只支持单一语言。
:::

### Soundex

[Soundex](https://en.wikipedia.org/wiki/Soundex)是一种用于按英语发音对名字进行索引的语音算法。其目的是使同音字被编码为相同的表示法，因此尽管在拼写上有细微的差别，它们也能被匹配。这是一个简单的算法，而且有多个改进的版本。

使用这种算法，`"Robert"`和`"Rupert"`都返回字符串`"R163"`，而`"Rubin"`产生`"R150"`。`"Ashcraft"`和`"Ashcroft"`都得到`"A261"`。

### Double Metaphone

[Double Metaphone](https://en.wikipedia.org/wiki/Metaphone) 语音编码算法是该算法的第二代。与最初的Metaphone算法相比，它在设计上做了一些改进。

Double Metaphone解析了斯拉夫语、日耳曼语、凯尔特语、希腊语、法语、意大利语、西班牙语、汉语和其他来源的英语中的各种不规则现象。
