---
title: ウォッチャー
---

# ウォッチャー

Isar では、データベースの変更を監視することができます。特定のオブジェクトやコレクション全体、あるいはクエリの変更を "監視" することができます。

ウォッチャーを使うと、データベースの変更に迅速に対応することができます。例えば、連絡先が追加されたときに UI を再構築したり、ドキュメントが更新されたときにネットワークリクエストを送ったりすることができます。

ウォッチャーは、トランザクションが正常にコミットされ、ターゲットが実際に変更された後に通知されます。

## オブジェクトの監視

特定のオブジェクトが作成、更新、削除されたときに通知を受けたい場合、そのオブジェクトを監視する必要があります：

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

上記の例からわかるように、オブジェクトはまだ存在しなくてもかまいません。オブジェクトが作成されると、ウォッチャーに通知されます。

追加のパラメータとして `fireImmediately` があります。これを `true` に設定すると、Isar はオブジェクトの現在の値を即座に Stream に追加します。

### レイジーウォッチング

新しい値を受け取る必要はなく、変更された事についてのみ通知して欲しい場合があるかもしれません。
その場合、Isarはオブジェクトを取得する手間を省くことができます。

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User 5 changed
```

## コレクションの監視

単一のオブジェクトを監視する代わりに、コレクション全体を監視し、いずれかのオブジェクトが追加、更新、または削除されたときに通知を受けることができます：

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// prints: A User changed
```

## クエリの監視

クエリ全体を監視することも可能です。Isarは、クエリの結果が実際に変更されたときのみ通知するよう最善を尽くします。ただ、リンクが原因でクエリが変更された場合は通知されません。リンクの変更について通知を受ける必要がある場合は、コレクションウォッチャーを使用してください。

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
offset & limit や distinct クエリを使用する場合, オブジェクトがフィルタにマッチしたが、クエリの外でoffset & limitなどから結果が変化した場合にも、Isar は通知します。
:::

`watchObject()` と同様に、`watchLazy()` を使うと、クエリの結果が変わっても、結果を取得せずに通知を受けることができます。

:::danger
変更があるたびにクエリを再実行するのは非効率です。その代わりにLazyコレクションウォッチャーを使うとよいでしょう。
:::
