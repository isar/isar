---
title: Schnellstart
---

# Schnellstart

Holla, die Waldfee! Du bist bestimmt hier um mit der coolsten Flutter-Datenbank zu starten...

Dieser Schnellstart wird wenig um den heißen Brei herumreden und direkt mit dem Coden beginnen.

## 1. Abhängigkeiten hinzufügen

Bevor es losgeht, müssen wir ein paar Pakete zur `pubspec.yaml` hinzufügen. Damit es schneller geht lassen wir pub das für uns erledigen.

```bash
dart pub add isar:^0.0.0-placeholder isar_flutter_libs:^0.0.0-placeholder --hosted-url=https://pub.isar-community.dev
```

## 2. Klassen annotieren

Annotiere deine Collection-Klassen mit `@collection` und wähle ein `Id`-Feld.

```dart
import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  late int id;

  String? name;

  int? age;
}
```

IDs identifizieren Objekte in einer Collection eindeutig und erlauben es dir, sie später wiederzufinden.

## 3. Code-Generator ausführen

Führe den folgenden Befehl aus, um den `build_runner` zu starten:

```
dart run build_runner build
```

## 4. Isar-Instanz öffnen

Öffne eine neue Isar-Instanz und übergebe alle Collection-Schemata. Optional kannst du einen Instanznamen und ein Verzeichnis angeben.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.openAsync(
  schemas: [UserSchema],
  directory: dir.path,
);
```

## 5. Schreiben und lesen

Wenn deine Instanz geöffnet ist, hast du Zugriff auf die Collections.

Alle grundlegenden CRUD-Operationen sind über die `IsarCollection` verfügbar .

```dart
final newUser = User()
  ..id = isar!.users.autoIncrement()
  ..name = 'Jane Doe'
  ..age = 36;

await isar!.writeAsync((isar) {
  return isar.users.put(newUser); // Einfügen & akualisieren
});

final existingUser = isar!.users.get(newUser.id); // Erhalten

if (existingUser != null) {
  await isar!.writeAsync((isar) {
    return isar.users.delete(existingUser.id); // Löschen
  });
}
```

## Weitere Ressourcen

Du lernst am besten visuell? Schau dir diese Videos an, um mit Isar zu starten:

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
