---
title: لنکس
---

# لنکس

روابط آپ کو اشیاء کے درمیان تعلقات کا اظہار کرنے کی اجازت دیتے ہیں، جیسے کہ تبصرہ کا مصنف (صارف)۔ آپ ای زار لنکس کے ساتھ `1:1`، `1:n`، اور `n:n` تعلقات کو ماڈل بنا سکتے ہیں۔ لنکس کا استعمال ایمبیڈڈ اشیاء کے استعمال سے کم ایرگونومک ہے اور جب بھی ممکن ہو آپ کو ایمبیڈڈ اشیاء کا استعمال کرنا چاہیے۔

لنک کو ایک علیحدہ جدول کے طور پر سوچیں جس میں رشتہ موجود ہو۔ یہ ایس کیو ایل ریلیشنز کی طرح ہے لیکن اس میں ایک مختلف فیچر سیٹ اور اےپی آئی ہے۔

## IsarLink

`IsarLink<T>` can contain no or one related object, and it can be used to express a to-one relationship. `IsarLink` has a single property called `value` which holds the linked object.

Links are lazy, so you need to tell the `IsarLink` to load or save the `value` explicitly. You can do this by calling `linkProperty.load()` and `linkProperty.save()`.

:::tip
کسی لنک کے سورس اور ٹارگٹ کلیکشن کی آئی ڈی پراپرٹی غیر حتمی ہونی چاہیے۔
:::

غیر ویب اہداف کے لیے، جب آپ انہیں پہلی بار استعمال کرتے ہیں تو لنکس خود بخود لوڈ ہو جاتے ہیں۔ آئیے ایک مجموعہ میں ایک IsarLink شامل کرکے شروع کریں:

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

  final teacher = IsarLink<Teacher>();
}
```

ہم نے اساتذہ اور طلباء کے درمیان ایک ربط کی وضاحت کی۔ اس مثال میں ہر طالب علم کو بالکل ایک استاد ہو سکتا ہے۔

سب سے پہلے، ہم استاد بناتے ہیں اور اسے ایک طالب علم کو تفویض کرتے ہیں۔ ہمیں استاد کو `.پٹ()` کرنا ہوگا اور لنک کو دستی طور پر محفوظ کرنا ہوگا۔

```dart
final mathTeacher = Teacher()..subject = 'Math';

final linda = Student()
  ..name = 'Linda'
  ..teacher.value = mathTeacher;

await isar.writeTxn(() async {
  await isar.students.put(linda);
  await isar.teachers.put(mathTeacher);
  await linda.teachers.save();
});
```

We can now use the link:

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

Let's try the same thing with synchronous code. We don't need to save the link manually because `.putSync()` automatically saves all links. It even creates the teacher for us.

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

یہ زیادہ معنی خیز ہوگا اگر پچھلی مثال کے طالب علم کے متعدد اساتذہ ہوسکتے ہیں۔ Fortunately, Isar has `IsarLinks<T>`, which can contain multiple related objects and express a to-many relationship.

`IsarLinks<T>` extends `Set<T>` and exposes all the methods that are allowed for sets.

`IsarLinks` behaves much like `IsarLink` and is also lazy. To load all linked object call `linkProperty.load()`. To persist the changes, call `linkProperty.save()`.

Internally both `IsarLink` and `IsarLinks` are represented in the same way. We can upgrade the `IsarLink<Teacher>` from before to an `IsarLinks<Teacher>` to assign multiple teachers to a single student (without losing data).

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teacher = IsarLinks<Teacher>();
}
```

This works because we did not change the name of the link (`teacher`), so Isar remembers it from before.

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

## بیک لنکس

میں نے آپ کو یہ پوچھتے ہوئے سنا ہے، "اگر ہم معکوس تعلقات کا اظہار کرنا چاہتے ہیں تو کیا ہوگا؟"۔ فکر مت کرو؛ اب ہم بیک لنکس متعارف کرائیں گے۔

Backlinks are links in the reverse direction. Each link always has an implicit backlink. You can make it available to your app by annotating an `IsarLink` or `IsarLinks` with `@Backlink()`.

بیک لنکس کو اضافی میموری یا وسائل کی ضرورت نہیں ہوتی ہے۔ آپ ڈیٹا کو کھونے کے بغیر انہیں آزادانہ طور پر شامل، ہٹا سکتے اور ان کا نام تبدیل کر سکتے ہیں۔

ہم یہ جاننا چاہتے ہیں کہ ایک مخصوص استاد کون سے طلباء کے پاس ہے، اس لیے ہم ایک بیک لنک کی وضاحت کرتے ہیں:

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

ہمیں اس لنک کی وضاحت کرنے کی ضرورت ہے جس کی طرف بیک لنک اشارہ کرتا ہے۔ دو اشیاء کے درمیان متعدد مختلف روابط کا ہونا ممکن ہے۔

## لنکس شروع کریں۔

`IsarLink` and `IsarLinks` have a zero-arg constructor, which should be used to assign the link property when the object is created. It is good practice to make link properties `final`.

جب آپ پہلی بار اپنے آبجیکٹ کو `پٹ()` کرتے ہیں، تو لنک سورس اور ٹارگٹ کلیکشن کے ساتھ شروع ہو جاتا ہے، اور آپ `لوڈ()` اور `سیو()` جیسے طریقوں کو کال کر سکتے ہیں۔ ایک لنک اپنی تخلیق کے فوراً بعد تبدیلیوں کو ٹریک کرنا شروع کر دیتا ہے، لہذا آپ لنک شروع ہونے سے پہلے ہی تعلقات کو شامل اور ہٹا سکتے ہیں۔

:::danger
کسی لنک کو کسی دوسری چیز میں منتقل کرنا غیر قانونی ہے۔
:::
