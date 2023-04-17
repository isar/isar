---

title: ڈیٹا مائیگریشن
---

# ڈیٹا مائیگریشن

اگر آپ مجموعے، فیلڈز، یا اشاریہ جات کو شامل یا ہٹاتے ہیں تو ایزار خود بخود آپ کے ڈیٹا بیس اسکیموں کو منتقل کر دیتا ہے۔ بعض اوقات آپ اپنے ڈیٹا کو بھی منتقل کرنا چاہتے ہیں۔ ایزار ایک بلٹ ان حل پیش نہیں کرتا ہے کیونکہ یہ من مانی نقل مکانی پر پابندیاں عائد کرے گا۔ ہجرت کی منطق کو لاگو کرنا آسان ہے جو آپ کی ضروریات کے مطابق ہو۔

ہم اس مثال میں پورے ڈیٹا بیس کے لیے ایک ہی ورژن استعمال کرنا چاہتے ہیں۔ ہم موجودہ ورژن کو ذخیرہ کرنے کے لیے مشترکہ ترجیحات کا استعمال کرتے ہیں اور اس کا موازنہ اس ورژن سے کرتے ہیں جس میں ہم منتقل ہونا چاہتے ہیں۔ اگر ورژن مماثل نہیں ہیں، تو ہم ڈیٹا کو منتقل کرتے ہیں اور ورژن کو اپ ڈیٹ کرتے ہیں۔


::: warning
آپ ہر مجموعہ کو اس کا اپنا ورژن بھی دے سکتے ہیں اور انہیں انفرادی طور پر منتقل کر سکتے ہیں۔
:::

تصور کریں کہ ہمارے پاس سالگرہ والے فیلڈ کے ساتھ صارف کا مجموعہ ہے۔ ہماری ایپ کے ورژن 2 میں، ہمیں عمر کی بنیاد پر صارفین سے استفسار کرنے کے لیے ایک اضافی پیدائشی سال کی فیلڈ کی ضرورت ہے۔

Version 1:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;
}
```

Version 2:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

مسئلہ یہ ہے کہ موجودہ صارف کے ماڈلز میں خالی `پیدائشی سال` فیلڈ ہوگی کیونکہ یہ ورژن 1 میں موجود نہیں تھا۔ ہمیں `پیدائشی سال` فیلڈ سیٹ کرنے کے لئے ڈیٹا کو منتقل کرنے کی ضرورت ہے۔

```dart
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [UserSchema],
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
      // If the version is not set (new installation) or already 2, we do not need to migrate
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // Update version
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // We paginate through the users to avoid loading all users into memory at once
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // We don't need to update anything since the birthYear getter is used
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
اگر آپ کو بہت سارے ڈیٹا کو منتقل کرنا ہے تو، یوآئی تھریڈ پر دباؤ کو روکنے کے لیے بیک گراؤنڈ آئسولیٹ استعمال کرنے پر غور کریں۔
:::
