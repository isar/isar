---
title: Migración de datos
---

# Migración de datos

Isar migra automáticamente tus esquemas de la base de datos si agregas o quitas colecciones, campos o índices. Probablemente quieras migrar también tus datos. Isar no ofrece una solución incluída porque impondría restricciones arbitrarias a la migración. Es sencillo implementar una lógica de migración que se adecúe a tus necesidades.

En este ejemplo usaremos una versión simple de la base de datos completa. Utilizamos `SharedPreferences` para almacenar la versión actual y compararla con la versión a la cual queremos migrar. Si la versión no coincide, migramos los datos y actualizamos la versión.

:::tip
También podrías darle a cada colección su propia versión y migrarlas individualmente.
:::

Imagina que tenemos una colección de usuarios con un campo de cumpleaños. En la versión 2 de nuetra app, necesitamos agregar un campo adicional para el año de nacimiento para consultar usuarios por edad.

Version 1:

```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;
}
```

Version 2:

```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

El problema es que el modelo existente para los usuarios tendrá un campo vacío `birthYear` porque no existía en la versión 1. Necesitamos migrar los datos para establecer el campo `birthYear`.

```dart
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [UserSchema],
    directory: dir.path,
  );

  await performMigrationIfNeeded(isar);

  runApp(MyApp(isar: isar));
}

Future<void> performMigrationIfNeeded(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  final currentVersion = prefs.getInt('version') ?? 2;
  switch(currentVersion) {
    case 1:
      await migrateV1ToV2(isar);
      break;
    case 2:
      // If the version is not set (new installation) or already 2, we do not need to migrate
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // Update version
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // We paginate through the users to avoid loading all users into memory at once
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // We don't need to update anything since the birthYear getter is used
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
Si tienes que migrar muchos datos, considera utilizar un isolate en segundo plano para prevenir efectos no deseados en la UI.
:::
