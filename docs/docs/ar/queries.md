---
title: الاستعلامات (Queries)
---

# الاستعلامات (Queries)

الاستعلام هو الطريقة التي تجد بها السجلات التي تطابق شروطاً معينة، على سبيل المثال:

- العثور على جميع جهات الاتصال المميزة بنجمة.
- العثور على الأسماء الأولى الفريدة (distinct) في جهات الاتصال.
- حذف جميع جهات الاتصال التي ليس لها اسم عائلة محدد.

نظرًا لأن الاستعلامات يتم تنفيذها على قاعدة البيانات وليس في Dart، فهي سريعة جدًا. عندما تستخدم الفهارس (indexes) بذكاء، يمكنك تحسين أداء الاستعلام بشكل أكبر. في ما يلي، ستتعلم كيفية كتابة الاستعلامات وكيف يمكنك جعلها سريعة قدر الإمكان.

هناك طريقتان مختلفتان لتصفية سجلاتك: الفلاتر (Filters) وعبارات "أين" (where clauses). سنبدأ بإلقاء نظرة على كيفية عمل الفلاتر.

## الفلاتر (Filters)

الفلاتر سهلة الاستخدام والفهم. اعتماداً على نوع خصائصك، تتوفر عمليات تصفية مختلفة، ومعظمها له أسماء تشرح نفسها.

تعمل الفلاتر من خلال تقييم تعبير لكل كائن في المجموعة التي يتم تصفيتها. إذا كانت نتيجة التعبير `true` (صحيح)، يقوم Isar بتضمين الكائن في النتائج. لا تؤثر الفلاتر على ترتيب النتائج.

سنستخدم النموذج التالي للأمثلة أدناه:

```dart
@collection
class Shoe {
  late int id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### شروط الاستعلام (Query conditions)

اعتماداً على نوع الحقل، تتوفر شروط مختلفة.

| الشرط | الوصف |
| :--- | :--- |
| `.equalTo(value)` | يطابق القيم التي تساوي الـ `value` المحددة. |
| `.between(lower, upper)` | يطابق القيم التي تقع بين `lower` و `upper`. |
| `.greaterThan(bound)` | يطابق القيم التي تكون أكبر من `bound`. |
| `.lessThan(bound)` | يطابق القيم التي تكون أقل من `bound`. سيتم تضمين قيم `null` افتراضياً لأن `null` يُعتبر أصغر من أي قيمة أخرى. |
| `.isNull()` | يطابق القيم التي تكون `null`. |
| `.isNotNull()` | يطابق القيم التي ليست `null`. |
| `.length()` | استعلامات طول القائمة (List) والسلسلة النصية (String) والروابط (link) تقوم بتصفية الكائنات بناءً على عدد العناصر. |

دعنا نفترض أن قاعدة البيانات تحتوي على أربعة أحذية بمقاسات 39 و 40 و 46 وواحد بمقاس غير محدد (`null`). ما لم تقم بإجراء فرز، فسيتم إرجاع القيم مرتبة حسب المعرف (id).

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

### العمليات المنطقية (Logical operators)

يمكنك تركيب الشروط باستخدام العمليات المنطقية التالية:

| العملية | الوصف |
| :--- | :--- |
| `.and()` | تكون النتيجة `true` إذا كانت كل من التعبيرات اليسرى واليمنى `true`. |
| `.or()` | تكون النتيجة `true` إذا كان أي من التعبيرين `true`. |
| `.xor()` | تكون النتيجة `true` إذا كان تعبير واحد فقط `true`. |
| `.not()` | يعكس نتيجة التعبير التالي. |
| `.group()` | تجميع الشروط والسماح بتحديد ترتيب التقييم. |

إذا كنت تريد العثور على جميع الأحذية بمقاس 46، يمكنك استخدام الاستعلام التالي:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

إذا كنت تريد استخدام أكثر من شرط واحد، يمكنك دمج فلاتر متعددة باستخدام **and** المنطقي `.and()`، و **or** المنطقي `.or()`، و **xor** المنطقي `.xor()`.

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // اختياري. يتم دمج الفلاتر ضمنياً باستخدام and المنطقي.
  .isUnisexEqualTo(true)
  .findAll();
```

هذا الاستعلام يعادل: `size == 46 && isUnisex == true`.

