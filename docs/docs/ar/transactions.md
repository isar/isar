---
title: المعاملات (Transactions)
---

# المعاملات (Transactions)

في Isar، تجمع المعاملات (transactions) عمليات قاعدة بيانات متعددة في وحدة عمل واحدة. تستخدم معظم التفاعلات مع Isar المعاملات ضمنيًا. الوصول للقراءة والكتابة في Isar متوافق مع مبادئ [ACID](http://en.wikipedia.org/wiki/ACID). يتم التراجع عن المعاملات تلقائيًا إذا حدث خطأ.

## المعاملات الصريحة (Explicit transactions)

في المعاملة الصريحة (explicit transaction)، تحصل على لقطة متسقة لقاعدة البيانات. حاول تقليل مدة المعاملات. يُحظر إجراء مكالمات شبكة أو عمليات أخرى طويلة الأمد داخل المعاملة.

تتحمل المعاملات (خاصة معاملات الكتابة) تكلفة، ويجب عليك دائمًا محاولة تجميع العمليات المتتالية في معاملة واحدة.

يمكن أن تكون المعاملات متزامنة (synchronous) أو غير متزامنة (asynchronous). في المعاملات المتزامنة، يمكنك استخدام العمليات المتزامنة فقط. في المعاملات غير المتزامنة، العمليات غير المتزامنة فقط.

|              | قراءة (Read)         | قراءة وكتابة (Read & Write)      |
| ------------ | ------------ | ----------------- |
| متزامنة (Synchronous)  | `.txnSync()` | `.writeTxnSync()` |
| غير متزامنة (Asynchronous) | `.txn()`     | `.writeTxn()`     |

### معاملات القراءة (Read transactions)

معاملات القراءة الصريحة (explicit read transactions) اختيارية، لكنها تسمح لك بإجراء قراءات ذرية (atomic reads) والاعتماد على حالة متسقة لقاعدة البيانات داخل المعاملة. داخليًا، تستخدم Isar دائمًا معاملات قراءة ضمنية (implicit read transactions) لجميع عمليات القراءة.

:::tip
معاملات القراءة غير المتزامنة (Async read transactions) تعمل بالتوازي مع معاملات القراءة والكتابة الأخرى. هذا رائع، أليس كذلك؟
:::

### معاملات الكتابة (Write transactions)

على عكس عمليات القراءة، يجب أن تكون عمليات الكتابة (write operations) في Isar مغلفة في معاملة صريحة (explicit transaction).

عندما تكتمل معاملة الكتابة (write transaction) بنجاح، يتم الالتزام بها تلقائيًا، وتُكتب جميع التغييرات على القرص. إذا حدث خطأ، يتم إجهاض المعاملة، ويتم التراجع عن جميع التغييرات. المعاملات هي 
“كل شيء أو لا شيء” (all or nothing): إما أن تنجح جميع عمليات الكتابة داخل المعاملة، أو لا يتم تطبيق أي منها لضمان اتساق البيانات.

:::warning
عندما تفشل عملية قاعدة بيانات، يتم إجهاض المعاملة ويجب عدم استخدامها بعد ذلك. حتى لو قمت بالتقاط الخطأ في Dart.
:::

```dart
@collection
class Contact {
  late int id;

  String? name;
}

// GOOD
await isar.writeTxn(() async {
  for (var contact in getContacts()) {
    await isar.contacts.put(contact);
  }
});

// BAD: move loop inside transaction
for (var contact in getContacts()) {
  await isar.writeTxn(() async {
    await isar.contacts.put(contact);
  });
}
```
