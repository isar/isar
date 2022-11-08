---
title: Watchers
---

# Watchers

Isar te permite suscribirte a los cambios en la base de datos. Puedes "observar" los cambios en un objeto específico, una colección entera, o una consulta.

Los watchers te permiten reaccionar a los cambios en la base de datos de manera eficiente. Puedes por ejemplo refrescar la interfaz de usuario cuando se agrega un contacto, enviar una consulta de red cuando un documento se actualiza, etc.

Un watcher es notificado después que una transacción finaliza exitosamente y el objeto realmente cambia.

## Observando objetos

Si quieres ser notificado cuando un objeto específico se crea, actualiza o elimina, debes "observar" un objeto:

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

Como puedes ver en el ejemplo anterior, el objeto no necesita existir aún. El watcher será notificado cuando se crea.

Existe un parámetro adicional `fireImmediately`. Si lo seteas en `true`, Isar agregará inmediatamente el valor actual del objeto al stream.

### Lazy watching

Tal vez no necesitas recibir el nuevo valor pero sólo ser notificado sobre el cambio. Esto evita que Isar tenga get obtener el objeto:

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// prints: User 5 changed
```

## Observando collections

En lugar de observar un solo objeto, puedes hacerlo con una colección completa y ser notificado cuando cualquier objeto se agrega, actualiza o elimina:

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// prints: A User changed
```

## Observando consultas

Incluso es posible observar consultas. Isar lo hace mejor incluso al notificarte sólo si el resultado de la consulta en realidad cambia. No serás notificado de los cambios provocados por un enlace. Observa una colección si quieres ser notificado acerca de los cambios en enlaces.

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
Si en tus consultas usas offset y límite o distinct, Isar incluso te notificará cuando los objetos coinciden con el filtro pero caen fuera de la consulta.
:::

Al igual que `watchObject()`, puedes usar `watchLazy()` para ser notificado cuando el resultado de la consulta cambia pero sin obtenerlos.

:::danger
Ejecutar consultas repetidamente para cada cambio es muy ineficiente. Sería mejor si usaras un watcher perezoso sobre la colección.
:::
