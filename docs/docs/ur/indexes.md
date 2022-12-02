---
title: انڈیکسز
---

# اشاریہ جات

اشاریہ جات اسار کی سب سے طاقتور خصوصیت ہیں۔ بہت سے ایمبیڈڈ ڈیٹا بیس "نارمل" اشاریہ جات پیش کرتے ہیں (اگر بالکل بھی ہیں)، لیکن اسر کے پاس جامع اور ملٹی انٹری انڈیکس بھی ہوتے ہیں۔ یہ سمجھنا کہ اشاریہ جات کیسے کام کرتے ہیں استفسار کی کارکردگی کو بہتر بنانے کے لیے ضروری ہے۔ ای زار آپ کو یہ منتخب کرنے دیتا ہے کہ آپ کون سا انڈیکس استعمال کرنا چاہتے ہیں اور آپ اسے کیسے استعمال کرنا چاہتے ہیں۔ ہم ایک فوری تعارف کے ساتھ شروع کریں گے کہ اشاریہ جات کیا ہیں۔

## اشاریہ جات کیا ہیں؟

جب کسی مجموعے کو انڈیکس نہیں کیا جاتا ہے تو، قطاروں کی ترتیب کو کسی بھی طرح سے آپٹمائز کیے گئے استفسار کے ذریعے واضح نہیں کیا جا سکتا ہے، اور اس لیے آپ کے استفسار کو اشیاء کے ذریعے لکیری طور پر تلاش کرنا پڑے گا۔ دوسرے لفظوں میں، استفسار کو حالات سے مماثل چیزوں کو تلاش کرنے کے لیے ہر شے کے ذریعے تلاش کرنا ہوگی۔ جیسا کہ آپ تصور کر سکتے ہیں، اس میں کچھ وقت لگ سکتا ہے۔ ہر ایک چیز کو تلاش کرنا زیادہ کارآمد نہیں ہے۔

For example, this `Product` collection is entirely unordered.

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

#### ڈیٹا:

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

ایک سوال جو تمام پروڈکٹس کو تلاش کرنے کی کوشش کرتا ہے جن کی قیمت €30 سے ​​زیادہ ہے تمام نو قطاروں میں تلاش کرنا پڑتی ہے۔ یہ نو قطاروں کے لیے کوئی مسئلہ نہیں ہے، لیکن یہ 100k قطاروں کے لیے ایک مسئلہ بن سکتا ہے۔

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

اس استفسار کی کارکردگی کو بہتر بنانے کے لیے، ہم `قیمت` پراپرٹی کو انڈیکس کرتے ہیں۔ ایک انڈیکس ایک ترتیب شدہ تلاش کی میز کی طرح ہے:

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

#### تیار کردہ انڈیکس:

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

اب، استفسار بہت تیزی سے عمل میں لایا جا سکتا ہے۔ ایگزیکیوٹر براہ راست آخری تین انڈیکس قطاروں میں جا سکتا ہے اور متعلقہ اشیاء کو ان کی آئی ڈی سے تلاش کر سکتا ہے۔

### چھانٹنا

ایک اور عمدہ چیز: اشاریہ جات انتہائی تیز چھانٹ سکتے ہیں۔ ترتیب شدہ سوالات مہنگے ہوتے ہیں کیونکہ ڈیٹا بیس کو تمام نتائج کو ترتیب دینے سے پہلے میموری میں لوڈ کرنا ہوتا ہے۔ یہاں تک کہ اگر آپ آفسیٹ یا حد کی وضاحت کرتے ہیں، تو وہ چھانٹنے کے بعد لاگو ہوتے ہیں۔

آئیے تصور کریں کہ ہم چار سب سے سستی مصنوعات تلاش کرنا چاہتے ہیں۔ ہم درج ذیل استفسار استعمال کر سکتے ہیں:

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

اس مثال میں، ڈیٹا بیس کو تمام (!) اشیاء کو لوڈ کرنا ہوگا، قیمت کے لحاظ سے ترتیب دینا ہوگا، اور چار مصنوعات کو سب سے کم قیمت کے ساتھ واپس کرنا ہوگا۔

