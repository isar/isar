---
title: المراقبون (Watchers)
---

# المراقبون (Watchers)

يتيح لك Isar الاشتراك في التغييرات التي تحدث في قاعدة البيانات. يمكنك "مراقبة" التغييرات في كائن معين، أو مجموعة كاملة (collection)، أو استعلام (query).

تمكنك المراقبون (Watchers) من التفاعل مع التغييرات في قاعدة البيانات بكفاءة. على سبيل المثال، يمكنك إعادة بناء واجهة المستخدم (UI) الخاصة بك عند إضافة جهة اتصال، أو إرسال طلب شبكة (network request) عند تحديث مستند، وما إلى ذلك.

يتم إخطار المراقب بعد أن يتم الالتزام بالمعاملة (transaction) بنجاح وتتغير القيمة المستهدفة بالفعل.

## مراقبة الكائنات (Watching Objects)

إذا كنت ترغب في تلقي إشعارات عند إنشاء كائن معين، أو تحديثه، أو حذفه، فيجب عليك مراقبة كائن:

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

كما ترى في المثال أعلاه، لا يلزم أن يكون الكائن موجودًا بالفعل. سيتم إخطار المراقب عند إنشائه.

يوجد معامل إضافي `fireImmediately`. إذا قمت بتعيينه إلى `true`، سيضيف Isar على الفور القيمة الحالية للكائن إلى التدفق (stream).

### المراقبة الكسولة (Lazy watching)

ربما لا تحتاج إلى تلقي القيمة الجديدة ولكن فقط يتم إخطارك بالتغيير. هذا يوفر على Isar عناء جلب الكائن:

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User 5 changed
```

## مراقبة المجموعات (Watching Collections)

بدلاً من مراقبة كائن واحد، يمكنك مراقبة مجموعة كاملة (collection) وتلقي إشعارات عند إضافة أي كائن أو تحديثه أو حذفه:

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// prints: A User changed
```

## مراقبة الاستعلامات (Watching Queries)

من الممكن أيضًا مراقبة استعلامات كاملة (queries). يبذل Isar قصارى جهده لإخطارك فقط عندما تتغير نتائج الاستعلام بالفعل. لن يتم إخطارك إذا تسببت الروابط (links) في تغيير الاستعلام. استخدم مراقب مجموعة (collection watcher) إذا كنت بحاجة إلى إشعارات حول تغييرات الروابط.

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

await isar.users.put(User()..name = 'Antonia');
// prints: Users with A are: [User(name: Albert), User(name: Antonia)]
```

:::warning
إذا كنت تستخدم `offset` و `limit` أو استعلامات `distinct`، فسيقوم Isar أيضًا بإخطارك عندما تتطابق الكائنات مع الفلتر ولكن خارج الاستعلام، تتغير النتائج.
:::

تمامًا مثل `watchObject()`، يمكنك استخدام `watchLazy()` لتلقي إشعارات عند تغيير نتائج الاستعلام ولكن دون جلب النتائج.

:::danger
إعادة تشغيل الاستعلامات لكل تغيير غير فعال للغاية. سيكون من الأفضل استخدام مراقب مجموعة كسول (lazy collection watcher) بدلاً من ذلك.
:::
