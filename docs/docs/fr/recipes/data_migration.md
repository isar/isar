---
title: Migration des données
---

# Migration des données

Isar migre automatiquement les schémas de notre base de données si nous ajoutons ou supprimons des collections, champs ou index. Il peut arriver que nous souhaitions également migrer des données. Isar n'offre pas de solution intégrée, car cela imposerait des restrictions de migration arbitraires. Il est facile d'implémenter une logique de migration adaptée à nos besoins.

Dans cet exemple, nous voulons utiliser une seule version pour l'ensemble de la base de données. Nous utilisons `shared_preferences` pour stocker la version actuelle et la comparer à la version vers laquelle nous désirons migrer. Si les versions ne correspondent pas, nous migrons les données et mettons à jour la version.

:::tip
Vous pouvez également donner à chaque collection sa propre version et les migrer individuellement.
:::

Imaginons que nous avons une collection d'utilisateurs avec un champ d'anniversaire. Dans la version 2 de notre application, nous avons besoin d'un champ supplémentaire pour l'année de naissance afin de rechercher des utilisateurs en fonction de leur âge.

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

Le problème est que les modèles d'utilisateurs existants auront un champ `birthYear` vide, car il n'existait pas dans la version 1. Nous devons migrer les données pour définir le champ `birthYear`.

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
      // Si la version n'est pas définie (nouvelle installation) ou si elle est déjà à 2, il n'est pas nécessaire de migrer.
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // Mise à jour de la version
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // Nous paginons à travers les utilisateurs pour éviter de tous les charger en mémoire en même temps
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // Nous n'avons pas besoin de mettre à jour quoi que ce soit puisque le `getter` `birthYear` est utilisé.
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
Si vous devez migrer un grand nombre de données, envisagez d'utiliser un isolat en arrière plan pour éviter de surcharger le thread de l'interface utilisateur.
:::
