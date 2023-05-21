---
title: اسکیما
---

# اسکیما

جب آپ اپنی ایپ کا ڈیٹا ذخیرہ کرنے کے لیے ایزار کا استعمال کرتے ہیں، تو آپ مجموعوں کے ساتھ کام کر رہے ہوتے ہیں۔ ایک مجموعہ متعلقہ ایزار ڈیٹا بیس میں ڈیٹا بیس کی میز کی طرح ہے اور اس میں صرف ایک قسم کی ڈارٹ آبجیکٹ ہو سکتی ہے۔ ہر مجموعہ آبجیکٹ متعلقہ مجموعہ میں ڈیٹا کی ایک قطار کی نمائندگی کرتا ہے۔

مجموعہ کی تعریف کو "اسکیما" کہا جاتا ہے۔ ایزار جنریٹر آپ کے لیے بھاری بھرکم سامان اٹھائے گا اور زیادہ تر کوڈ تیار کرے گا جس کی آپ کو کلیکشن استعمال کرنے کی ضرورت ہے۔

## مجموعہ کی اناٹومی۔

آپ `کلیکشن` یا `کلیکشن` کے ساتھ کلاس کی تشریح کر کے ہر اسر مجموعہ کی وضاحت کرتے ہیں۔ ایزار مجموعہ میں ڈیٹا بیس میں متعلقہ جدول میں ہر کالم کے لیے فیلڈز شامل ہوتے ہیں، جس میں بنیادی کلید شامل ہوتی ہے۔

درج ذیل کوڈ ایک سادہ مجموعہ کی ایک مثال ہے جو ایزار، پہلا نام اور آخری نام کے کالموں کے ساتھ ایک `صارف` ٹیبل کی وضاحت کرتا ہے:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
کسی فیلڈ کو برقرار رکھنے کے لیے، اسر کو اس تک رسائی حاصل ہونی چاہیے۔ آپ اس بات کو یقینی بنا سکتے ہیں کہ ایسر کو کسی فیلڈ تک رسائی حاصل ہے اسے عوامی بنا کر یا گیٹر اور سیٹٹر کے طریقے فراہم کر کے۔
:::

مجموعہ کو حسب ضرورت بنانے کے لیے چند اختیاری پیرامیٹرز ہیں:

| Config        | Description                                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------------------------------- |
| `inheritance` | کنٹرول کریں کہ آیا پیرنٹ کلاسز اور مکسین کے فیلڈز کو اسر میں محفوظ کیا جائے گا۔ بطور ڈیفالٹ فعال۔                  |
| `accessor`    | آپ کو ڈیفالٹ کلیکشن ایکسیسر کا نام تبدیل کرنے کی اجازت دیتا ہے (مثال کے طور پر `رابطہ` مجموعہ کے لئے `ایزار.رابطہ`)۔ |
| `ignore`      | کچھ خصوصیات کو نظر انداز کرنے کی اجازت دیتا ہے۔ یہ سپر کلاسز کے لیے بھی قابل احترام ہیں۔                                  |

### ای زار آئی ڈی

ہر کلیکشن کلاس کو کسی شے کی منفرد شناخت کرنے والی قسم `آئی ڈی` کے ساتھ ایک آئی ڈی پراپرٹی کی وضاحت کرنی ہوتی ہے۔ `آئی ڈی` `انٹ` کا صرف ایک عرف ہے جو ای زار جنریٹر کو آئی ڈی کی خاصیت کو پہچاننے کی اجازت دیتا ہے۔

ای زار خود بخود آئی ڈی فیلڈز کو انڈیکس کرتا ہے، جو آپ کو ان کی شناخت کی بنیاد پر اشیاء کو مؤثر طریقے سے حاصل کرنے اور ان میں ترمیم کرنے کی اجازت دیتا ہے۔

آپ یا تو خود ids سیٹ کر سکتے ہیں یا ای زار سے ایک آٹو انکریمنٹ آئی ڈی تفویض کرنے کو کہہ سکتے ہیں۔ اگر `آئی ڈی` فیلڈ `نل` ہے اور `حتمی` نہیں ہے تو ای زار ایک خودکار اضافہ آئی ڈی تفویض کرے گا۔ اگر آپ غیر منسوخ آٹو انکریمنٹ آئی ڈی چاہتے ہیں تو آپ `نل` کی بجائے `ای زار.آٹوانکریمنٹ` استعمال کر سکتے ہیں۔

