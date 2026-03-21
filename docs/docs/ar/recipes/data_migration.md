---
title: ترحيل البيانات
---

# ترحيل البيانات

يقوم Isar تلقائيًا بترحيل مخططات قاعدة البيانات الخاصة بك إذا قمت بإضافة أو إزالة مجموعات أو حقول أو فهارس. في بعض الأحيان قد ترغب في ترحيل بياناتك أيضًا. لا يقدم Isar حلًا مدمجًا لذلك لأنه قد يفرض قيودًا تعسفية على الترحيل. ولكن من السهل تنفيذ منطق ترحيل يناسب احتياجاتك.

سنستخدم في هذا المثال رقم إصدار واحد لقاعدة البيانات بالكامل. سنستخدم Shared Preferences لتخزين الإصدار الحالي ومقارنته بالإصدار الذي نريد الترحيل إليه. إذا لم يتطابق الإصداران، نقوم بترحيل البيانات وتحديث الإصدار.

:::tip
يمكنك أيضًا إعطاء كل مجموعة رقم إصدار خاص بها وترحيلها بشكل فردي.
:::

لنفترض أن لدينا مجموعة مستخدمين تحتوي على حقل تاريخ الميلاد. في الإصدار الثاني من تطبيقنا، نحتاج إلى حقل إضافي لسنة الميلاد للاستعلام عن المستخدمين بناءً على العمر.

**الإصدار 1:**

```dart
@collection
class User {
  late int id;

  late String name;

  late DateTime birthday;
}
```

الإصدار 2:

```dart
@collection
class User {
  late int id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

المشكلة هي أن نماذج المستخدمين الحالية سيكون لها حقل birthYear فارغًا لأنه لم يكن موجودًا في الإصدار 1. نحتاج إلى ترحيل البيانات لتعيين حقل birthYear.

```dart
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.openAsync(
    schemas: [UserSchema],
    directory: dir.path,
  );

  await performMigrationIfNeeded(isar);

  runApp(MyApp(isar: isar));
}

Future<void> performMigrationIfNeeded(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  final currentVersion = prefs.getInt('version') ?? 2;
  switch(currentVersion) {
    case 1:
      await migrateV1ToV2(isar);
      break;
    case 2:
      // إذا لم يكن الإصدار محددًا (تثبيت جديد) أو كان بالفعل 2، فلا داعي للترحيل
      return;
    default:
      throw Exception('إصدار غير معروف: $currentVersion');
  }

  // تحديث الإصدار
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // نقوم بتصفح المستخدمين بالصفحات لتجنب تحميل جميع المستخدمين في الذاكرة مرة واحدة
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // لا نحتاج إلى تحديث أي شيء لأن دالة getter birthYear تُستخدم مباشرة
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
إذا كنت بحاجة إلى ترحيل كمية كبيرة من البيانات، ففكر في استخدام معزل خلفي (background isolate) لتجنب الضغط على واجهة المستخدم.
:::

```
