---
title: Migrazione dei dati
---

# Migrazione dei dati

Isar migra automaticamente gli schemi del database se aggiungi o rimuovi raccolte, campi o indici. A volte potresti voler migrare anche i tuoi dati. Isar non offre una soluzione integrata perché imporrebbe restrizioni alle migrazioni arbitrarie. È facile implementare la logica di migrazione adatta alle tue esigenze.

Vogliamo utilizzare una singola versione per l'intero database in questo esempio. Utilizziamo le preferenze condivise per archiviare la versione corrente e confrontarla con la versione a cui vogliamo migrare. Se le versioni non corrispondono, migriamo i dati e aggiorniamo la versione.

:::tip
Puoi anche assegnare a ciascuna raccolta la propria versione e migrarle individualmente.
:::

Immagina di avere una raccolta di utenti con un campo di compleanno. Nella versione 2 della nostra app, abbiamo bisogno di un campo aggiuntivo per l'anno di nascita per interrogare gli utenti in base all'età.

Versione 1:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;
}
```

Versione 2:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

Il problema è che i modelli utente esistenti avranno un campo `birthYear` vuoto perché non esisteva nella versione 1. Abbiamo bisogno di migrare i dati per impostare il campo `birthYear`.

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
Se devi migrare molti dati, prendi in considerazione l'utilizzo di un isolamento in background per evitare sollecitazioni sul thread dell'interfaccia utente.
:::