يمكنك أيضاً تجميع الشروط باستخدام `.group()`:

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

هذا الاستعلام يعادل `size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)`.

لعكس شرط أو مجموعة، استخدم **not** المنطقي `.not()`:

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

هذا الاستعلام يعادل `size != 46 && isUnisex != true`.

### شروط السلاسل النصية (String conditions)

بالإضافة إلى شروط الاستعلام أعلاه، توفر قيم السلاسل النصية (String) بضعة شروط أخرى يمكنك استخدامها. تسمح الرموز البديلة (Wildcards) الشبيهة بـ Regex، على سبيل المثال، بمزيد من المرونة في البحث.

| الشرط | الوصف |
| :--- | :--- |
| `.startsWith(value)` | يطابق قيم السلسلة التي تبدأ بـ `value` المقدمة. |
| `.contains(value)` | يطابق قيم السلسلة التي تحتوي على `value` المقدمة. |
| `.endsWith(value)` | يطابق قيم السلسلة التي تنتهي بـ `value` المقدمة. |
| `.matches(wildcard)` | يطابق قيم السلسلة التي تطابق نمط الرمز البديل `wildcard` المقدم. |

**حساسية حالة الأحرف (Case sensitivity)**
جميع عمليات السلاسل النصية لها معلمة `caseSensitive` اختيارية تكون قيمتها الافتراضية `true`.

**الرموز البديلة (Wildcards):**
تعبير الرمز البديل (wildcard string expression) هو سلسلة تستخدم أحرفاً عادية مع حرفين خاصين للرموز البديلة:

- الرمز البديل `*` يطابق صفراً أو أكثر من أي حرف.
- الرمز البديل `?` يطابق أي حرف واحد.
على سبيل المثال، السلسلة `"d?g"` تطابق `"dog"` و `"dig"` و `"dug"`، ولكنها لا تطابق `"ding"` أو `"dg"` أو `"a dog"`.

### معدلات الاستعلام (Query modifiers)

أحياناً يكون من الضروري بناء استعلام بناءً على بعض الشروط أو لقيم مختلفة. يمتلك Isar أداة قوية جداً لبناء الاستعلامات الشرطية:

| المعدل | الوصف |
| :--- | :--- |
| `.optional(cond, qb)` | يوسع الاستعلام فقط إذا كان الشرط `condition` هو `true`. يمكن استخدام هذا في أي مكان تقريباً في الاستعلام، على سبيل المثال لفرز الاستعلام أو تقييده شرطياً. |
| `.anyOf(list, qb)` | يوسع الاستعلام لكل قيمة في القائمة `list` ويدمج الشروط باستخدام **or** المنطقي. |
| `.allOf(list, qb)` | يوسع الاستعلام لكل قيمة في القائمة `list` ويدمج الشروط باستخدام **and** المنطقي. |

في هذا المثال، نقوم ببناء طريقة يمكنها العثور على الأحذية بفلتر اختياري:

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // لا يتم تطبيق الفلتر إلا إذا كان sizeFilter != null
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

إذا كنت تريد العثور على جميع الأحذية التي لها واحد من مقاسات أحذية متعددة، يمكنك إما كتابة استعلام تقليدي أو استخدام معدل `anyOf()`:

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

تعد معدلات الاستعلام مفيدة بشكل خاص عندما تريد بناء استعلامات ديناميكية.

### القوائم (Lists)

حتى القوائم يمكن الاستعلام عنها:

```dart
class Tweet {
  late int id;

  String? text;

  List<String> hashtags = [];
}
```

يمكنك الاستعلام بناءً على طول القائمة:

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

هذه تعادل كود Dart التالي: `tweets.where((t) => t.hashtags.isEmpty);` و `tweets.where((t) => t.hashtags.length > 5);`. يمكنك أيضاً الاستعلام بناءً على عناصر القائمة:

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

هذا يعادل كود Dart التالي: `tweets.where((t) => t.hashtags.contains('flutter'));`.

### الكائنات المضمنة (Embedded objects)

تعد الكائنات المضمنة واحدة من أكثر ميزات Isar فائدة. يمكن الاستعلام عنها بكفاءة عالية باستخدام نفس الشروط المتاحة للكائنات ذات المستوى الأعلى. لنفترض أن لدينا النموذج التالي:

