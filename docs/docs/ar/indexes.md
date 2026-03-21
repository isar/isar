---
title: الفهارس (Indexes)
---

# الفهارس (Indexes)

تعد الفهارس أقوى ميزة في Isar. توفر العديد من قواعد البيانات المضمنة فهارس "عادية" (هذا إن وجدت أصلاً)، لكن Isar يمتلك أيضاً فهارس مركبة (composite) وفهارس متعددة المدخلات (multi-entry). يعد فهم كيفية عمل الفهارس أمراً ضرورياً لتحسين أداء الاستعلام. يتيح لك Isar اختيار الفهرس الذي تريد استخدامه وكيفية استخدامه. سنبدأ بمقدمة سريعة حول ماهية الفهارس.

## ما هي الفهارس؟

عندما تكون المجموعة غير مفهرسة، فمن المحتمل ألا يكون ترتيب الصفوف قابلاً للتمييز بواسطة الاستعلام كونه محسناً بأي شكل من الأشكال، وبالتالي سيتعين على استعلامك البحث عبر الكائنات بشكل خطي. بعبارة أخرى، سيتعين على الاستعلام البحث في كل كائن للعثور على الكائنات التي تطابق الشروط. كما يمكنك أن تتخيل، قد يستغرق ذلك بعض الوقت. البحث في كل كائن على حدة ليس فعالاً للغاية.

على سبيل المثال، مجموعة `Product` (منتج) هذه غير مرتبة تماماً.

```dart
@collection
class Product {
  late int id;

  late String name;

  late int price;
}
```

**البيانات:**

| id | name | price |
| :--- | :--- | :--- |
| 1 | Book | 15 |
| 2 | Table | 55 |
| 3 | Chair | 25 |
| 4 | Pencil | 3 |
| 5 | Lightbulb | 12 |
| 6 | Carpet | 60 |
| 7 | Pillow | 30 |
| 8 | Computer | 650 |
| 9 | Soap | 2 |

الاستعلام الذي يحاول العثور على جميع المنتجات التي تكلفتها أكثر من 30 يورو يجب أن يبحث في جميع الصفوف التسعة. هذه ليست مشكلة لتسعة صفوف، ولكنها قد تصبح مشكلة لـ 100 ألف صف.

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

لتحسين أداء هذا الاستعلام، نقوم بفهرسة خاصية `price` (السعر). الفهرس يشبه جدول بحث مرتب:

```dart
@collection
class Product {
  late int id;

  late String name;

  @Index()
  late int price;
}
```

**الفهرس الذي تم إنشاؤه:**

| price | id |
| :--- | :--- |
| 2 | 9 |
| 3 | 4 |
| 12 | 5 |
| 15 | 1 |
| 25 | 3 |
| 30 | 7 |
| <mark>**55**</mark> | <mark>**2**</mark> |
| <mark>**60**</mark> | <mark>**6**</mark> |
| <mark>**650**</mark> | <mark>**8**</mark> |

الآن، يمكن تنفيذ الاستعلام بشكل أسرع بكثير. يمكن للمنفذ القفز مباشرة إلى آخر ثلاثة صفوف في الفهرس والعثور على الكائنات المقابلة بواسطة معرفاتها (id).

### الفرز (Sorting)

شيء رائع آخر: يمكن للفهارس إجراء فرز سريع جداً. الاستعلامات المرتبة مكلفة لأن قاعدة البيانات يجب أن تحمل جميع النتائج في الذاكرة قبل فرزها. حتى إذا حددت إزاحة (offset) أو حداً (limit)، فسيتم تطبيقهما بعد الفرز.

دعنا نتخيل أننا نريد العثور على أرخص أربعة منتجات. يمكننا استخدام الاستعلام التالي:

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

في هذا المثال، سيتعين على قاعدة البيانات تحميل جميع (!) الكائنات، وفرزها حسب السعر، وإرجاع المنتجات الأربعة ذات السعر الأدنى.

كما يمكنك أن تتخيل على الأرجح، يمكن القيام بذلك بكفاءة أكبر بكثير باستخدام الفهرس السابق. تأخذ قاعدة البيانات أول أربعة صفوف من الفهرس وتعيد الكائنات المقابلة لأنها موجودة بالفعل بالترتيب الصحيح.

