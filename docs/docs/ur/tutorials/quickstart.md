---
title: فورا شروع کریں
---

  # فورا شروع کریں 

خوشی کی بات ہے،آپ یہاں ہیں! آئیے وہاں موجود بہترین Flutter Database کا استعمال شروع کریں۔
ہم اس فورا شروع کرتے ہیں میں الفاظ میں مختصر اور کوڈ پر تیز ہونے جا رہے ہیں۔

## 1. انحصار شامل کریں۔

 تفریح کا آغاز کرنےسے پہلے `pubspec.yaml` میں  ہمیں چند پیکجز شامل کرنے کی ضرورت ہے۔
ہم اپنے لیے بھاری سامان اٹھانے کے لیے پب کا استعمال کر سکتے ہیں۔

```bash
flutter pub add isar isar_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. کلاسوں کی تشریح کریں۔

اپنی کلیکشن کلاسز کو `@collection` کے ساتھ تشریح کریں اورایک `Id` فیلڈ کا انتخاب کریں۔

```dart
part 'email.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  آپ  id = null سےآٹوانکریمنٹ بھی استعمال کر سکتے ہیں۔//

  String? name;
  int? age;
}
```

آئی ڈیز مجموعہ میں اشیاء کی منفرد شناخت کرتی ہیں اور آپ کو بعد میں انہیں دوبارہ تلاش کرنے کی اجازت دیتی ہیں۔

## 3. کوڈ جنریٹر چلائیں۔

شروع کرنے کے لیے درج ذیل کمانڈ پر عمل کریں `build_runner` :

```
dart run build_runner build
```

اگر آپ Flutter استعمال کر رہے ہیں تو درج ذیل استعمال کریں:

```
flutter pub run build_runner build
```

## 4. ۔ Isar Instance کھولیں۔

   ایک نیا Isar Instance کھولیں اور اپنے تمام کلیکشن اسکیموں کو پاس کریں۔ اختیاری طور پر آپ Instance کا نام اور ڈائریکٹری بتا سکتے ہیں۔

```dart
final isar = await Isar.open([EmailSchema]);
```

## 5. لکھیں اور پڑھیں

ایک بار آپ کا Instance کھلنے کے بعد، آپ مجموعے کا استعمال شروع کر سکتے ہیں۔

  تمام بنیادی CRUD آپریشنز `IsarCollection`  کے ذریعے دستیاب ہیں۔


```dart
final newUser = User()..name = 'Jane Doe'..age = 36;

await isar.writeTxn(() async {
  await isar.users.put(newUser);
  داخل کریں اور تروتازہ کریں۔//
});

final existingUser = await isar.users.get(newUser.id);
 حاصل کریں۔//
await isar.writeTxn(() async {
  await isar.users.delete(existingUser.id!);
  حذف کریں//
});
```

## دیگر وسائل

کیا آپ بصری سیکھنے والے ہیں؟ ای زار کے ساتھ شروع کرنے کے لیے یہ ویڈیوز دیکھیں:
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