```dart
@collection
class Car {
  late int id;

  Brand? brand;
}

@embedded
class Brand {
  String? name;

  String? country;
}
```

نريد الاستعلام عن جميع السيارات التي لها علامة تجارية باسم `"BMW"` والبلد `"Germany"`. يمكننا القيام بذلك باستخدام الاستعلام التالي:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

حاول دائماً تجميع الاستعلامات المتداخلة. الاستعلام أعلاه أكثر كفاءة من الاستعلام التالي، على الرغم من أن النتيجة هي نفسها:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### الروابط (Links)

إذا كان نموذجك يحتوي على [روابط أو روابط عكسية](links)، يمكنك تصفية استعلامك بناءً على الكائنات المرتبطة أو عدد الكائنات المرتبطة.

| العملية | الوصف |
| :--- | :--- |
| `.findFirst()` | استرجاع أول كائن مطابق فقط أو `null` إذا لم يطابق أي شيء. |
| `.findAll()` | استرجاع جميع الكائنات المطابقة. |
| `.count()` | حساب عدد الكائنات التي تطابق الاستعلام. |
| `.deleteFirst()` | حذف أول كائن مطابق من المجموعة. |
| `.deleteAll()` | حذف جميع الكائنات المطابقة من المجموعة. |
| `.build()` | تجميع الاستعلام لإعادة استخدامه لاحقاً. هذا يوفر تكلفة بناء الاستعلام إذا كنت تريد تنفيذه عدة مرات. |

## استعلامات الخصائص (Property queries)

إذا كنت مهتماً فقط بقيم خاصية واحدة، يمكنك استخدام استعلام الخاصية. ما عليك سوى بناء استعلام عادي واختيار خاصية:

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

استخدام خاصية واحدة فقط يوفر الوقت أثناء عملية إلغاء التسلسل (deserialization). تعمل استعلامات الخصائص أيضاً للكائنات المضمنة والقوائم.

## التجميع (Aggregation)

يدعم Isar تجميع قيم استعلام الخاصية. تتوفر عمليات التجميع التالية:

| العملية | الوصف |
| :--- | :--- |
| `.min()` | يجد القيمة الدنيا أو `null` إذا لم يطابق أي شيء. |
| `.max()` | يجد القيمة القصوى أو `null` إذا لم يطابق أي شيء. |
| `.sum()` | يجمع كل القيم. |
| `.average()` | يحسب متوسط جميع القيم أو `NaN` إذا لم يطابق أي شيء. |

استخدام التجميعات أسرع بكثير من العثور على جميع الكائنات المطابقة وإجراء التجميع يدوياً.

## الاستعلامات الديناميكية (Dynamic queries)

:::danger
هذا القسم على الأرجح ليس ذا صلة بك. لا يُنصح باستخدام الاستعلامات الديناميكية إلا إذا كنت بحاجة ماسة إليها (ونادراً ما تحتاج إليها).
:::

استخدمت جميع الأمثلة أعلاه `QueryBuilder` وطرق التوسيع الثابتة التي تم إنشاؤها. ربما تريد إنشاء استعلامات ديناميكية أو لغة استعلام مخصصة (مثل Isar Inspector). في هذه الحالة، يمكنك استخدام طريقة `buildQuery()`:

| المعلمة | الوصف |
| :--- | :--- |
| `whereClauses` | عبارات "أين" الخاصة بالاستعلام. |
| `whereDistinct` | ما إذا كان يجب أن تعيد عبارات "أين" قيماً فريدة (مفيد فقط لعبارات "أين" الفردية). |
| `whereSort` | ترتيب التنقل في عبارات "أين" (مفيد فقط لعبارات "أين" الفردية). |
| `filter` | الفلتر المراد تطبيقه على النتائج. |
| `sortBy` | قائمة بالخصائص المراد الفرز حسبها. |
| `distinctBy` | قائمة بالخصائص المراد التمييز حسبها. |
| `offset` | إزاحة النتائج. |
| `limit` | الحد الأقصى لعدد النتائج المراد إرجاعها. |
| `property` | إذا لم يكن null، يتم إرجاع قيم هذه الخاصية فقط. |

دعنا ننشئ استعلاماً ديناميكياً:

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

الاستعلام التالي مكافئ له:

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
