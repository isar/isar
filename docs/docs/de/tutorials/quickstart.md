---
title: Schnellstart
---

# Schnellstart

Holla, die Waldfee! Du bist bestimmt hier um mit der coolsten Flutter-Datenbank zu starten...

Dieser Schnellstart wird wenig um den heißen Brei herumreden und direkt mit dem coden beginnen.

## 1. Abhängigkeiten hinzufügen

Bevor es losgeht, müssen wir ein paar Pakete zur `pubspec.yaml` hinzufügen. Damit es schneller geht lassen wir pub das für uns erledigen.

```bash
flutter pub add isar isar_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. Klassen annotieren

Annotiere deine Collection-Klassen mit `@collection` und wähle ein `Id`-Feld.

```dart
part 'email.g.dart'

@collection
class User {
  Id id = Isar.autoIncrement; // Für auto-increment kannst du auch id = null zuweisen 

  String? name;

  int? age;
}
```

Ids identifizieren Objekte in einer Collection eindeutig und erlauben es dir, sie später wiederzufinden.

## 3. Code-Generator ausführen

Führe den folgenden Befehl aus, um den `build_runner` zu starten:

```
dart run build_runner build
```

Wenn du Flutter verwendest:

```
flutter pub run build_runner build
```

## 4. Isar-Instanz öffnen

Öffne eine neue Isar-Instanz und übergebe alle Collection-Schemata. Optional kannst du einen Instanznamen und ein Verzeichnis angeben.

```dart
final isar = await Isar.open([EmailSchema]);
```

## 5. Schreiben und lesen

Wenn deine Instanz geöffnet ist, hast du Zugriff auf die Collections.

Alle grundlegenden CRUD-Operationen sind über die `IsarCollection` verfügbar .

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
