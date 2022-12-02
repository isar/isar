---
title: نگران
---

# نگران

ای زار آپ کو ڈیٹا بیس میں ہونے والی تبدیلیوں کو سبسکرائب کرنے کی اجازت دیتا ہے۔ آپ کسی مخصوص شے، پورے مجموعہ، یا کسی سوال میں تبدیلیوں کے لیے "دیکھ" سکتے ہیں۔

نگہبان آپ کو ڈیٹا بیس میں ہونے والی تبدیلیوں پر موثر انداز میں رد عمل ظاہر کرنے کے قابل بناتے ہیں۔ مثال کے طور پر جب کوئی رابطہ شامل کیا جاتا ہے تو آپ اپنا یوآئی دوبارہ بنا سکتے ہیں، جب کوئی دستاویز اپ ڈیٹ ہو جائے تو نیٹ ورک کی درخواست بھیج سکتے ہیں، وغیرہ۔

لین دین کے کامیابی سے انجام پانے اور ہدف میں تبدیلی کے بعد دیکھنے والے کو مطلع کیا جاتا ہے۔

##آبجیکٹ دیکھنا

اگر آپ چاہتے ہیں کہ کسی مخصوص چیز کے بننے، اپ ڈیٹ یا حذف ہونے پر آپ کو مطلع کیا جائے، تو آپ کو کسی چیز کو دیکھنا چاہیے:

```dart
Stream<User> userChanged = isar.users.watchObject(5);
userChanged.listen((newUser) {
  print('User changed: ${newUser?.name}');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User changed: David

final user2 = User(id: 5)..name = 'Mark';
await isar.users.put(user);
// prints: User changed: Mark

await isar.users.delete(5);
// prints: User changed: null
```

جیسا کہ آپ اوپر کی مثال میں دیکھ سکتے ہیں، آبجیکٹ کو ابھی موجود ہونے کی ضرورت نہیں ہے۔ دیکھنے والے کو اس کے بننے پر مطلع کیا جائے گا۔

There is an additional parameter `fireImmediately`. If you set it to `true`, Isar will immediately add the object's current value to the stream.

### سست دیکھ رہا ہے۔

ہوسکتا ہے کہ آپ کو نئی قیمت وصول کرنے کی ضرورت نہ ہو لیکن صرف تبدیلی کے بارے میں مطلع کیا جائے۔ یہ ای زار کو آبجیکٹ لانے سے بچاتا ہے:

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User 5 changed
```

## کلیکشن دیکھ رہے ہیں۔

کسی ایک شے کو دیکھنے کے بجائے، آپ ایک پورا مجموعہ دیکھ سکتے ہیں اور کسی بھی چیز کو شامل، اپ ڈیٹ یا حذف کیے جانے پر مطلع کر سکتے ہیں:

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// prints: A User changed
```

## سوالات دیکھ رہے ہیں۔

پورے سوالات کو دیکھنا بھی ممکن ہے۔ ای زار صرف آپ کو مطلع کرنے کی پوری کوشش کرتا ہے جب سوال کے نتائج حقیقت میں تبدیل ہوں۔ آپ کو مطلع نہیں کیا جائے گا اگر لنکس استفسار کو تبدیل کرنے کا سبب بنتے ہیں۔ اگر آپ کو لنک کی تبدیلیوں کے بارے میں مطلع کرنے کی ضرورت ہو تو کلیکشن واچر کا استعمال کریں۔

```dart
Query<User> usersWithA = isar.users.filter()
    .nameStartsWith('A')
    .build();

Stream<List<User>> queryChanged = usersWithA.watch(fireImmediately: true);
queryChanged.listen((users) {
  print('Users with A are: $users');
});
// prints: Users with A are: []

await isar.users.put(User()..name = 'Albert');
// prints: Users with A are: [User(name: Albert)]

await isar.users.put(User()..name = 'Monika');
// no print

awaited isar.users.put(User()..name = 'Antonia');
// prints: Users with A are: [User(name: Albert), User(name: Antonia)]
```

:::warning
اگر آپ آفسیٹ اور لمیٹ یا الگ الگ سوالات استعمال کرتے ہیں، تو آئسر آپ کو اس وقت بھی مطلع کرے گا جب اشیاء فلٹر سے مماثل ہوں لیکن استفسار سے باہر، نتائج تبدیل ہوتے ہیں۔
:::

Just like `watchObject()`, you can use `watchLazy()` to get notified when the query results change but not fetch the results.

:::danger
ہر تبدیلی کے لیے استفسارات کو دوبارہ چلانا بہت ناکارہ ہے۔ اس کے بجائے اگر آپ سست کلیکشن واچر کا استعمال کریں تو بہتر ہوگا۔
:::
