---
title: مکمل متن کی تلاش
---

# مکمل متن کی تلاش

مکمل متن کی تلاش ڈیٹا بیس میں متن تلاش کرنے کا ایک طاقتور طریقہ ہے۔ آپ کو پہلے سے ہی واقف ہونا چاہئے کہ [اشاریہ جات](/اشاریہ جات) کیسے کام کرتے ہیں، لیکن آئیے بنیادی باتوں کو دیکھتے ہیں۔

ایک انڈیکس تلاش کی میز کی طرح کام کرتا ہے، جس سے استفسار کے انجن کو دی گئی قدر کے ساتھ تیزی سے ریکارڈ تلاش کرنے کی اجازت ملتی ہے۔ مثال کے طور پر، اگر آپ کے آبجیکٹ میں ایک `ٹائٹل` فیلڈ ہے، تو آپ اس فیلڈ پر ایک انڈیکس بنا سکتے ہیں تاکہ دیے گئے عنوان کے ساتھ اشیاء کو تلاش کرنا تیز تر بنایا جا سکے۔

## مکمل متن کی تلاش کیوں مفید ہے؟

You can easily search text using filters. There are various string operations for example `.startsWith()`, `.contains()` and `.matches()`. The problem with filters is that their runtime is `O(n)` where `n` is the number of records in the collection. String operations like `.matches()` are especially expensive.

:::tip
مکمل متن کی تلاش فلٹرز سے کہیں زیادہ تیز ہے، لیکن اشاریہ جات کی کچھ حدود ہیں۔ اس نسخہ میں، ہم ان حدود کے ارد گرد کام کرنے کا طریقہ دریافت کریں گے۔
:::

## بنیادی مثال

خیال ہمیشہ ایک جیسا ہوتا ہے: پورے متن کو ترتیب دینے کے بجائے، ہم متن میں الفاظ کو ترتیب دیتے ہیں تاکہ ہم انفرادی طور پر ان کو تلاش کر سکیں۔

آئیے سب سے بنیادی فل ٹیکسٹ انڈیکس بنائیں:

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

یہ استفسار بہت تیز ہے، لیکن کچھ مسائل ہیں:

1. ہم صرف پورے الفاظ تلاش کر سکتے ہیں۔
2. ہم اوقاف پر غور نہیں کرتے
3. ہم دوسرے وائٹ اسپیس حروف کی حمایت نہیں کرتے ہیں۔

##متن کو صحیح طریقے سے تقسیم کرنا

آئیے پچھلی مثال کو بہتر بنانے کی کوشش کرتے ہیں۔ ہم الفاظ کی تقسیم کو ٹھیک کرنے کے لیے ایک پیچیدہ ریجیکس تیار کرنے کی کوشش کر سکتے ہیں، لیکن یہ ممکنہ طور پر کنارے کے معاملات کے لیے سست اور غلط ہوگا۔

The [Unicode Annex #29](https://unicode.org/reports/tr29/) defines how to split text into words correctly for almost all languages. It is quite complicated, but fortunately, Isar does the heavy lifting for us:

```dart
Isar.splitWords('hello world'); // -> ['hello', 'world']

Isar.splitWords('The quick (“brown”) fox can’t jump 32.3 feet, right?');
// -> ['The', 'quick', 'brown', 'fox', 'can’t', 'jump', '32.3', 'feet', 'right']
```

## میں مزید کنٹرول چاہتا ہوں۔

بالکل آسان! ہم اپنے انڈیکس کو بھی تبدیل کر سکتے ہیں تاکہ سابقہ ​​مماثلت اور کیس غیر حساس مماثلت کو سپورٹ کیا جا سکے۔

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

ڈبل میٹافون سلاو، جرمن، سیلٹک، یونانی، فرانسیسی، اطالوی، ہسپانوی، چینی، اور دیگر ماخذ کی انگریزی میں مختلف بے ضابطگیوں کے لیے اکاؤنٹس ہیں۔