:::tip
جب کسی چیز کو حذف کیا جاتا ہے تو آٹو انکریمنٹ آئی ڈیز دوبارہ استعمال نہیں کی جاتی ہیں۔ آٹو انکریمنٹ آئی ڈی کو دوبارہ ترتیب دینے کا واحد طریقہ ڈیٹا بیس کو صاف کرنا ہے۔
:::

### مجموعوں اور فیلڈز کا نام تبدیل کرنا

پہلے سے طے شدہ طور پر، ای زار کلاس کا نام مجموعہ کے نام کے طور پر استعمال کرتا ہے۔ اسی طرح، ای زار ڈیٹا بیس میں فیلڈ کے ناموں کو کالم کے نام کے طور پر استعمال کرتا ہے۔ اگر آپ چاہتے ہیں کہ کسی مجموعہ یا فیلڈ کا نام مختلف ہو، تو `@نام` تشریح شامل کریں۔ درج ذیل مثال جمع کرنے اور فیلڈز کے لیے حسب ضرورت ناموں کو ظاہر کرتی ہے:

```dart
@collection
@Name("User")
class MyUserClass1 {

  @Name("id")
  Id myObjectId;

  @Name("firstName")
  String theFirstName;

  @Name("lastName")
  String familyNameOrWhatever;
}
```

خاص طور پر اگر آپ ڈارٹ فیلڈز یا کلاسز کا نام تبدیل کرنا چاہتے ہیں جو پہلے سے ڈیٹا بیس میں محفوظ ہیں، آپ کو `@نام` تشریح استعمال کرنے پر غور کرنا چاہیے۔ بصورت دیگر، ڈیٹا بیس فیلڈ یا مجموعہ کو حذف کر کے دوبارہ تخلیق کر دے گا۔

### Ignoring fields

Isar persists all public fields of a collection class. By annotating a property or getter with `@ignore`, you can exclude it from persistence, as shown in the following code snippet:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;

  @ignore
  String? password;
}
```

In cases where a collection inherits fields from a parent collection, it's usually easier to use the `ignore` property of the `@Collection` annotation:

```dart
@collection
class User {
  Image? profilePicture;
}

@Collection(ignore: {'profilePicture'})
class Member extends User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

اگر کسی مجموعے میں ایک ایسی فیلڈ ہے جس کی قسم ایسر کے ذریعہ تعاون یافتہ نہیں ہے، تو آپ کو فیلڈ کو نظر انداز کرنا ہوگا۔

:::warning
اس بات کو ذہن میں رکھیں کہ ایسیر اشیاء میں معلومات کو ذخیرہ کرنا اچھا عمل نہیں ہے جو برقرار نہیں ہیں۔
:::

## تائید شدہ اقسام

ای زار درج ذیل ڈیٹا کی اقسام کی حمایت کرتا ہے:

- `bool`
- `int`
- `double`
- `DateTime`
- `String`
- `List<bool>`
- `List<int>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

Additionally, embedded objects and enums are supported. We'll cover those below.

##بائٹ، مختصر، فلوٹ

بہت سے استعمال کے معاملات کے لیے، آپ کو 64 بٹ انٹیجر یا ڈبل ​​کی پوری رینج کی ضرورت نہیں ہے۔ ای ار اضافی اقسام کی حمایت کرتا ہے جو آپ کو چھوٹے نمبروں کو ذخیرہ کرتے وقت جگہ اور میموری کو بچانے کی اجازت دیتا ہے۔

| Type       | Size in bytes | Range                                                   |
| ---------- |-------------- | ------------------------------------------------------- |
| **byte**   | 1             | 0 to 255                                                |
| **short**  | 4             | -2,147,483,647 to 2,147,483,647                         |
| **int**    | 8             | -9,223,372,036,854,775,807 to 9,223,372,036,854,775,807 |
| **float**  | 4             | -3.4e38 to 3.4e38                                       |
| **double** | 8             | -1.7e308 to 1.7e308                                     |

The additional number types are just aliases for the native Dart types, so using `short`, for example, works the same as using `int`.

Here is an example collection containing all of the above types:

```dart
@collection
class TestCollection {
  Id? id;

