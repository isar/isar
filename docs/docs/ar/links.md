---
title: الروابط (Links)
---

# الروابط (Links)

تسمح لك الروابط بالتعبير عن العلاقات بين الكائنات، مثل مؤلف التعليق (مستخدم). يمكنك تمثيل علاقات `1:1` و `1:n` و `n:n` باستخدام روابط Isar. استخدام الروابط أقل سهولة من استخدام الكائنات المضمنة (embedded objects)، ويجب عليك استخدام الكائنات المضمنة كلما أمكن ذلك.

فكر في الرابط كجدول منفصل يحتوي على العلاقة. إنه مشابه لعلاقات SQL ولكنه يمتلك مجموعة ميزات وواجهة برمجة تطبيقات (API) مختلفة.

## IsarLink

يمكن لـ `IsarLink<T>` أن يحتوي على كائن واحد مرتبط أو لا شيء، ويمكن استخدامه للتعبير عن علاقة "واحد إلى واحد" (to-one relationship). يمتلك `IsarLink` خاصية واحدة تسمى `value` والتي تحمل الكائن المرتبط.

الروابط "كسولة" (lazy)، لذا تحتاج إلى إخبار `IsarLink` بتحميل (load) أو حفظ (save) القيمة `value` بشكل صريح. يمكنك القيام بذلك عن طريق استدعاء `linkProperty.load()` و `linkProperty.save()`.

:::tip
يجب أن تكون خاصية المعرف (id) لمجموعات المصدر والهدف للرابط غير نهائية (non-final).
:::

بالنسبة للأهداف غير الويب، يتم تحميل الروابط تلقائياً عند استخدامها لأول مرة. لنبدأ بإضافة `IsarLink` إلى مجموعة:

```dart
@collection
class Teacher {
  late int id;

  late String subject;
}

@collection
class Student {
  late int id;

  late String name;

  final teacher = IsarLink<Teacher>();
}
```

لقد حددنا رابطاً بين المعلمين والطلاب. يمكن لكل طالب أن يكون لديه معلم واحد بالضبط في هذا المثال.

أولاً، نقوم بإنشاء المعلم وتعيينه لطالب. يتعين علينا استخدام `.put()` للمعلم وحفظ الرابط يدوياً.

```dart
final mathTeacher = Teacher()..subject = 'Math';

final linda = Student()
  ..name = 'Linda'
  ..teacher.value = mathTeacher;

await isar.writeTxn(() async {
  await isar.students.put(linda);
  await isar.teachers.put(mathTeacher);
  await linda.teacher.save();
});
```

يمكننا الآن استخدام الرابط:

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

دعنا نجرب نفس الشيء مع كود متزامن (synchronous). لا نحتاج إلى حفظ الرابط يدوياً لأن `.putSync()` يحفظ جميع الروابط تلقائياً. بل إنه ينشئ المعلم لنا أيضاً.

```dart
final englishTeacher = Teacher()..subject = 'English';

final david = Student()
  ..name = 'David'
  ..teacher.value = englishTeacher;

isar.writeTxnSync(() {
  isar.students.putSync(david);
});
```

## IsarLinks

سيكون من المنطقي أكثر إذا كان بإمكان الطالب في المثال السابق أن يكون لديه عدة معلمين. لحسن الحظ، يمتلك Isar نوع `IsarLinks<T>`، والذي يمكن أن يحتوي على كائنات مرتبطة متعددة ويعبر عن علاقة "واحد إلى متعدد" (to-many relationship).

يرث `IsarLinks<T>` من `Set<T>` ويكشف عن جميع الطرق المسموح بها للمجموعات (sets).

يتصرف `IsarLinks` تماماً مثل `IsarLink` وهو أيضاً "كسول". لتحميل جميع الكائنات المرتبطة، استدعِ `linkProperty.load()`. ولحفظ التغييرات، استدعِ `linkProperty.save()`.

داخلياً، يتم تمثيل كل من `IsarLink` و `IsarLinks` بنفس الطريقة. يمكننا ترقية `IsarLink<Teacher>` من قبل إلى `IsarLinks<Teacher>` لتعيين معلمين متعددين لطالب واحد (دون فقدان البيانات).

```dart
@collection
class Student {
  late int id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

هذا يعمل لأننا لم نغير اسم الرابط (`teacher`) من قبل، لذا يتذكره Isar.

```dart
final biologyTeacher = Teacher()..subject = 'Biology';

final linda = isar.students.where()
  .filter()
  .nameEqualTo('Linda')
  .findFirst();

print(linda.teachers); // {Teacher('Math')}

linda.teachers.add(biologyTeacher);

await isar.writeTxn(() async {
  await linda.teachers.save();
});

print(linda.teachers); // {Teacher('Math'), Teacher('Biology')}
```

## الروابط العكسية (Backlinks)

أسمعك تسأل، "ماذا لو أردنا التعبير عن علاقات عكسية؟". لا تقلق؛ سنقدم الآن الروابط العكسية.

الروابط العكسية هي روابط في الاتجاه المعاكس. كل رابط له دائماً رابط عكسي ضمني. يمكنك جعله متاحاً لتطبيقك عن طريق إضافة التعليق التوضيحي `@Backlink()` لـ `IsarLink` أو `IsarLinks`.

لا تتطلب الروابط العكسية ذاكرة أو موارد إضافية؛ يمكنك إضافتها وإزالتها وإعادة تسميتها بحرية دون فقدان البيانات.

نريد معرفة الطلاب الذين لديهم معلم معين، لذا نحدد رابطاً عكسياً:

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

نحتاج إلى تحديد الرابط الذي يشير إليه الرابط العكسي. من الممكن وجود روابط مختلفة متعددة بين كائنين.

## تهيئة الروابط (Initialize links)

يمتلك كل من `IsarLink` و `IsarLinks` منشئاً (constructor) بدون وسائط، والذي يجب استخدامه لتعيين خاصية الرابط عند إنشاء الكائن. من الممارسات الجيدة جعل خصائص الروابط نهائية (`final`).

عندما تقوم بـ `put()` لكائنك لأول مرة، يتم تهيئة الرابط بمجموعة المصدر والهدف، ويمكنك استدعاء طرق مثل `load()` و `save()`. يبدأ الرابط في تتبع التغييرات فور إنشائه، لذا يمكنك إضافة وإزالة العلاقات حتى قبل تهيئة الرابط.

:::danger
من غير القانوني نقل رابط إلى كائن آخر.
:::
