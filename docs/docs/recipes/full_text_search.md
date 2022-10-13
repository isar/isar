---
title: Full-text search
---

# Full-text search

Full-text search is a powerful way to search text in the database. You should already be familiar with how [indexes](/indexes) work, but let's go over the basics.

An index works like a lookup table, allowing the query engine to find records with a given value quickly. For example, if you have a `title` field in your object, you can create an index on that field to make it faster to find objects with a given title.

## Why is full-text search useful?

You can easily search text using filters. There are various string operations for example `.startsWith()`, `.contains()` and `.matches()`. The problem with filters is that their runtime is `O(n)` where `n` is the number of records in the collection. String operations like `.matches()` are especially expensive.

:::tip
Full-text search is much faster than filters, but indexes have some limitations. In this recipe, we will explore how to work around these limitations.
:::

## Basic example

The idea is always the same: Instead of indexing the whole text, we index the words in the text so we can search for them individually.

Let's create the most basic full-text index:

```dart
class Message {
  Id? id;

  late String content;

  @Index()
  List<String> get contentWords => content.split(' ');
}
```

We can now search for messages with specific words in the content:

```dart
final posts = await isar.messages
  .where()
  .contentWordsAnyEqualTo('hello')
  .findAll();
```

This query is super fast, but there are some problems:

1. We can only search for entire words
2. We do not consider punctuation
3. We do not support other whitespace characters

## Splitting text the right way

Let's try to improve the previous example. We could try to develop a complicated regex to fix word splitting, but it will likely be slow and wrong for edge cases.

The [Unicode Annex #29](https://unicode.org/reports/tr29/) defines how to split text into words correctly for almost all languages. It is quite complicated, but fortunately, Isar does the heavy lifting for us:

```dart
Isar.splitWords('hello world'); // -> ['hello', 'world']

Isar.splitWords('The quick (“brown”) fox can’t jump 32.3 feet, right?');
// -> ['The', 'quick', 'brown', 'fox', 'can’t', 'jump', '32.3', 'feet', 'right']
```

## I want more control

Easy peasy! We can change our index also to support prefix matching and case-insensitive matching:

```dart
class Post {
  Id? id;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get titleWords => title.split(' ');
}
```

By default, Isar will store the words as hashed values which is fast and space efficient. But hashes can't be used for prefix matching. Using `IndexType.value`, we can change the index to use the words directly instead. It gives us the `.titleWordsAnyStartsWith()` where clause:

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

## I also need `.endsWith()`

Sure thing! We will use a trick to achieve `.endsWith()` matching:

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

Don't forget reversing the ending you want to search for:

```dart
final posts = await isar.posts
  .where()
  .revTitleWordsAnyStartsWith('lcome'.reversed)
  .findAll();
```

## Stemming algorithms

Unfortunately, indexes do not support `.contains()` matching (this is true for other databases as well). But there are a few alternatives that are worth exploring. The choice highly depends on your use. One example is indexing word stems instead of the whole word.

A stemming algorithm is a process of linguistic normalization in which the variant forms of a word are reduced to a common form:

```
connection
connections
connective          --->   connect
connected
connecting
```

Popular algorithms are the [Porter stemming algorithm](https://tartarus.org/martin/PorterStemmer/) and the [Snowball stemming algorithms](https://snowballstem.org/algorithms/).

There are also more advanced forms like [lemmatization](https://en.wikipedia.org/wiki/Lemmatisation).

## Phonetic algorithms

A [phonetic algorithm](https://en.wikipedia.org/wiki/Phonetic_algorithm) is an algorithm for indexing words by their pronunciation. In other words, it allows you to find words that sound similar to the ones you are looking for.

:::warning
Most phonetic algorithms only support a single language.
:::

### Soundex

[Soundex](https://en.wikipedia.org/wiki/Soundex) is a phonetic algorithm for indexing names by sound, as pronounced in English. The goal is for homophones to be encoded to the same representation so they can be matched despite minor differences in spelling. It is a straightforward algorithm, and there are multiple improved versions.

Using this algorithm, both `"Robert"` and `"Rupert"` return the string `"R163"` while `"Rubin"` yields `"R150"`. `"Ashcraft"` and `"Ashcroft"` both yield `"A261"`.

### Double Metaphone

The [Double Metaphone](https://en.wikipedia.org/wiki/Metaphone) phonetic encoding algorithm is the second generation of this algorithm. It makes several fundamental design improvements over the original Metaphone algorithm.

Double Metaphone accounts for various irregularities in English of Slavic, Germanic, Celtic, Greek, French, Italian, Spanish, Chinese, and other origins.
