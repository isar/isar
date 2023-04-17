---
title: Avvio rapido
---

# Avvio rapido

Santi numi, sei qui! Iniziamo a usare il database Flutter più interessante in circolazione...

In questa guida introduttiva saremo a corto di parole e veloci nel codice.

## 1. Aggiungi dipendenze

Prima che inizii il divertimento, dobbiamo aggiungere alcuni pacchetti a `pubspec.yaml`. Possiamo usare il pub per facilitarci il lavoro pesante.

```bash
flutter pub add isar isar_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. Annota le classi

Annota le tue classi collection con `@collection` e scegli un campo `Id`.

```dart
part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // puoi anche usare id = null per incrementare automaticamente

  String? name;

  int? age;
}
```

Gli ID identificano in modo univoco gli oggetti in una collezione e ti consentono di ritrovarli in seguito.

## 3. Esegui il generatore di codice

Esegui il seguente comando per avviare `build_runner`:

```
dart run build_runner build
```

Se stai usando Flutter, usa quanto segue:

```
flutter pub run build_runner build
```

## 4. Apri l'istanza Isar

Apri una nuova istanza Isar e passa tutti i tuoi schemi di raccolte. Facoltativamente, puoi specificare un nome di istanza e una directory.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [UserSchema],
  directory: dir.path,
);
```

## 5. Scrivi e leggi

Una volta aperta l'istanza, puoi iniziare a utilizzare le raccolte.

Tutte le operazioni CRUD di base sono disponibili tramite "IsarCollection".

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

## Altre risorse

Sei uno studente visivo? Guarda questi video per iniziare con Isar:
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