لاستخدام الفهرس للفرز، سنكتب الاستعلام بهذا الشكل:

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

تخبر عبارة "أين" `.anyX()` نظام Isar باستخدام الفهرس للفرز فقط. يمكنك أيضاً استخدام عبارة "أين" مثل `.priceGreaterThan()` والحصول على نتائج مرتبة.

## الفهارس الفريدة (Unique indexes)

يضمن الفهرس الفريد عدم احتواء الفهرس على أي قيم مكررة. قد يتكون من خاصية واحدة أو خصائص متعددة. إذا كان الفهرس الفريد يحتوي على خاصية واحدة، فستكون القيم في هذه الخاصية فريدة. إذا كان الفهرس الفريد يحتوي على أكثر من خاصية واحدة، فإن مزيج القيم في هذه الخصائص يكون فريداً.

```dart
@collection
class User {
  late int id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

أي محاولة لإدراج أو تحديث بيانات في الفهرس الفريد تتسبب في تكرار ستؤدي إلى خطأ:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> موافق

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

// محاولة إدراج مستخدم بنفس اسم المستخدم
await isar.users.put(user2); // -> خطأ: انتهاك قيد الفرادة (unique constraint)
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## استبدال الفهارس (Replace indexes)

أحياناً لا يكون من المفضل رمي خطأ إذا تم انتهاك قيد الفرادة. بدلاً من ذلك، قد ترغب في استبدال الكائن الموجود بالكائن الجديد. يمكن تحقيق ذلك عن طريق تعيين خاصية `replace` في الفهرس إلى `true`.

```dart
@collection
class User {
  late int id;

