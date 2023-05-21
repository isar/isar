---
title: سوالات
---

# سوالات

استفسار یہ ہے کہ آپ کو ایسے ریکارڈز کیسے ملتے ہیں جو کچھ شرائط سے میل کھاتے ہیں، مثال کے طور پر:

- تمام ستارے والے رابطے تلاش کریں۔
- رابطوں میں الگ الگ نام تلاش کریں۔
- ان تمام رابطوں کو حذف کریں جن کے آخری نام کی وضاحت نہیں کی گئی ہے۔

چونکہ سوالات ڈیٹا بیس پر کیے جاتے ہیں نہ کہ ڈارٹ میں، وہ واقعی تیز ہیں۔ جب آپ ہوشیاری سے اشاریہ جات کا استعمال کرتے ہیں، تو آپ استفسار کی کارکردگی کو مزید بہتر بنا سکتے ہیں۔ مندرجہ ذیل میں، آپ سیکھیں گے کہ سوالات کیسے لکھتے ہیں اور آپ انہیں جتنی جلدی ممکن ہو سکے کیسے بنا سکتے ہیں۔

آپ کے ریکارڈ کو فلٹر کرنے کے دو مختلف طریقے ہیں: فلٹرز اور جہاں شقیں۔ ہم ایک نظر ڈال کر شروع کریں گے کہ فلٹرز کیسے کام کرتے ہیں۔

## فلٹرز

فلٹرز استعمال کرنے اور سمجھنے میں آسان ہیں۔ آپ کی خصوصیات کی قسم پر منحصر ہے، مختلف فلٹر آپریشنز دستیاب ہیں جن میں سے اکثر کے خود وضاحتی نام ہیں۔

فلٹر فلٹر کیے جانے والے مجموعہ میں موجود ہر شے کے اظہار کا جائزہ لے کر کام کرتے ہیں۔ اگر اظہار 'سچ' پر حل کرتا ہے، تو اسر نتائج میں اعتراض کو شامل کرتا ہے۔ فلٹرز نتائج کی ترتیب کو متاثر نہیں کرتے ہیں۔

ہم ذیل کی مثالوں کے لیے درج ذیل ماڈل استعمال کریں گے۔

```dart
@collection
class Shoe {
  Id? id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### استفسار کی شرائط

فیلڈ کی قسم پر منحصر ہے، مختلف شرائط دستیاب ہیں۔

| Condition | Description |
| ----------| ------------|
| `.equalTo(value)` | Matches values that are equal to the specified `value`. |
| `.between(lower, upper)` | Matches values that are between `lower` and `upper`. |
| `.greaterThan(bound)` | Matches values that are greater than `bound`. |
| `.lessThan(bound)` | Matches values that are less than `bound`. `null` values will be included by default because `null` is considered smaller than any other value. |
| `.isNull()` | Matches values that are `null`.|
| `.isNotNull()` | Matches values that are not `null`.|
| `.length()` | List, String and link length queries filter objects based on the number of elements in a list or link. |

Let's assume the database contains four shoes with sizes 39, 40, 46 and one with an un-set (`null`) size. Unless you perform sorting, the values will be returned sorted by id.

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

### منطقی آپریٹرز

آپ مندرجہ ذیل منطقی آپریٹرز کا استعمال کرتے ہوئے جامع پیشن گوئی کر سکتے ہیں:

| Operator   | Description |
| ---------- | ----------- |
| `.and()`   | Evaluates to `true` if both left-hand and right-hand expressions evaluate to `true`. |
| `.or()`    | Evaluates to `true` if either expression evaluates to `true`. |
| `.xor()`   | Evaluates to `true` if exactly one expression evaluates to `true`. |
| `.not()`   | Negates the result of the following expression. |
| `.group()` | Group conditions and allow to specify order of evaluation. |

اگر آپ 46 سائز میں تمام جوتے تلاش کرنا چاہتے ہیں، تو آپ درج ذیل استفسار کا استعمال کر سکتے ہیں:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

If you want to use more than one condition, you can combine multiple filters using logical **and** `.and()`, logical **or** `.or()` and logical **xor** `.xor()`.

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // Optional. Filters are implicitly combined with logical and.
  .isUnisexEqualTo(true)
  .findAll();
```

This query is equivalent to: `size == 46 && isUnisex == true`.

You can also group conditions using `.group()`:

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

This query is equivalent to `size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)`.

