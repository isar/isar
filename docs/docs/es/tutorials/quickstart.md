---
title: Inicio rápido
---

# Inicio rápido

Increíble!, estás aquí! Vamos a empezar a usar la base de datos más genial que existe para Flutter...

Vamos a ser cortos en palabras para ir inmediatamente al código en esta guía de inicio rápido.

## 1. Agrega las dependencias

Antes de empezar la parte divertida, necesitamos agregar algunos paquetes al `pubspec.yaml`. Podemos usar pub para hacer el trabajo pesado por nosotros.

```bash
flutter pub add isar isar_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. Anota las clases

Anota tus clases de colecciones con `@collection` y elige un campo `Id`.

```dart
part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  String? name;

  int? age;
}
```

Los Ids identifican inequívocamente los objetos en una colección y te permiten luego buscarlos nuevamente.

## 3. Ejecuta el generador de código

Ejecuta el siguiente comando para iniciar el `build_runner`:

```
dart run build_runner build
```

Si estás usando Flutter, puedes usar el siguiente:

```
flutter pub run build_runner build
```

## 4. Abre una instancia Isar

Abre una nueva instalcia Isar y pásale todos los esquemas de tu colección. Opcionalmente puedes especificar un nombre para la instancia y un directorio.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [UserSchema],
  directory: dir.path,
);
```

## 5. Lee y escribe

Una vez que tu base de datos está abierta, puedes comenzar a usar tus colecciones.

Todas las operaciones CRUD básicas están disponibles a través del `IsarCollection`.

```dart
final newUser = User()..name = 'Jane Doe'..age = 36;

await isar.writeTxn(() async {
  await isar.users.put(newUser); // insert & update
});

final existingUser = await isar.users.get(newUser.id); // get

await isar.writeTxn(() async {
  await isar.users.delete(existingUser.id!); // delete
});
```

## Otros recursos

Gustas de aprender de manera visual? Dale un vistazo a estos videos para empezar con Isar (Advertencia, material en Inglés):

<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/CwC9-a9hJv4" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/videoseries?list=PLKKf8l1ne4_hMBtRykh9GCC4MMyteUTyf" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/pdKb8HLCXOA " title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