  @Index(unique: true, replace: true)
  late String username;
}
```

الآن عندما نحاول إدراج مستخدم باسم مستخدم موجود، سيقوم Isar باستبدال المستخدم الموجود بالمستخدم الجديد.

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

تولد فهارس الاستبدال أيضاً طرق `putBy()` التي تسمح لك بتحديث الكائنات بدلاً من استبدالها. يتم إعادة استخدام المعرف (id) الموجود، وتظل الروابط (links) ممتلئة.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// المستخدم غير موجود لذا هذا هو نفسه put()
await isar.users.putByUsername(user1);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

كما ترى، تمت إعادة استخدام معرف المستخدم الأول الذي تم إدراجه.

## الفهارس غير الحساسة لحالة الأحرف (Case-insensitive indexes)

تكون جميع الفهارس على خصائص `String` و `List<String>` حساسة لحالة الأحرف (case-sensitive) بشكل افتراضي. إذا كنت تريد إنشاء فهرس غير حساس لحالة الأحرف، يمكنك استخدام خيار `caseSensitive`:

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

## نوع الفهرس (Index type)

هناك أنواع مختلفة من الفهارس. في معظم الأوقات، سترغب في استخدام فهرس من نوع `IndexType.value` (القيمة)، لكن فهارس التجزئة (hash indexes) أكثر كفاءة.

### فهرس القيمة (Value index)

فهارس القيمة هي النوع الافتراضي والوحيد المسموح به لجميع الخصائص التي لا تحتوي على سلاسل نصية (Strings) أو قوائم (Lists). تُستخدم قيم الخصائص لبناء الفهرس. في حالة القوائم، تُستخدم عناصر القائمة. إنه النوع الأكثر مرونة ولكنه يستهلك مساحة أكبر من بين أنواع الفهارس الثلاثة.

:::tip
استخدم `IndexType.value` للأنواع الأولية (primitives)، والسلاسل النصية حيث تحتاج إلى عبارات "أين" من نوع `startsWith()`، والقوائم إذا كنت تريد البحث عن عناصر فردية.
:::

### فهرس التجزئة (Hash index)

يمكن تجزئة السلاسل النصية والقوائم لتقليل مساحة التخزين المطلوبة للفهرس بشكل كبير. عيب فهارس التجزئة هو أنه لا يمكن استخدامها لعمليات مسح البادئة (عبارات "أين" من نوع `startsWith`).

:::tip
استخدم `IndexType.hash` للسلاسل النصية والقوائم إذا كنت لا تحتاج إلى `startsWith` وعبارات "أين" من نوع `elementEqualTo`.
:::

### فهرس تجزئة العناصر (HashElements index)

يمكن تجزئة قوائم السلاسل النصية ككل (باستخدام `IndexType.hash`)، أو يمكن تجزئة عناصر القائمة بشكل منفصل (باستخدام `IndexType.hashElements`) مما يؤدي فعلياً إلى إنشاء فهرس متعدد المدخلات مع عناصر مجزأة.

:::tip
استخدم `IndexType.hashElements` لـ `List<String>` حيث تحتاج إلى عبارات "أين" من نوع `elementEqualTo`.
:::

## الفهارس المركبة (Composite indexes)

الفهرس المركب هو فهرس على خصائص متعددة. يتيح لك Isar إنشاء فهارس مركبة تصل إلى ثلاث خصائص.

تُعرف الفهارس المركبة أيضاً باسم الفهارس متعددة الأعمدة.

من الأفضل البدء بمثال. نقوم بإنشاء مجموعة أشخاص ونحدد فهرساً مركباً على خصائص العمر والاسم:

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

**البيانات:**

| id | name | age | hometown |
| :--- | :--- | :--- | :--- |
| 1 | Daniel | 20 | Berlin |
| 2 | Anne | 20 | Paris |
| 3 | Carl | 24 | San Diego |
| 4 | Simon | 24 | Munich |
| 5 | David | 20 | New York |
| 6 | Carl | 24 | London |
| 7 | Audrey | 30 | Prague |
| 8 | Anne | 24 | Paris |

**الفهرس الذي تم إنشاؤه:**

| age | name | id |
| :--- | :--- | :--- |
| 20 | Anne | 2 |
| 20 | Daniel | 1 |
| 20 | David | 5 |
| 24 | Anne | 8 |
| 24 | Carl | 3 |
| 24 | Carl | 6 |
| 24 | Simon | 4 |
| 30 | Audrey | 7 |

يحتوي الفهرس المركب الذي تم إنشاؤه على جميع الأشخاص مرتبين حسب أعمارهم وأسمائهم.

تعد الفهارس المركبة رائعة إذا كنت تريد إنشاء استعلامات فعالة مرتبة حسب خصائص متعددة. كما أنها تتيح عبارات "أين" متقدمة بخصائص متعددة:

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

تدعم الخاصية الأخيرة للفهرس المركب أيضاً شروطاً مثل `startsWith()` أو `lessThan()`:

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## الفهارس متعددة المدخلات (Multi-entry indexes)

إذا قمت بفهرسة قائمة باستخدام `IndexType.value` فسيقوم Isar تلقائياً بإنشاء فهرس متعدد المدخلات، ويتم فهرسة كل عنصر في القائمة باتجاه الكائن. يعمل هذا مع جميع أنواع القوائم.

تشمل التطبيقات العملية للفهارس متعددة المدخلات فهرسة قائمة من الوسوم (tags) أو إنشاء فهرس نصي كامل.

```dart
@collection
class Product {
  late int id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

تقوم `Isar.splitWords()` بتقسيم السلسلة النصية إلى كلمات وفقاً لمواصفات [Unicode Annex #29](https://unicode.org/reports/tr29/)، لذا فهي تعمل بشكل صحيح لجميع اللغات تقريباً.

**البيانات:**

| id | description | descriptionWords |
| :--- | :--- | :--- |
| 1 | comfortable blue t-shirt | [comfortable, blue, t-shirt] |
| 2 | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3 | plain red t-shirt | [plain, red, t-shirt] |
| 4 | red necktie (super red) | [red, necktie, super, red] |

تظهر المدخلات ذات الكلمات المكررة مرة واحدة فقط في الفهرس.

**الفهرس الذي تم إنشاؤه:**

| descriptionWords | id |
| :--- | :--- |
| comfortable | [1, 2] |
| blue | 1 |
| necktie | 4 |
| plain | 3 |
| pullover | 2 |
| red | [2, 3, 4] |
| super | 4 |
| t-shirt | [1, 3] |

يمكن الآن استخدام هذا الفهرس لعبارات "أين" من نوع البادئة (أو المساواة) للكلمات الفردية في الوصف.

:::tip
بدلاً من تخزين الكلمات مباشرة، فكر أيضاً في استخدام نتيجة [خوارزمية صوتية](https://en.wikipedia.org/wiki/Phonetic_algorithm) مثل [ساوندكس (Soundex)](https://en.wikipedia.org/wiki/Soundex).
:::
