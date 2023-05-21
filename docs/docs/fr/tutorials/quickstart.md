---
title: Démarrage rapide
---

# Démarrage rapide

Vous revoilà! Commençons à utiliser la base de données Flutter la plus cool qui soit...

Nous allons être brefs en mots et rapides en code dans ce démarrage rapide.

## 1. Ajout des dépendances

Avant de débuter, nous devons ajouter quelques dépendances au fichier `pubspec.yaml`. Nous pouvons utiliser la commande `pub` pour faire le gros du travail à notre place.

```bash
flutter pub add isar isar_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. Annotation de classes

Annotez vos classes de collection avec `@collection` et choisissez un champ `Id`.

```dart
part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // Vous pouvez aussi utiliser id = null pour l'auto incrémentation

  String? name;

  int? age;
}
```

Les Ids identifient de manière unique les objets d'une collection et vous permettent de les retrouver ultérieurement.

## 3. Exécuter le générateur de code

Exécutez la commande suivante pour démarrer le `build_runner`:

```sh
dart run build_runner build
```

Si vous utilisez Flutter:

```sh
flutter pub run build_runner build
```

## 4. Ouverture l'instance Isar

Ouvrez une nouvelle instance d'Isar et passez tous vos schémas de collection. En option, vous pouvez spécifier un nom d'instance et un dossier.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [UserSchema],
  directory: dir.path,
);
```

## 5. Écriture et lecture

Une fois que votre instance est ouverte, vous pouvez commencer à utiliser les collections.

Toutes les opérations CRUD de base sont disponibles via `IsarCollection`.

```dart
final newUser = User()..name = 'Jane Doe'..age = 36;

await isar.writeTxn(() async {
  await isar.users.put(newUser); // Insertion & modification
});

final existingUser = await isar.users.get(newUser.id); // Obtention

await isar.writeTxn(() async {
  await isar.users.delete(existingUser.id!); // Suppression
});
```

## Autre ressources

Vous apprenez mieux visuellement ? Regardez ces vidéos pour commencer avec Isar:

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
