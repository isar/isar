---
title: Observateurs
---

# Observateurs

Isar nous permet de nous abonner aux changements dans la base de données. Nous pouvons "observer" les modifications apportées à un objet spécifique, à une collection entière ou à une requête.

Les observateurs (`Watchers`) nous permettent de réagir efficacement aux changements dans la base de données. Nous pouvons par exemple reconstruire une interface utilisateur lorsqu'un contact est ajouté, envoyer une requête réseau lorsqu'un document est mis à jour, etc.

Un observateur est notifié lorsqu'une transaction est validée avec succès et que la cible est réellement modifiée.

## Observation d'objets

Si nous voulons être notifié lorsqu'un objet spécifique est créé, mis à jour ou supprimé, nous devons observer un objet:

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

Comme nous pouvons le voir dans l'exemple ci-dessus, l'objet ne doit pas encore exister. L'observateur sera notifié lorsqu'il sera créé.

Il existe un paramètre supplémentaire, `fireImmediately`. Si nous le mettons à `true`, Isar ajoutera immédiatement la valeur courante de l'objet au flux.

### Observation paresseuse

Peut-être n'avez-vous pas besoin de recevoir la nouvelle valeur, mais seulement d'être notifié du changement? Cela évite à Isar d'avoir à aller chercher l'objet:

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User 5 changed
```

## Observation de collections

Au lieu d'observer un seul objet, nous pouvons observer une collection entière et être notifié lorsqu'un objet est ajouté, mis à jour ou supprimé:

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// prints: A User changed
```

## Observation de requêtes

Il est même possible d'observer des requêtes entières. Isar fait de son possible pour nous notifier uniquement lorsque les résultats de la requête changent réellement. Nous ne serons pas notifiés si des liens entraînent une modification de la requête. Utilisez un observateur de collection si vous avez besoin d'être informé des changements de liens.

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
Si vous utilisez des requêtes `offset`, `limit` ou `distinct`, Isar vous notifiera même si les changements y sont en dehors.
:::

Tout comme `watchObject()`, nous pouvons utiliser `watchLazy()` pour être notifié lorsque les résultats de la requête changent, mais ne pas aller les chercher.

:::danger
Relancer les requêtes à chaque modification est très inefficace. Il serait préférable d'utiliser un observateur de collection paresseux (`lazy`) à la place.
:::