To negate a condition or group, use logical **not** `.not()`:

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

This query is equivalent to `size != 46 && isUnisex != true`.

### سٹرنگ کے حالات

مندرجہ بالا استفسار کی شرائط کے علاوہ، سٹرنگ اقدار کچھ اور شرائط پیش کرتی ہیں جنہیں آپ استعمال کر سکتے ہیں۔ مثال کے طور پر ریجیکس جیسے وائلڈ کارڈز تلاش میں مزید لچک پیدا کرتے ہیں۔

| Condition            | Description                                                       |
| -------------------- | ----------------------------------------------------------------- |
| `.startsWith(value)` | Matches string values that begins with provided `value`.          |
| `.contains(value)`   | Matches string values that contain the provided `value`.          |
| `.endsWith(value)`   | Matches string values that end with the provided `value`.         |
| `.matches(wildcard)` | Matches string values that match the provided `wildcard` pattern. |

**کیس کی حساسیت**  
All string operations have an optional `caseSensitive` parameter that defaults to `true`.

**Wildcards:**  
A [wildcard string expression](https://en.wikipedia.org/wiki/Wildcard_character) is a string that uses normal characters with two special wildcard characters:

- The `*` wildcard matches zero or more of any character
- The `?` wildcard matches any character.
  For example, the wildcard string `"d?g"` matches `"dog"`, `"dig"`, and `"dug"`, but not `"ding"`, `"dg"`, or `"a dog"`.

### سوال میں ترمیم کرنے والے

بعض اوقات کچھ شرائط یا مختلف اقدار کی بنیاد پر استفسار کرنا ضروری ہوتا ہے۔ aای زار مشروط سوالات کی تعمیر کے لئے ایک بہت طاقتور ٹول ہے:

| Modifier              | Description                                          |
| --------------------- | ---------------------------------------------------- |
| `.optional(cond, qb)` | Extends the query only if the `condition` is `true`. This can be used almost anywhere in a query for example to conditionally sort or limit it. |
| `.anyOf(list, qb)`    | Extends the query for each value in `values` and combines the conditions using logical **or**. |
| `.allOf(list, qb)`    | Extends the query for each value in `values` and combines the conditions using logical **and**. |

In this example, we build a method that can find shoes with an optional filter:

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // only apply filter if sizeFilter != null
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

If you want to find all shoes that have one of multiple shoe sizes, you can either write a conventional query or use the `anyOf()` modifier:

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

استفسار میں ترمیم کرنے والے خاص طور پر اس وقت مفید ہوتے ہیں جب آپ متحرک سوالات بنانا چاہتے ہیں۔

### فہرستیں

یہاں تک کہ فہرستوں سے بھی استفسار کیا جا سکتا ہے:

```dart
class Tweet {
  Id? id;

  String? text;

  List<String> hashtags = [];
}
```

آپ فہرست کی لمبائی کی بنیاد پر استفسار کر سکتے ہیں:

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

These are equivalent to the Dart code `tweets.where((t) => t.hashtags.isEmpty);` and `tweets.where((t) => t.hashtags.length > 5);`. You can also query based on list elements:

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

This is equivalent to the Dart code `tweets.where((t) => t.hashtags.contains('flutter'));`.

### ایمبیڈڈ اشیاء

ایمبیڈڈ اشیاء اسر کی سب سے مفید خصوصیات میں سے ایک ہیں۔ اعلیٰ سطحی اشیاء کے لیے دستیاب انہی شرائط کا استعمال کرتے ہوئے ان سے بہت مؤثر طریقے سے استفسار کیا جا سکتا ہے۔ آئیے فرض کریں کہ ہمارے پاس مندرجہ ذیل ماڈل ہے:

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

We want to query all cars that have a brand with the name `"BMW"` and the country `"Germany"`. We can do this using the following query:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

ہمیشہ نیسٹڈ سوالات کو گروپ کرنے کی کوشش کریں۔ مندرجہ بالا استفسار درج ذیل سے زیادہ موثر ہے۔ اگرچہ نتیجہ ایک ہی ہے:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### لنکس

اگر آپ کے ماڈل میں [لنک یا بیک لنکس](لنک) ہیں تو آپ لنک شدہ اشیاء یا منسلک اشیاء کی تعداد کی بنیاد پر اپنے استفسار کو فلٹر کر سکتے ہیں۔

:::warning
ذہن میں رکھیں کہ لنک کے سوالات مہنگے ہوسکتے ہیں کیونکہ اسر کو منسلک اشیاء کو تلاش کرنے کی ضرورت ہے۔ اس کے بجائے سرایت شدہ اشیاء استعمال کرنے پر غور کریں۔
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

ہم ان تمام طلباء کو تلاش کرنا چاہتے ہیں جن کے پاس ریاضی یا انگریزی کے استاد ہیں:

```dart
final result = await isar.students.filter()
  .teachers((q) {
    return q.subjectEqualTo('Math')
      .or()
      .subjectEqualTo('English');
  }).findAll();
```

Link filters evaluate to `true` if at least one linked object matches the conditions.

Let's search for all students that have no teachers:
  
```dart
final result = await isar.students.filter().teachersLengthEqualTo(0).findAll();
```

or alternatively:

```dart
final result = await isar.students.filter().teachersIsEmpty().findAll();
```

## جہاں کلازز

جہاں شقیں ایک بہت طاقتور ٹول ہیں، لیکن انہیں درست کرنا تھوڑا مشکل ہو سکتا ہے۔

فلٹرز کے برعکس جہاں شقیں استفسار کے حالات کو چیک کرنے کے لیے اسکیما میں بیان کردہ اشاریہ جات کا استعمال کرتی ہیں۔ انڈیکس سے استفسار کرنا ہر ریکارڈ کو انفرادی طور پر فلٹر کرنے سے کہیں زیادہ تیز ہے۔

➡️ Learn more: [Indexes](indexes)

:::tip
ایک بنیادی اصول کے طور پر، آپ کو ہمیشہ جہاں تک ممکن ہو وہاں کی شقوں کا استعمال کرتے ہوئے ریکارڈ کو کم کرنے کی کوشش کرنی چاہیے اور باقی فلٹرنگ فلٹرز کا استعمال کرتے ہوئے کرنی چاہیے۔
:::

آپ صرف منطقی **یا** کا استعمال کرتے ہوئے شقوں کو جوڑ سکتے ہیں۔ دوسرے الفاظ میں، آپ متعدد جہاں شقوں کو ایک ساتھ جمع کر سکتے ہیں، لیکن آپ متعدد جہاں شقوں کے تقاطع سے استفسار نہیں کر سکتے۔

آئیے جوتوں کے مجموعہ میں اشاریہ جات شامل کریں:

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

There are two indexes. The index on `size` allows us to use where clauses like `.sizeEqualTo()`. The composite index on `isUnisex` allows where clauses like `isUnisexSizeEqualTo()`. But also `isUnisexEqualTo()` because you can always use any prefix of an index.

اب ہم کمپوزٹ انڈیکس کا استعمال کرتے ہوئے 46 سائز میں یونیسیکس جوتے تلاش کرنے سے پہلے کے سوال کو دوبارہ لکھ سکتے ہیں۔ یہ استفسار پچھلی کی نسبت بہت تیز ہوگا:

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

Where clauses have two more superpowers: They give you "free" sorting and a super fast distinct operation.

### جہاں شقوں اور فلٹرز کو ملانا

Remember the `shoes.filter()` queries? It's actually just a shortcut for `shoes.where().filter()`. You can (and should) combine where clauses and filters in the same query to use the benefits of both:

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

جہاں شق پہلے لاگو کی جاتی ہے تاکہ فلٹر کیے جانے والے آبجیکٹ کی تعداد کو کم کیا جا سکے۔ پھر فلٹر بقیہ آبجیکٹس پر لاگو ہوتا ہے۔

## چھانٹنا
You can define how the results should be sorted when executing the query using the `.sortBy()`, `.sortByDesc()`, `.thenBy()` and `.thenByDesc()` methods.

انڈیکس کا استعمال کیے بغیر تمام جوتوں کو ماڈل کے نام کے مطابق صعودی ترتیب اور نزولی ترتیب میں سائز تلاش کرنے کے لیے:

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

بہت سے نتائج کو ترتیب دینا مہنگا ہو سکتا ہے، خاص طور پر چونکہ چھانٹنا آفسیٹ اور حد سے پہلے ہوتا ہے۔ اوپر چھانٹنے کے طریقے کبھی بھی اشاریہ جات کا استعمال نہیں کرتے ہیں۔ خوش قسمتی سے، ہم دوبارہ استعمال کر سکتے ہیں جہاں شق چھانٹنا ہے اور اپنی استفسار کو تیز رفتار بنا سکتے ہیں چاہے ہمیں ایک ملین اشیاء کو ترتیب دینے کی ضرورت ہو۔

### جہاں شق کی چھانٹی

اگر آپ اپنی استفسار میں ایک **سنگل** جہاں شق استعمال کرتے ہیں، تو نتائج پہلے ہی انڈیکس کے مطابق ترتیب دیئے گئے ہیں۔ یہ ایک بڑی بات ہے!

Let's assume we have shoes in sizes `[43, 39, 48, 40, 42, 45]` and we want to find all shoes with a size greater than `42` and also have them sorted by size:

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // also sorts the results by size
  .findAll(); // -> [43, 45, 48]
```

As you can see, the result is sorted by the `size` index. If you want to reverse the where clause sort order, you can set `sort` to `Sort.desc`:

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

بعض اوقات آپ جہاں کی شق استعمال نہیں کرنا چاہتے لیکن پھر بھی مضمر چھانٹی سے فائدہ اٹھاتے ہیں۔ آپ 'کوئی' استعمال کر سکتے ہیں جہاں شق:

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

اگر آپ ایک جامع اشاریہ استعمال کرتے ہیں، تو نتائج کو اشاریہ کے تمام شعبوں کے حساب سے ترتیب دیا جاتا ہے۔

:::tip
If you need the results to be sorted, consider using an index for that purpose. Especially if you work with `offset()` and `limit()`.
:::

بعض اوقات چھانٹنے کے لیے اشاریہ استعمال کرنا ممکن یا مفید نہیں ہوتا ہے۔ اس طرح کے معاملات کے لیے، آپ کو انڈیکس کا استعمال کرنا چاہیے تاکہ نتیجے میں آنے والے اندراجات کی تعداد کو جتنا ممکن ہو کم کیا جا سکے۔

## منفرد اقدار

منفرد قدروں کے ساتھ صرف اندراجات واپس کرنے کے لیے، الگ پیش گوئی کا استعمال کریں۔ مثال کے طور پر، یہ معلوم کرنے کے لیے کہ آپ کے ای زار ڈیٹا بیس میں آپ کے جوتوں کے کتنے مختلف ماڈل ہیں:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

آپ الگ الگ ماڈل سائز کے امتزاج کے ساتھ تمام جوتوں کو تلاش کرنے کے لیے متعدد مختلف شرائط کو بھی جوڑ سکتے ہیں:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

ہر ایک الگ امتزاج کا صرف پہلا نتیجہ واپس آتا ہے۔ آپ اسے کنٹرول کرنے کے لیے جہاں کی شقیں اور چھانٹنے کی کارروائیاں استعمال کر سکتے ہیں۔

### جہاں شق الگ ہے۔

اگر آپ کے پاس غیر منفرد انڈیکس ہے، تو آپ اس کی تمام الگ الگ اقدار حاصل کرنا چاہتے ہیں۔ آپ پچھلے حصے سے `distinctBy` آپریشن استعمال کر سکتے ہیں، لیکن یہ چھانٹنے اور فلٹر کرنے کے بعد انجام دیا جاتا ہے، اس لیے کچھ اوور ہیڈ ہے۔
اگر آپ صرف ایک جہاں کی شق استعمال کرتے ہیں، تو آپ اس کے بجائے الگ آپریشن کرنے کے لیے انڈیکس پر انحصار کر سکتے ہیں۔

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
نظریہ میں، آپ یہاں تک کہ ایک سے زیادہ استعمال کر سکتے ہیں جہاں چھانٹنے اور الگ کرنے کے لیے شقیں ہیں۔ پابندی صرف یہ ہے کہ جہاں شقیں اوور لیپنگ نہ ہوں اور وہی انڈیکس استعمال کریں۔ درست چھانٹنے کے لیے، انہیں بھی ترتیب کے لحاظ سے لاگو کرنے کی ضرورت ہے۔ اگر آپ اس پر بھروسہ کرتے ہیں تو بہت محتاط رہیں!
:::

## آفسیٹ اور حد

سست فہرست کے نظارے کے لیے استفسار کے نتائج کی تعداد کو محدود کرنا اکثر اچھا خیال ہوتا ہے۔ آپ ایک `لیمٹ()` سیٹ کر کے ایسا کر سکتے ہیں:

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

By setting an `offset()` you can also paginate the results of your query.

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

چونکہ ڈارٹ آبجیکٹ کو انسٹیٹیوٹ کرنا اکثر استفسار پر عمل کرنے کا سب سے مہنگا حصہ ہوتا ہے، اس لیے یہ ایک اچھا خیال ہے کہ آپ کو مطلوبہ اشیاء کو لوڈ کیا جائے۔

## ایگزیکیوشن آرڈر
ای زار سوالات کو ہمیشہ اسی ترتیب میں انجام دیتا ہے:

1. اشیاء تلاش کرنے کے لیے پرائمری یا سیکنڈری انڈیکس کو عبور کریں (جہاں شقیں لگائیں)
2. اشیاء کو فلٹر کریں۔
3. نتائج ترتیب دیں۔
4. الگ آپریشن کا اطلاق کریں۔
5. آف سیٹ اور نتائج کو محدود کریں۔
6. نتائج واپس کریں۔

## استفسار کے آپریشنز

In the previous examples, we used `.findAll()` to retrieve all matching objects. There are more operations available, however:

| Operation        | Description                                                                                                         |
| ---------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.findFirst()`   | Retreive only the first matching object or `null` if none matches.                                                  |
| `.findAll()`     | Retreive all matching objects.                                                                                      |
| `.count()`       | Count how many objects match the query.                                                                             |
| `.deleteFirst()` | Delete the first matching object from the collection.                                                               |
| `.deleteAll()`   | Delete all matching objects from the collection.                                                                    |
| `.build()`       | Compile the query to reuse it later. This saves the cost to build a query if you want to execute it multiple times. |

## پراپرٹی کے سوالات

اگر آپ صرف ایک پراپرٹی کی قدروں میں دلچسپی رکھتے ہیں، تو آپ پراپرٹی استفسار استعمال کرسکتے ہیں۔ بس ایک باقاعدہ استفسار بنائیں اور ایک پراپرٹی منتخب کریں:

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

صرف ایک پراپرٹی کا استعمال ڈی سیریلائزیشن کے دوران وقت بچاتا ہے۔ پراپرٹی کے سوالات ایمبیڈڈ اشیاء اور فہرستوں کے لیے بھی کام کرتے ہیں۔

## جمع کرنا

اسار پراپرٹی کے سوال کی قدروں کو جمع کرنے کی حمایت کرتا ہے۔ مندرجہ ذیل جمع آپریشن دستیاب ہیں:

| Operation    | Description                                                    |
| ------------ | -------------------------------------------------------------- |
| `.min()`     | Finds the minimum value or `null` if none matches.             |
| `.max()`     | Finds the maximum value or `null` if none matches.             |
| `.sum()`     | Sums all values.                                               |
| `.average()` | Calculates the average of all values or `NaN` if none matches. |

جمع کا استعمال تمام مماثل اشیاء کو تلاش کرنے اور دستی طور پر جمع کرنے سے کہیں زیادہ تیز ہے۔

## متحرک سوالات

:::danger
یہ سیکشن غالباً آپ سے متعلق نہیں ہے۔ متحرک سوالات استعمال کرنے کی حوصلہ شکنی کی جاتی ہے جب تک کہ آپ کو بالکل ضرورت نہ ہو (اور آپ شاذ و نادر ہی کرتے ہیں)۔
:::

All the examples above used the QueryBuilder and the generated static extension methods. Maybe you want to create dynamic queries or a custom query language (like the Isar Inspector). In that case, you can use the `buildQuery()` method:

| Parameter       | Description                                                                                 |
| --------------- | ------------------------------------------------------------------------------------------- |
| `whereClauses`  | The where clauses of the query.                                                             |
| `whereDistinct` | Whether where clauses should return distinct values (only useful for single where clauses). |
| `whereSort`     | The traverse order of the where clauses (only useful for single where clauses).             |
| `filter`        | The filter to apply to the results.                                                         |
| `sortBy`        | A list of properties to sort by.                                                            |
| `distinctBy`    | A list of properties to distinct by.                                                        |
| `offset`        | The offset of the results.                                                                  |
| `limit`         | The maximum number of results to return.                                                    |
| `property`      | If non-null, only the values of this property are returned.                                 |

آئیے ایک متحرک استفسار بنائیں:

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

درج ذیل استفسار مساوی ہے:

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