  late byte byteValue;

  short? shortValue;

  int? intValue;

  float? floatValue;

  double? doubleValue;
}
```

All number types can also be used in lists. For storing bytes, you should use `List<byte>`.

## کالعدم اقسام

Understanding how nullability works in Isar is essential: Number types do **NOT** have a dedicated `null` representation. Instead, a specific value is used:

| Type       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` | 
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN` |
| **double** |  `double.NaN` |

`bool`, `String`, and `List` have a separate `null` representation.

یہ رویہ کارکردگی کو بہتر بنانے کے قابل بناتا ہے، اور یہ آپ کو نل اقدار کو ہینڈل کرنے کے لیے منتقلی یا خصوصی کوڈ کی ضرورت کے بغیر اپنے فیلڈز کی منسوخی کو آزادانہ طور پر تبدیل کرنے کی اجازت دیتا ہے۔

:::warning
The `byte` type does not support null values.
:::

## تاریخ وقت

Isar does not store timezone information of your dates. Instead, it converts `DateTime`s to UTC before storing them. Isar returns all dates in local time.

`DateTime`s are stored with microsecond precision. In browsers, only millisecond precision is supported because of JavaScript limitations.

## اینوم

ایزار دیگر ایزار اقسام کی طرح اینومز کو ذخیرہ کرنے اور استعمال کرنے کی اجازت دیتا ہے۔ تاہم، آپ کو انتخاب کرنا ہوگا کہ اسر ڈسک پر موجود اینوم کی نمائندگی کیسے کرے۔ ایزار چار مختلف حکمت عملیوں کی حمایت کرتا ہے:

| EnumType    | Description 
| ----------- | -----------
| `ordinal`   | The index of the enum is stored as `byte`. This is very efficient but does not allow nullable enums |
| `ordinal32` | The index of the enum is stored as `short` (4-byte integer).                                        |
| `name`      | The enum name is stored as `String`.                                                                |
| `value`     | A custom property is used to retrieve the enum value.                                               |

:::warning
`ordinal` and `ordinal32` depend on the order of the enum values. If you change the order, existing databases will return incorrect values.
:::

آئیے ہر حکمت عملی کے لیے ایک مثال دیکھیں۔

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // same as EnumType.ordinal
  late TestEnum byteIndex; // cannot be nullable

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // cannot be nullable

  @Enumerated(EnumType.ordinal32)
  TestEnum? shortIndex;

  @Enumerated(EnumType.name)
  TestEnum? name;

  @Enumerated(EnumType.value, 'myValue')
  TestEnum? myValue;
}

enum TestEnum {
  first(10),
  second(100),
  third(1000);

  const TestEnum(this.myValue);

  final short myValue;
}
```

یقینا، اینمز کو فہرستوں میں بھی استعمال کیا جا سکتا ہے۔

## ایمبیڈڈ اشیاء

آپ کے کلیکشن ماڈل میں گھریلو اشیاء کا ہونا اکثر مددگار ہوتا ہے۔ اس کی کوئی حد نہیں ہے کہ آپ اشیاء کو کتنی گہرائی میں گھونسلا سکتے ہیں۔ تاہم، ذہن میں رکھیں کہ گہرے اندر کی چیز کو اپ ڈیٹ کرنے کے لیے پورے آبجیکٹ ٹری کو ڈیٹا بیس میں لکھنے کی ضرورت ہوگی۔
  
```dart
@collection
class Email {
  Id? id;

  String? title;

  Recepient? recipient;
}

@embedded
class Recepient {
  String? name;

  String? address;
}
```

ایمبیڈڈ اشیاء کالعدم ہوسکتی ہیں اور دیگر اشیاء کو بڑھا سکتی ہیں۔ صرف ضرورت یہ ہے کہ وہ `@ایمبڈیڈ` کے ساتھ تشریح شدہ ہوں اور بغیر مطلوبہ پیرامیٹرز کے ڈیفالٹ کنسٹرکٹر ہوں۔
