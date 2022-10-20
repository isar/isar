---
title: Watchers
---

# Watchers

Isar allows you to subscribe to changes in the database. You can "watch" for changes in a specific object, an entire collection, or a query.

Watchers enable you to react to changes in the database efficiently. You can for example rebuild your UI when a contact is added, send a network request when a document is updated, etc.

A watcher is notified after a transaction commits successfully and the target actually changes.

## Watching Objects

If you want to be notified when a specific object is created, updated or deleted, you should watch an object:

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

As you can see in the example above, the object does not need to exist yet. The watcher will be notified when it is created.

There is an additional parameter `fireImmediately`. If you set it to `true`, Isar will immediately add the object's current value to the stream.

### Lazy watching

Maybe you don't need to receive the new value but only be notified about the change. That saves Isar from having to fetch the object:

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User 5 changed
```

## Watching Collections

Instead of watching a single object, you can watch an entire collection and get notified when any object is added, updated, or deleted:

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// prints: A User changed
```

## Watching Queries

It is even possible to watch entire queries. Isar does its best to only notify you when the query results actually change. You will not be notified if links cause the query to change. Use a collection watcher if you need to be notified about link changes.

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
If you use offset & limit or distinct queries, Isar will also notify you when objects match the filter but outside the query, results change.
:::

Just like `watchObject()`, you can use `watchLazy()` to get notified when the query results change but not fetch the results.

:::danger
Rerunning queries for every change is very inefficient. It would be best if you used a lazy collection watcher instead.
:::