جیسا کہ آپ شاید تصور کر سکتے ہیں، یہ پچھلے انڈیکس کے ساتھ بہت زیادہ مؤثر طریقے سے کیا جا سکتا ہے. ڈیٹا بیس انڈیکس کی پہلی چار قطاریں لیتا ہے اور متعلقہ اشیاء کو واپس کرتا ہے کیونکہ وہ پہلے سے ہی درست ترتیب میں ہیں۔

انڈیکس کو ترتیب دینے کے لیے استعمال کرنے کے لیے، ہم استفسار کو اس طرح لکھیں گے:

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

The `.anyX()` where clause tells Isar to use an index just for sorting. You can also use a where clause like `.priceGreaterThan()` and get sorted results.

## منفرد اشاریہ جات

ایک منفرد انڈیکس اس بات کو یقینی بناتا ہے کہ انڈیکس میں کوئی ڈپلیکیٹ قدر شامل نہیں ہے۔ یہ ایک یا متعدد خصوصیات پر مشتمل ہوسکتا ہے۔ اگر ایک منفرد انڈیکس میں ایک خاصیت ہے، تو اس خاصیت کی قدریں منفرد ہوں گی۔ اگر منفرد انڈیکس میں ایک سے زیادہ خاصیتیں ہیں، تو ان خصوصیات میں اقدار کا مجموعہ منفرد ہے۔

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

منفرد انڈیکس میں ڈیٹا داخل کرنے یا اپ ڈیٹ کرنے کی کوئی بھی کوشش جو ڈپلیکیٹ کا سبب بنتی ہے اس کے نتیجے میں ایک خرابی ہوگی:

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

// try to insert user with same username
await isar.users.put(user2); // -> error: unique constraint violated
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## اشاریہ جات کو تبدیل کریں۔

اگر کسی انوکھی رکاوٹ کی خلاف ورزی کی جاتی ہے تو بعض اوقات غلطی کرنا بہتر نہیں ہوتا۔ اس کے بجائے، آپ موجودہ آبجیکٹ کو نئے سے تبدیل کرنا چاہیں گے۔ یہ انڈیکس کی 'ری پلیس' پراپرٹی کو 'سچ' پر سیٹ کر کے حاصل کیا جا سکتا ہے۔

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

اب جب ہم موجودہ صارف نام کے ساتھ کسی صارف کو داخل کرنے کی کوشش کرتے ہیں، تو ای زار موجودہ صارف کو نئے صارف کے ساتھ بدل دے گا۔

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

انڈیکس کو تبدیل کرنے سے `پٹ بائی()` طریقے بھی تیار ہوتے ہیں جو آپ کو اشیاء کو تبدیل کرنے کے بجائے اپ ڈیٹ کرنے کی اجازت دیتے ہیں۔ موجودہ آئی ڈی کو دوبارہ استعمال کیا جاتا ہے، اور لنکس اب بھی آباد ہیں۔

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// user does not exist so this is the same as put()
await isar.users.putByUsername(user1); 
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

جیسا کہ آپ دیکھ سکتے ہیں، پہلے داخل کردہ صارف کی شناخت دوبارہ استعمال کی جاتی ہے۔

## کیس غیر حساس اشاریہ جات

All indexes on `String` and `List<String>` properties are case-sensitive by default. If you want to create a case-insensitive index, you can use the `caseSensitive` option:

```dart
@collection
class Person {
  Id? id;

  @Index(caseSensitive: false)
  late String name;

  @Index(caseSensitive: false)
  late List<String> tags;
}
```

## انڈیکس کی قسم

اشاریہ جات کی مختلف اقسام ہیں۔ زیادہ تر وقت، آپ ایک `IndexType.value` انڈیکس استعمال کرنا چاہیں گے، لیکن ہیش انڈیکس زیادہ موثر ہوتے ہیں۔

### ویلیو انڈیکس

ویلیو انڈیکس ڈیفالٹ قسم ہیں اور ان تمام پراپرٹیز کے لیے صرف ایک کی اجازت ہے جس میں سٹرنگز یا فہرستیں نہیں ہیں۔ انڈیکس بنانے کے لیے پراپرٹی ویلیوز کا استعمال کیا جاتا ہے۔ فہرستوں کے معاملے میں، فہرست کے عناصر استعمال کیے جاتے ہیں۔ یہ تینوں انڈیکس اقسام میں سب سے زیادہ لچکدار ہے لیکن جگہ استعمال کرنے والا بھی ہے۔

