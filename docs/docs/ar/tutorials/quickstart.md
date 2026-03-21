---
title: دليل البدء السريع
---

# دليل البدء السريع

يا إلهي، لقد وصلت! دعنا نبدأ في استخدام أروع قاعدة بيانات Flutter موجودة...

سنكون موجزين في الكلمات وسريعين في الكود في هذا الدليل السريع.

## 1. إضافة التبعيات (Dependencies)

قبل أن تبدأ المتعة، نحتاج إلى إضافة بعض الحزم إلى ملف `pubspec.yaml`. يمكننا استخدام `pub` للقيام بالعمل الشاق نيابة عنا.

```bash
flutter pub add isar isar_flutter_libs path_provider
flutter pub add -d isar_generator build_runner
```

## 2. إضافة التعليقات التوضيحية (Annotate) للفئات (Classes)

أضف التعليقات التوضيحية لفئات مجموعتك باستخدام `@collection` واختر حقل `Id`.

```dart
import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // يمكنك أيضًا استخدام id = null لزيادة تلقائية

  String? name;

  int? age;
}
```

تحدد المعرفات (Ids) الكائنات بشكل فريد في المجموعة وتسمح لك بالعثور عليها لاحقًا.

## 3. تشغيل مولد الكود (Code Generator)

نفّذ الأمر التالي لبدء `build_runner`:

```
dart run build_runner build
```

إذا كنت تستخدم Flutter، فاستخدم ما يلي:

```
flutter pub run build_runner build
```

## 4. فتح مثيل Isar (Isar Instance)

افتح مثيل Isar جديدًا ومرر جميع مخططات مجموعاتك (collection schemas). اختياريًا، يمكنك تحديد اسم المثيل والدليل.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.openAsync(
  schemas: [UserSchema],
  directory: dir.path,
);
```

## 5. الكتابة والقراءة (Write and Read)

بمجرد فتح المثيل الخاص بك، يمكنك البدء في استخدام المجموعات.

تتوفر جميع عمليات CRUD الأساسية عبر `IsarCollection`.

```dart
final newUser = User()..name = 'Jane Doe'..age = 36;

await isar.writeTxn(() async {
  await isar.users.put(newUser); // إدراج وتحديث
});

final existingUser = await isar.users.get(newUser.id); // الحصول

await isar.writeTxn(() async {
  await isar.users.delete(existingUser.id!); // حذف
});
```

## موارد أخرى

هل أنت متعلم بصري؟ شاهد هذه الفيديوهات للبدء مع Isar:

<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/CwC9-a9hJv4" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/videoseries?list=PLKKf8l1ne4_hMBtRykh9GCC4MMyteUTyf" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/pdKb8HLCXOA " title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
