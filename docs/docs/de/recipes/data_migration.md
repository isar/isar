---
title: Migration von Daten
---

# Migration vron Daten

Isar migriert deine Datenbankschemas automatisch, wenn du Collections, Felder oder Indizes hinzufügst oder entfernst. Manchmal möchtest du möglicherweise auch deine Daten migrieren. Isar liefert keine eingebaute Lösung, weil das willkürliche Migrationsbeschränkungen festlegen würde. Es ist leicht eine passende Migrationslogik zu implementieren.

Wir wollen in diesem Beispiel eine einzige Version für die gesamte Datenbank verwenden. Wir benutzen Shared Preferences um die derzeitige Version zu speichern und vergleichen diese mit der Version zu der wir unsere Daten migrieren wollen. Wenn die Versionen nicht übereinstimmen, migrieren wir die Daten und aktualisieren die Version.

:::tip
Du kannst auch jeder Collection seine eigene Version zuweisen und sie individuell migrieren.
:::

Stell dir vor, wie haben eine Benutzer-Collection mit einem Feld Geburtstag. In Version 2 unserer App benötigen wir ein zusätzliches Feld Geburtsjahr um Benutzer anhand des Alters abzufragen.

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

Das Problem ist, dass vorhandene Benutzermodelle ein leeres `birthYear`-Feld haben werden, weil es in Version 1 nicht existiert hat. Wir müssen die Daten migrieren, um das `birthYear`-Feld zu setzen.

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
      // Wenn die Version nicht gesetzt (neue Installation), oder schon 2 ist, müssen wir nicht migrieren
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // Version aktualisieren
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // Wir paginieren durch die Benutzer, um zu vermeiden, dass wir alle Benutzer gleichzeitig in den Speicher laden
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // Wir müssen nichts aktualisieren, weil der birthYear-Getter verwendet wird
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
Wenn du viele Daten migrieren musst, solltest du überlegen einen Hintergrund-Isolate zu verwenden, um eine Belastung des UI-Threads zu verhindern.
:::
