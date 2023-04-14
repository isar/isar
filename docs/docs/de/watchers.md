---
title: Watcher
---

# Watcher

Isar ermöglicht es dir zu Änderungen in der Datenbank zu abbonieren. Du kannst Änderungen in einem Objekt, einer ganzen Collection oder einer Abfrage "beobachten".

Watcher erlauben es dir auf Änderungen in der Datenbank effizient zu reagieren. Du kannst z.B. dein UI neuladen, wenn ein Kontakt hinzugefügt wurde, eine Netzwerkabfrage machen, wenn ein Dokument aktualisiert wurde, etc.

Ein Watcher wird benachrichtigt, wenn eine Transaktion efolgreich stattfindet, und das Ziel sich wirklich ändert.

## Objekte beobachten

Wenn du benachrichtigt werden möchtest, wenn ein spezifisches Objekt erstellt, aktualisiert oder gelöscht wird, solltest du ein Objekt beobachten:

```dart
Stream<User> userChanged = isar.users.watchObject(5);
userChanged.listen((newUser) {
  print('User changed: ${newUser?.name}');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// Ausgabe: User changed: David

final user2 = User(id: 5)..name = 'Mark';
await isar.users.put(user);
// Ausgabe: User changed: Mark

await isar.users.delete(5);
// Ausgabe: User changed: null
```

Wie du im eben gezeigten Beispiel sehen kannst, muss das Objekt noch nicht existieren. Der Watcher wird benachrichtigt, wenn es erzeugt wird.

Es gibt den zusätzlichen Parameter `fireImmediately`. Wenn du ihn auf `true` gesetzt hast, wird Isar sofort die Werte des aktuellen Objekts in den Stream geben.

### Lazy Beobachtung

Vielleicht möchtest du gar nicht den neuen Wert erhalten, sondern nur über die Änderungen informiert werden. Das erspart es Isar die Objekte abrufen zu müssen:

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// Ausgabe: User 5 changed
```

## Collections beobachten

Statt ein einzelnes Objekt zu beobachten kannst du auch eine ganze Collection beobachten und benachrichtigt werden, wenn irgendein Objekt hinzugefügt, geändert oder gelöscht wird:

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// Ausgabe: A User changed
```

## Abfragen beobachten

Es ist sogar möglich ganze Abfragen zu beobachten. Isar versucht sein Bestes dich nur zu benachrichtigen, wenn das Abfrageergebnis sich wirklich ändert. Du wirst nicht informiert, wenn Links darin resultieren, dass deine Abfrageergebnisse sich ändern. Benutze einen Collection-Watcher, wenn du über Linkänderungen benachrichtigt werden willst.

```dart
Query<User> usersWithA = isar.users.filter()
    .nameStartsWith('A')
    .build();

Stream<List<User>> queryChanged = usersWithA.watch(fireImmediately: true);
queryChanged.listen((users) {
  print('Users with A are: $users');
});
// Ausgabe: Users with A are: []

await isar.users.put(User()..name = 'Albert');
// Ausgabe: Users with A are: [User(name: Albert)]

await isar.users.put(User()..name = 'Monika');
// keine Ausgabe

awaited isar.users.put(User()..name = 'Antonia');
// Ausgabe: Users with A are: [User(name: Albert), User(name: Antonia)]
```

:::warning
Wenn du einen Offset mit Limitierung oder Eindeutigkeitsabfragen benutzt, wird Isar dich auch informieren, wenn Ergebnisse innerhalb der Abfrage, aber außerhalb der Abfragegrenzen stattfinden.
:::

Genau wie bei `watchObject()` kannst du `watchLazy()` verwenden, um über Änderungen in den Abfrageergebnissen benachrichtigt zu werden, ohne die Ergebnisse zu erhalten.

:::danger
Abfragen für jede Änderung erneut ablaufen zu lassen ist sehr ineffizient. Es wäre besser, wenn du stattdessen einen lazy Collection-Watcher verwenden würdest.
:::
