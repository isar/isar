---
title: Erstellen, Lesen, Aktualisieren und Löschen
---

# Erstellen, Lesen, Aktualisieren und Löschen

Lerne wie du Collections in Isar nutzt nachdem du sie definiert hast.

## Öffnen von Isar

Als Erstes benötigen wir eine Isar Instanz. Jede Instanz erfordert einen Ordner mit Schreibrechten, in dem die Datenbankdatei gespeichert werden kann. Wenn du keinen Ordner angibst, wird Isar einen geeigneten Standardordner für die aktuelle Plattform finden.

Gib alle Schemas an, die du mit der Isar-Instanz verwenden möchtest. Wenn du mehrere Instanzen öffnest, musst du trotzdem jeder Instanz die gleichen Schemas mitgeben.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [RecipeSchema],
  directory: dir.path,
);
```

Du kannst die Standardkonfiguration verwenden oder einige der folgenden Parameter setzen:

| Konfiguration       | Beschreibung                                                                                                                                                                                                        |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`              | Öffne mehrere Instanzen mit unterschiedlichen Namen. Standardmäßig wird `"default"` verwendet.                                                                                                                      |
| `directory`         | Der Speicherort für diese Instanz. Standardmäßig wird `NSDocumentDirectory` für iOS und `getDataDirectory` für Android verwendet. Nicht erforderlich für Web.                                                       |
| `relaxedDurability` | Entspannt die durability-Garantie, um die Schreibleistung zu erhöhen. Im Falle eines Systemabsturzes (nicht App-Absturz) ist es möglich, die letzte Transaktion zu verlieren. Datenbankkorruption ist nicht möglich |

Wenn eine Instanz bereits geöffnet ist, wird `Isar.open()` die vorhandene Instanz unabhängig von den angegebenen Parametern zurückgeben. Das ist nützlich, um Isar in einem Isolate zu verwenden.

:::tip
Verwende das [path_provider](https://pub.dev/packages/path_provider)-Paket, um einen gültigen Pfad auf allen Plattformen zu erhalten.
:::

Der Speicherort der Datenbankdatei ist `directory/name.isar`

## Aus der Datenbank lesen

Verwende `IsarCollection`-Instanzen um Objekte eines bestimmten Typs in Isar zu finden, abzufragen und neu zu erstellen.

Den folgenden Beispielen liegt die Collection `Recipe` zugrunde, die wie folgt definiert ist:

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### Eine Collection erhalten

Alle deine Collections befinden sich in der Isar Instanz. Erhalte die Recipes-Collection über den Accessor:

```dart
final recipes = isar.recipes;
```

Das war einfach! Wenn du keine Collection-Accessors verwenden möchtest, ist alternativ die `collection()`-Methode verfügbar:

```dart
final recipes = isar.collection<Recipe>();
```

### Objekt abrufen (per ID)

Wir haben noch keine Daten in der Collection, aber wir nehmen an, dass bereits ein Objekt mit der ID `123` existiert.

```dart
final recipe = await recipes.get(123);
```

Die `get()`-Methode gibt ein `Future` zurück, das entweder das Objekt enthält, oder `null`, wenn die ID nicht existiert. Alle Isar-Operationen sind standardmäßig asynchron, auch wenn die meisten ein synchrones Gegenstück haben:

```dart
final recipe = recipes.getSync(123);
```

:::warning
Normalerweise solltest du die asynchrone Version der Methoden in deinem UI-Isolate bevorzugen. Da Isar sehr schnell ist, sind die synchronen Methoden oft auch in Ordnung.
:::

Wenn du mehrere Objekte auf einmal abrufen möchtest, kannst du `getAll()` oder `getAllSync()` verwenden:

```dart
final recipe = await recipes.getAll([1, 2]);
```

### Abfragen von Objekten

Anstatt Objekte über die ID zu erhalten, kannst du mittels `.where()` und `.filter()` auch eine Liste von Objekten abfragen, die bestimmten Bedingungen entsprechen:

```dart
final allRecipes = await recipes.where().findAll();

final favourites = await recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ Lerne mehr: [Abfragen](queries)

## Ändern der Datenbank

Jetzt ist es endlich an der Zeit, unsere Collection zu verändern! Um Objekte zu erstellen, zu aktualisieren oder zu löschen, rufe die entsprechenden Operationen innerhalb einer Schreibtransaktion auf:

```dart
await isar.writeTxn(() async {
  final recipe = await recipes.get(123)

  recipe.isFavorite = false;
  await recipes.put(recipe); // Aktualisierungsoperationen

  await recipes.delete(123); // oder Löschoperationen durchführen
});
```

➡️ Lerne mehr: [Transaktionen](transactions)

### Objekt erstellen

Erstelle ein Objekt in einer Collection um es in Isar zu speichern. Die `put()`-Methode von Isar erstellt das Objekt entweder oder aktualisiert es, je nachdem, ob es bereits in der Collection existiert.

Wenn das ID-Feld `null` oder `Isar.autoIncrement` ist, verwendet Isar eine automatisch generierte ID.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await recipes.put(pancakes);
})
```

Ist das ID-Feld nicht-final, weist Isar die generierte ID automatisch dem Objekt zu.

Das Erstellen von mehreren Objekten auf einmal ist genauso einfach:

```dart
await isar.writeTxn(() async {
  await recipes.putAll([pancakes, pizza]);
})
```

### Objekt aktualisieren

Sowohl das Erstellen als auch das Aktualisieren funktioniert mit `collection.put(object)`. Wenn die ID `null` ist (oder nicht existiert), wird das Objekt erstellt, andernfalls wird es aktualisiert.

Wenn wir also Pfannkuchen nicht mehr mögen, können wir Folgendes tun:

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await recipes.put(recipe);
});
```

### Objekt löschen

Willst du ein Objekt in Isar loswerden? Verwende `collection.delete(id)`. Die delete-Methode gibt zurück, ob ein Objekt mit der angegebenen ID gefunden und gelöscht wurde. Lass uns z.B. das Objekt mit der ID `123` löschen:

```dart
await isar.writeTxn(() async {
  final success = await recipes.delete(123);
  print('Recipe deleted: $success');
});
```

Ähnlich wie bei `get()` und `put()` gibt es auch einen Massenlöschvorgang, der die Anzahl der gelöschten Objekte zurückgibt:

```dart
await isar.writeTxn(() async {
  final count = await recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

Wenn du die IDs der zu löschenden Objekte nicht kennst ist es auch möglich eine Abfrage zu verwenden:

```dart
await isar.writeTxn(() async {
  final count = await recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