:::tip
Use `IndexType.value` for primitives, Strings where you need `startsWith()` where clauses, and Lists if you want to search for individual elements.
:::

### ہیش انڈیکس

انڈیکس کے لیے درکار اسٹوریج کو نمایاں طور پر کم کرنے کے لیے سٹرنگز اور لسٹوں کو ہیش کیا جا سکتا ہے۔ ہیش اشاریہ جات کا نقصان یہ ہے کہ انہیں سابقہ ​​اسکین کے لیے استعمال نہیں کیا جا سکتا (`startsWith` جہاں شقیں ہیں)۔

:::tip
Use `IndexType.hash` for Strings and Lists if you don't need `startsWith`, and `elementEqualTo` where clauses.
:::

### HashElements انڈیکس

String lists can be hashed as a whole (using `IndexType.hash`), or the elements of the list can be hashed separately (using `IndexType.hashElements`), effectively creating a multi-entry index with hashed elements.

:::tip
Use `IndexType.hashElements` for `List<String>` where you need `elementEqualTo` where clauses.
:::

## جامع اشاریہ جات

ایک جامع اشاریہ متعدد خصوصیات پر مشتمل ایک اشاریہ ہے۔ ای زار آپ کو تین خصوصیات تک کے جامع اشاریہ جات بنانے کی اجازت دیتا ہے۔

جامع اشاریہ جات کو متعدد کالم اشاریہ جات کے نام سے بھی جانا جاتا ہے۔

شاید ایک مثال کے ساتھ شروع کرنا بہتر ہے۔ ہم ایک شخص کا مجموعہ بناتے ہیں اور عمر اور نام کی خصوصیات پر ایک جامع انڈیکس کی وضاحت کرتے ہیں:

```dart
@collection
class Person {
  Id? id;

  late String name;

  @Index(composite: [CompositeIndex('name')])
  late int age;

  late String hometown;
}
```

#### Data:

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

#### تیار کردہ انڈیکس

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

تیار کردہ کمپوزٹ انڈیکس میں تمام افراد کو ان کی عمر کے لحاظ سے ان کے نام سے ترتیب دیا گیا ہے۔

جامع اشاریہ جات بہت اچھے ہیں اگر آپ ایک سے زیادہ خصوصیات کے لحاظ سے ترتیب دی گئی موثر سوالات تخلیق کرنا چاہتے ہیں۔ وہ متعدد خصوصیات کے ساتھ اعلی درجے کی جہاں شقوں کو بھی فعال کرتے ہیں:

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

جامع انڈیکس کی آخری خاصیت بھی اس طرح کی شرائط کی حمایت کرتی ہے۔ `startsWith()` or `lessThan()`:

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## ملٹی انٹری انڈیکس

If you index a list using `IndexType.value`, Isar خود بخود ملٹی انٹری انڈیکس بنائے گا، اور فہرست میں موجود ہر آئٹم کو آبجیکٹ کی طرف انڈیکس کیا جاتا ہے۔ یہ تمام اقسام کی فہرستوں کے لیے کام کرتا ہے۔

ملٹی انٹری انڈیکس کے لیے عملی ایپلی کیشنز میں ٹیگز کی فہرست کو انڈیکس کرنا یا مکمل ٹیکسٹ انڈیکس بنانا شامل ہے۔

```dart
@collection
class Product {
  Id? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` splits a string into words according to the [Unicode Annex #29](https://unicode.org/reports/tr29/) specification, so it works for almost all languages correctly.

#### ڈیٹا:

| id  | description                  | descriptionWords             |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

Entries with duplicate words only appear once in the index.

#### تیار کردہ انڈیکس

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

یہ انڈیکس اب سابقہ ​​(یا مساوات) کے لیے استعمال کیا جا سکتا ہے جہاں وضاحت کے انفرادی الفاظ کی شقیں ہیں۔

:::tip
Instead of storing the words directly, also consider using the result of a [phonectic algorithm](https://en.wikipedia.org/wiki/Phonetic_algorithm) like [Soundex](https://en.wikipedia.org/wiki/Soundex).
:::
