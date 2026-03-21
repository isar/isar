---
title: الإنشاء والقراءة والتحديث والحذف (CRUD)
---

# الإنشاء والقراءة والتحديث والحذف (CRUD)

بمجرد تحديد مجموعاتك (collections)، تعلم كيفية التعامل معها وتعديلها!

## فتح Isar

قبل أن تتمكن من القيام بأي شيء، نحتاج إلى مثيل (instance) من Isar. يتطلب كل مثيل دليلاً (directory) بصلاحية كتابة حيث يمكن تخزين ملف قاعدة البيانات. إذا لم تحدد دليلاً، فسيقوم Isar بالعثور على دليل افتراضي مناسب للمنصة الحالية.

قم بتوفير جميع المخططات (schemas) التي تريد استخدامها مع مثيل Isar. إذا قمت بفتح مثيلات متعددة، فلا يزال يتعين عليك توفير نفس المخططات لكل مثيل.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.openAsync(
  schemas: [RecipeSchema],
  directory: dir.path,
);
```

يمكنك استخدام التكوين الافتراضي أو توفير بعض المعلمات (parameters) التالية:

| التكوين (Config) | الوصف |
| :--- | :--- |
| `name` | فتح مثيلات متعددة بأسماء مميزة. بشكل افتراضي، يتم استخدام `"default"`. |
| `directory` | موقع التخزين لهذا المثيل. غير مطلوب للويب. |
| `maxSizeMib` | الحجم الأقصى لملف قاعدة البيانات بالميجابايت (MiB). يستخدم Isar الذاكرة الافتراضية وهي ليست مورداً غير محدود، لذا كن حذراً في القيمة هنا. إذا فتحت مثيلات متعددة، فإنها تشترك في الذاكرة الافتراضية المتاحة، لذا يجب أن يكون لكل مثيل قيمة `maxSizeMib` أصغر. الافتراضي هو 2048. |
| `relaxedDurability` | يخفف من ضمان المتانة (durability) لزيادة أداء الكتابة. في حالة تعطل النظام (وليس تعطل التطبيق)، من الممكن فقدان آخر معاملة (transaction) تم تأكيدها. تلف البيانات غير ممكن. |
| `compactOnLaunch` | شروط للتحقق مما إذا كان يجب ضغط (compact) قاعدة البيانات عند فتح المثيل. |
| `inspector` | تمكين المفتش (Inspector) لإصدارات التصحيح (debug builds). بالنسبة لإصدارات الأداء (profile) والإصدارات النهائية (release)، يتم تجاهل هذا الخيار. |

إذا كان المثيل مفتوحاً بالفعل، فإن استدعاء `Isar.open()` سيعيد المثيل الموجود بغض النظر عن المعلمات المحددة. هذا مفيد لاستخدام Isar في عازل (isolate).

:::tip
فكر في استخدام حزمة [path_provider](https://pub.dev/packages/path_provider) للحصول على مسار صالح على جميع المنصات.
:::

موقع تخزين ملف قاعدة البيانات هو `directory/name.isar`

## القراءة من قاعدة البيانات

استخدم مثيلات `IsarCollection` للعثور على الكائنات من نوع معين في Isar والاستعلام عنها وإنشائها.

بالنسبة للأمثلة أدناه، نفترض أن لدينا مجموعة `Recipe` (وصفة) محددة كما يلي:

```dart
@collection
class Recipe {
  late int id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### الحصول على مجموعة (Collection)

تعيش جميع مجموعاتك في مثيل Isar. يمكنك الحصول على مجموعة الوصفات باستخدام:

```dart
final recipes = isar.recipes;
```

كان ذلك سهلاً! إذا كنت لا تريد استخدام أدوات الوصول للمجموعات (collection accessors)، يمكنك أيضاً استخدام طريقة `collection()`:

```dart
final recipes = isar.collection<Recipe>();
```

### الحصول على كائن (بواسطة المعرف id)

ليس لدينا بيانات في المجموعة بعد، ولكن دعنا نتظاهر بأن لدينا بيانات حتى نتمكن من الحصول على كائن تخيلي بالمعرف `123`:

```dart
final recipe = await isar.recipes.get(123);
```

تعيد `get()` كائن `Future` يحتوي إما على الكائن أو `null` إذا لم يكن موجوداً. جميع عمليات Isar غير متزامنة (asynchronous) بشكل افتراضي، ومعظمها له نظير متزامن (synchronous):

```dart
final recipe = isar.recipes.getSync(123);
```

:::warning
يجب أن تعتمد بشكل افتراضي على النسخة غير المتزامنة من الطرق في عازل واجهة المستخدم (UI isolate). وبما أن Isar سريع جداً، فغالباً ما يكون من المقبول استخدام النسخة المتزامنة.
:::

إذا كنت تريد الحصول على كائنات متعددة في وقت واحد، استخدم `getAll()` أو `getAllSync()`:

```dart
final recipe = await isar.recipes.getAll([1, 2]);
```

### الاستعلام عن الكائنات (Query objects)

بدلاً من الحصول على الكائنات بواسطة المعرف، يمكنك أيضاً الاستعلام عن قائمة من الكائنات التي تطابق شروطاً معينة باستخدام `.where()` و `.filter()`:

```dart
final allRecipes = await isar.recipes.where().findAll();

final favorites = await isar.recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ تعرف على المزيد: [الاستعلامات (Queries)](queries)

## تعديل قاعدة البيانات

لقد حان الوقت أخيراً لتعديل مجموعتنا! لإنشاء كائنات أو تحديثها أو حذفها، استخدم العمليات المعنية مغلفة في معاملة كتابة (write transaction):

```dart
await isar.writeTxn(() async {
  final recipe = await isar.recipes.get(123)

  recipe.isFavorite = false;
  await isar.recipes.put(recipe); // تنفيذ عمليات التحديث

  await isar.recipes.delete(123); // أو عمليات الحذف
});
```

➡️ تعرف على المزيد: [المعاملات (Transactions)](transactions)

### إدراج كائن (Insert object)

لحفظ كائن في Isar، قم بإدراجه في مجموعة. ستقوم طريقة `put()` في Isar إما بإدراج الكائن أو تحديثه اعتماداً على ما إذا كان موجوداً بالفعل في المجموعة أم لا.

إذا كان حقل المعرف `null` أو `Isar.autoIncrement`، فسيستخدم Isar معرفاً يزداد تلقائياً.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await isar.recipes.put(pancakes);
})
```

سيقوم Isar تلقائياً بتعيين المعرف للكائن إذا كان حقل `id` غير نهائي (non-final).

إدراج كائنات متعددة في وقت واحد سهل بنفس القدر:

```dart
await isar.writeTxn(() async {
  await isar.recipes.putAll([pancakes, pizza]);
})
```

### تحديث كائن (Update object)

يعمل كل من الإنشاء والتحديث باستخدام `collection.put(object)`. إذا كان المعرف `null` (أو غير موجود)، يتم إدراج الكائن؛ وإلا، يتم تحديثه.

لذا، إذا أردنا إزالة "البانكيك" من المفضلة، يمكننا القيام بما يلي:

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await isar.recipes.put(pancakes);
});
```

### حذف كائن (Delete object)

هل تريد التخلص من كائن في Isar؟ استخدم `collection.delete(id)`. تعيد طريقة الحذف ما إذا كان قد تم العثور على كائن بالمعرف المحدد وحذفه. إذا كنت تريد حذف الكائن ذو المعرف `123` على سبيل المثال، يمكنك القيام بـ:

```dart
await isar.writeTxn(() async {
  final success = await isar.recipes.delete(123);
  print('Recipe deleted: $success');
});
```

على غرار الحصول والإدراج، هناك أيضاً عملية حذف جماعي تعيد عدد الكائنات المحذوفة:

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

إذا كنت لا تعرف معرفات الكائنات التي تريد حذفها، يمكنك استخدام استعلام:

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
