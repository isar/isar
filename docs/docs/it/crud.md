---
title: Create, Read, Update, Delete
---

# Create, Read, Update, Delete

Quando hai definito le tue collezioni, impara a manipolarle!

## Apertura di Isar

Prima che tu possa fare qualsiasi cosa, abbiamo bisogno di un'istanza Isar. Ogni istanza richiede una directory con autorizzazione di scrittura in cui è possibile archiviare il file di database. Se non specifichi una directory, Isar troverà una directory predefinita adatta per la piattaforma corrente.

Fornisci tutti gli schemi che desideri utilizzare con l'istanza Isar. Se apri più istanze, devi comunque fornire gli stessi schemi a ciascuna istanza.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [ContactSchema],
  directory: dir.path,
);
```

È possibile utilizzare la configurazione predefinita o fornire alcuni dei seguenti parametri:

| Config. |  Descrizione |
| -------| -------------|
| `name` | Apri più istanze con nomi distinti. Per impostazione predefinita, viene utilizzato `"predefinito"`. |
| `directory` | Il percorso di archiviazione per questa istanza. Puoi passare un percorso relativo o assoluto. Per impostazione predefinita, `NSDocumentDirectory` viene utilizzato per iOS e `getDataDirectory` per Android. Non richiesto per il web. |
| `relaxedDurability` | Rilassa la garanzia di durata per aumentare le prestazioni di scrittura. In caso di arresto anomalo del sistema (non arresto anomalo dell'app), è possibile perdere l'ultima transazione impegnata. La corruzione non è possibile |
| `compactOnLaunch` | Condizioni per verificare se il database deve essere compattato all'apertura dell'istanza. |
| `inspector` | Abilita l'Inspector per le build di debug. Per le build di profili e versioni questa opzione viene ignorata. |

Se un'istanza è già aperta, la chiamata a `Isar.open()` fornirà l'istanza esistente indipendentemente dai parametri specificati. È utile per usare Isar in un isolate.

:::tip
Prendi in considerazione l'utilizzo del pacchetto [path_provider](https://pub.dev/packages/path_provider) per ottenere un percorso valido su tutte le piattaforme.
:::

Il percorso di archiviazione del file di database è `directory/name.isar`.

## Lettura dal database

Usa le istanze di `IsarCollection` per trovare, interrogare e creare nuovi oggetti di un determinato tipo in Isar.

Per gli esempi seguenti, assumiamo di avere una raccolta "Ricetta" definita come segue:

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### Ottieni una raccolta

Tutte le tue raccolte vivono nell'istanza Isar. Puoi ottenere la raccolta di ricette con:

```dart
final recipes = isar.recipes;
```

È stato facile! Se non vuoi usare le funzioni di accesso alla raccolta, puoi anche usare il metodo `collection()`:

```dart
final recipes = isar.collection<Recipe>();
```

### Ottieni un oggetto (per ID)

Non abbiamo ancora dati nella raccolta, ma facciamo finta di farlo in modo da poter ottenere un oggetto immaginario con l'id `123`

```dart
final recipe = await recipes.get(123);
```

`get()` restituisce un `Future` con l'oggetto o `null` se non esiste. Tutte le operazioni Isar sono asincrone per impostazione predefinita e la maggior parte di esse ha una controparte sincrona:

```dart
final recipe = recipes.getSync(123);
```

:::warning
Per impostazione predefinita, dovresti utilizzare la versione asincrona dei metodi nell'isolato dell'interfaccia utente. Poiché Isar è molto veloce, è spesso accettabile utilizzare la versione sincrona.
:::

Se vuoi ottenere più oggetti contemporaneamente, usa `getAll()` o `getAllSync()`:

```dart
final recipe = await recipes.getAll([1, 2]);
```

### Interroga gli oggetti

Invece di ottenere oggetti per id puoi anche interrogare un elenco di oggetti che soddisfano determinate condizioni usando `.where()` e `.filter()`:

```dart
final allRecipes = await recipes.where().findAll();

final favouires = await recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ Scopri di più: [Queries](queries)

## Modifica del database

È finalmente arrivato il momento di modificare la nostra collezione! Per creare, aggiornare o eliminare oggetti, utilizzare le rispettive operazioni racchiuse in una transazione di scrittura:

```dart
await isar.writeTxn(() async {
  final recipe = await recipes.get(123)

  recipe.isFavorite = false;
  await recipes.put(recipe); // perform update operations

  await recipes.delete(123); // or delete operations
});
```

➡️ Scopri di più: [Transactions](transactions)

### Inserimento

Per rendere persistente un oggetto in Isar, inserirlo in una collezione. Il metodo `put()` di Isar inserirà o aggiornerà l'oggetto a seconda che esista già nella raccolta.

Se il campo id è `null` o `Isar.autoIncrement`, Isar utilizzerà un id di incremento automatico.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await recipes.put(pancakes);
})
```

Isar assegnerà automaticamente l'id all'oggetto se il campo `id` non è definitivo.

Inserire più oggetti contemporaneamente è altrettanto facile:

```dart
await isar.writeTxn(() async {
  await recipes.putAll([pancakes, pizza]);
})
```

### Aggiornamento

Sia la creazione che l'aggiornamento funzionano con `collection.put(object)`. Se l'id è `null` (o non esiste), l'oggetto viene inserito; in caso contrario, viene aggiornato.

Quindi, se vogliamo eliminare i nostri pancake dai preferiti, possiamo fare quanto segue:

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await recipes.put(recipe);
});
```

### Eliminazione

Vuoi sbarazzarti di un oggetto in Isar? Usa `collection.delete(id)`. Il metodo delete restituisce se un oggetto con l'ID specificato è stato trovato ed eliminato. Se vuoi eliminare l'oggetto con id `123`, ad esempio, puoi fare:

```dart
await isar.writeTxn(() async {
  final success = await recipes.delete(123);
  print('Recipe deleted: $success');
});
```

Allo stesso modo per get e put, esiste anche un'operazione di eliminazione in blocco che restituisce il numero di oggetti eliminati:

```dart
await isar.writeTxn(() async {
  final count = await recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

Se non conosci gli ID degli oggetti che desideri eliminare, puoi utilizzare una query:

```dart
await isar.writeTxn(() async {
  final count = await recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
