---
title: Osservatori
---

# Osservatori

Isar permette di sottoscrivere le modifiche al database. Puoi "osservare" le modifiche in un oggetto specifico, un'intera raccolta o una query.

Gli osservatori consentono di reagire in modo efficiente alle modifiche nel database. Ad esempio, puoi ricostruire la tua interfaccia utente quando viene aggiunto un contatto, inviare una richiesta di rete quando un documento viene aggiornato, ecc.

Un osservatore riceve una notifica dopo che una transazione è stata eseguita correttamente e la destinazione cambia effettivamente.

## Osservare gli oggetti

Se vuoi essere avvisato quando un oggetto specifico viene creato, aggiornato o eliminato, dovresti osservare un oggetto:

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

Come puoi vedere nell'esempio sopra, l'oggetto non deve ancora esistere. L'osservatore riceverà una notifica quando verrà creato.

C'è un parametro aggiuntivo `fireImmediately`. Se lo imposti su `true`, Isar aggiungerà immediatamente il valore corrente dell'oggetto allo stream.

### Osservazione pigra

Forse non è necessario ricevere il nuovo valore ma solo essere avvisati della modifica. Ciò evita a Isar di dover recuperare l'oggetto:

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User 5 changed
```

## Osservare le raccolte

Invece di guardare un singolo oggetto, puoi guardare un'intera raccolta e ricevere una notifica quando un oggetto viene aggiunto, aggiornato o eliminato:

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// prints: A User changed
```

## Osservare le query

È anche possibile osservare intere query. Isar fa del suo meglio per avvisarti solo quando i risultati della query cambiano effettivamente. Non riceverai una notifica se i collegamenti causano la modifica della query. Utilizza un osservatore di raccolta se hai bisogno di essere informato sulle modifiche ai link.

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
Se utilizzi query offset & limit o distinte, Isar ti avviserà anche quando gli oggetti corrispondono al filtro ma al di fuori della query, i risultati cambiano.
:::

Proprio come `watchObject()`, puoi usare `watchLazy()` per ricevere una notifica quando i risultati della query cambiano ma non recupera i risultati.

:::danger
La ripetizione delle query per ogni modifica è molto inefficiente. Sarebbe meglio se invece utilizzassi un osservatore di raccolta pigro.
:::
