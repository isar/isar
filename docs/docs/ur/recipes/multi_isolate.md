---
title:  کثیر الگ تھلگ استعمال
---

# کثیر الگ تھلگ استعمال

دھاگوں کے بجائے، تمام ڈارٹ کوڈ الگ تھلگ کے اندر چلتا ہے۔ ہر الگ تھلگ کی اپنی یادداشت کا ڈھیر ہوتا ہے، اس بات کو یقینی بناتا ہے کہ الگ تھلگ ریاست میں سے کوئی بھی کسی دوسرے الگ تھلگ سے قابل رسائی نہیں ہے۔

ایزار تک ایک ہی وقت میں متعدد الگ تھلگ مقامات سے رسائی حاصل کی جاسکتی ہے، اور یہاں تک کہ دیکھنے والے بھی الگ تھلگ جگہوں پر کام کرتے ہیں۔ اس ترکیب میں، ہم دیکھیں گے کہ ایک کثیر الگ تھلگ ماحول میں اسار کو کیسے استعمال کیا جائے۔

## ایک سے زیادہ الگ تھلگ کب استعمال کریں۔

اسر لین دین متوازی طور پر انجام پاتے ہیں چاہے وہ ایک ہی الگ تھلگ میں چلیں۔ بعض صورتوں میں، متعدد الگ تھلگ مقامات سے اسار تک رسائی حاصل کرنا اب بھی فائدہ مند ہے۔

Tاس کی وجہ یہ ہے کہ اسر ڈارٹ آبجیکٹ سے اور ڈیٹا کو انکوڈنگ اور ڈی کوڈ کرنے میں کافی وقت صرف کرتا ہے۔ آپ اسے انکوڈنگ اور ڈی کوڈنگ جیسن (صرف زیادہ موثر) کے طور پر سوچ سکتے ہیں۔ یہ آپریشن آئسولیٹ کے اندر چلتے ہیں جہاں سے ڈیٹا تک رسائی حاصل کی جاتی ہے اور قدرتی طور پر الگ تھلگ میں دوسرے کوڈ کو بلاک کر دیتے ہیں۔ دوسرے الفاظ میں: اسر آپ کے ڈارٹ آئسولیٹ میں کچھ کام انجام دیتا ہے۔

اگر آپ کو صرف چند سو اشیاء کو ایک ساتھ پڑھنے یا لکھنے کی ضرورت ہے، تو اسے یوآئی الگ تھلگ میں کرنا کوئی مسئلہ نہیں ہے۔ لیکن بڑی لین دین کے لیے یا اگر یوآئی تھریڈ پہلے سے مصروف ہے، تو آپ کو الگ الگ الگ استعمال کرنے پر غور کرنا چاہیے۔

## مثال

The first thing we need to do is to open Isar in the new isolate. Since the instance of Isar is already open in the main isolate, `Isar.open()` will return the same instance.

:::warning
Make sure to provide the same schemas as in the main isolate. Otherwise, you will get an error.
:::

`compute()` starts a new isolate in Flutter and runs the given function in it.

```dart
void main() {
  // Open Isar in the UI isolate
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [MessageSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  // listen to changes in the database
  isar.messages.watchLazy(() {
    print('omg the messages changed!');
  });

  // start a new isolate and create 10000 messages
  compute(createDummyMessages, 10000).then(() {
    print('isolate finished');
  });

  // after some time:
  // > omg the messages changed!
  // > isolate finished
}

// function that will be executed in the new isolate
Future createDummyMessages(int count) async {
  // we don't need the path here because the instance is already open
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [PostSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Message $i');
  // we use a synchronous transactions in isolates
  isar.writeTxnSync(() {
    isar.messages.insertAllSync(messages);
  });
}
```

There are a few interesting things to note in the example above:

- `isar.messages.watchLazy()` is called in the UI isolate and is notified of changes from another isolate.
- Instances are referenced by name. The default name is `default`, but in this example, we set it to `myInstance`.
- We used a synchronous transaction to create the mesasges. Blocking our new isolate is no problem, and synchronous transactions are a little faster.
