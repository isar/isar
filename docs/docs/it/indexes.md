---
title: Indici
---

# Indici

Gli indici sono la caratteristica più potente di Isar. Molti database incorporati offrono indici "normali" (se non del tutto), ma Isar ha anche indici compositi e multi-voce. Comprendere il funzionamento degli indici è essenziale per ottimizzare le prestazioni delle query. Isar ti permette di scegliere quale indice vuoi usare e come usarlo. Inizieremo con una rapida introduzione a cosa sono gli indici.

## Cosa sono gli indici?

Quando una raccolta non è indicizzata, è probabile che l'ordine delle righe non sia distinguibile dalla query in quanto non ottimizzato e la query dovrà quindi cercare tra gli oggetti in maniera lineare. In altre parole, la query dovrà cercare in ogni oggetto per trovare quelli che soddisfano le condizioni. Come puoi immaginare, può volerci del tempo. Guardare attraverso ogni singolo oggetto non è molto efficiente.

Ad esempio, questa raccolta `Product` non è ordinata.

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

**Dati:**

| id  | nome      | prezzo |
| --- | --------- | ----- |
| 1   | Book      | 15    |
| 2   | Table     | 55    |
| 3   | Chair     | 25    |
| 4   | Pencil    | 3     |
| 5   | Lightbulb | 12    |
| 6   | Carpet    | 60    |
| 7   | Pillow    | 30    |
| 8   | Computer  | 650   |
| 9   | Soap      | 2     |

Una query che tenti di trovare tutti i prodotti che costano più di € 30 deve cercare in tutte e nove le righe. Questo non è un problema per nove righe, ma potrebbe diventare un problema per 100.000 righe.

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

Per migliorare le prestazioni di questa query, indicizziamo la proprietà `price`. Un indice è come una tabella di ricerca ordinata:

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

**Indici generati:**

| price                | id                 |
| -------------------- | ------------------ |
| 2                    | 9                  |
| 3                    | 4                  |
| 12                   | 5                  |
| 15                   | 1                  |
| 25                   | 3                  |
| 30                   | 7                  |
| <mark>**55**</mark>  | <mark>**2**</mark> |
| <mark>**60**</mark>  | <mark>**6**</mark> |
| <mark>**650**</mark> | <mark>**8**</mark> |

Ora, la query può essere eseguita molto più velocemente. L'esecutore può saltare direttamente alle ultime tre righe dell'indice e trovare gli oggetti corrispondenti in base al loro ID.

### Ordinamento

Un'altra cosa interessante: gli indici possono eseguire un ordinamento super veloce. Le query ordinate sono costose perché il database deve caricare tutti i risultati in memoria prima di ordinarli. Anche se si specifica un offset o un limite, vengono applicati dopo l'ordinamento.

Immaginiamo di voler trovare i quattro prodotti più economici. Potremmo usare la seguente query:

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

In questo esempio, il database dovrebbe caricare tutti (!) gli oggetti, ordinarli per prezzo e restituire i quattro prodotti con il prezzo più basso.

Come probabilmente puoi immaginare, questo può essere fatto in modo molto più efficiente con l'indice precedente. Il database prende le prime quattro righe dell'indice e restituisce gli oggetti corrispondenti poiché sono già nell'ordine corretto.

Per utilizzare l'indice per l'ordinamento, scriveremo la query in questo modo:

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

La clausola `.anyX()` indica a Isar di usare un indice solo per l'ordinamento. Puoi anche usare una clausola where come `.priceGreaterThan()` e ottenere risultati ordinati.

## Indici univoci

Un indice univoco garantisce che l'indice non contenga valori duplicati. Può essere costituito da una o più proprietà. Se un indice univoco ha una proprietà, i valori in questa proprietà saranno univoci. Se l'indice univoco ha più di una proprietà, la combinazione di valori in queste proprietà è univoca.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

Qualsiasi tentativo di inserire o aggiornare i dati nell'indice univoco che causa un duplicato risulterà in un errore:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> ok

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

// try to insert user with same username
await isar.users.put(user2); // -> error: unique constraint violated
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## Sostituisci gli indici

A volte non è preferibile generare un errore se viene violato un vincolo univoco. Invece, potresti voler sostituire l'oggetto esistente con quello nuovo. Questo può essere ottenuto impostando la proprietà `replace` dell'indice su `true`.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

Ora quando proviamo a inserire un utente con un nome utente esistente, Isar sostituirà l'utente esistente con quello nuovo.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1);
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
print(await isar.user.where().findAll());
// > [{id: 2, username: 'user1' age: 30}]
```

Sostituire gli indici genera anche metodi `putBy()` che ti consentono di aggiornare gli oggetti invece di sostituirli. L'ID esistente viene riutilizzato e i collegamenti continuano a essere popolati.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// user does not exist so this is the same as put()
await isar.users.putByUsername(user1); 
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

Come puoi vedere, l'id del primo utente inserito viene riutilizzato.

## Indici senza distinzione tra maiuscole e minuscole

Tutti gli indici sulle proprietà `String` e `List<String>` fanno distinzione tra maiuscole e minuscole per impostazione predefinita. Se desideri creare un indice senza distinzione tra maiuscole e minuscole, puoi utilizzare l'opzione `caseSensitive`:

```dart
@collection
class Person {
  Id? id;

  @Index(caseSensitive: false)
  late String name;

  @Index(caseSensitive: false)
  late List<String> tags;
}
```

## Tipo di indice

Esistono diversi tipi di indici. La maggior parte delle volte, vorrai usare un indice `IndexType.value`, ma gli indici hash sono più efficienti.

### Indice di valore

Gli indici di valore sono il tipo predefinito e l'unico consentito per tutte le proprietà che non contengono stringhe o elenchi. I valori delle proprietà vengono utilizzati per creare l'indice. Nel caso di elenchi, vengono utilizzati gli elementi dell'elenco. È il più flessibile ma anche dispendioso in termini di spazio dei tre tipi di indice.

:::tip
Usa `IndexType.value` per le primitive, String dove hai bisogno della clausole-where `startsWith()` e List se vuoi cercare singoli elementi.
:::

### Indice hash

È possibile eseguire l'hashing di stringhe ed elenchi per ridurre significativamente lo spazio di archiviazione richiesto dall'indice. Lo svantaggio degli indici hash è che non possono essere usati per scansioni di prefissi (clausole-where `startsWith`).

:::tip
Usa `IndexType.hash` per stringhe ed elenchi se non hai bisogno di clausole-where `startsWith` e `elementEqualTo`.
:::

### Indice HashElements

Gli elenchi di stringhe possono essere sottoposti a hash per intero (usando `IndexType.hash`), oppure gli elementi dell'elenco possono essere sottoposti a hash separatamente (usando `IndexType.hashElements`), creando in modo efficace un indice multi-voce con elementi hash.

:::tip
Usa `IndexType.hashElements` per `List<String>` dove hai bisogno di clausole-where `elementEqualTo`.
:::

## Indici compositi

Un indice composito è un indice su più proprietà. Isar consente di creare indici compositi fino a tre proprietà.

Gli indici compositi sono anche noti come indici a più colonne.

Probabilmente è meglio iniziare con un esempio. Creiamo una collezione di persone e definiamo un indice composito sulle proprietà di età e nome:

```dart
@collection
class Person {
  Id? id;

  late String name;

  @Index(composite: [CompositeIndex('name')])
  late int age;

  late String hometown;
}
```

**Dati:**

| id  | nome   | età | città natale  |
| --- | ------ | --- | --------- |
| 1   | Daniel | 20  | Berlin    |
| 2   | Anne   | 20  | Paris     |
| 3   | Carl   | 24  | San Diego |
| 4   | Simon  | 24  | Munich    |
| 5   | David  | 20  | New York  |
| 6   | Carl   | 24  | London    |
| 7   | Audrey | 30  | Prague    |
| 8   | Anne   | 24  | Paris     |

**Indici generati:**

| età | nome   | id  |
| --- | ------ | --- |
| 20  | Anne   | 2   |
| 20  | Daniel | 1   |
| 20  | David  | 5   |
| 24  | Anne   | 8   |
| 24  | Carl   | 3   |
| 24  | Carl   | 6   |
| 24  | Simon  | 4   |
| 30  | Audrey | 7   |

L'indice composito generato contiene tutte le persone ordinate per età e nome.

Gli indici compositi sono ottimi se desideri creare query efficienti ordinate in base a più proprietà. Consentono anche clausole dove avanzate con più proprietà:

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

L'ultima proprietà di un indice composito supporta anche condizioni come `startsWith()` o `lessThan()`:

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## Indici a più voci

Se indicizzi una lista usando 'IndexType.value', Isar creerà automaticamente un indice multi-voce e ogni voce nella lista viene indicizzata verso l'oggetto. Funziona per tutti i tipi di liste.

Le applicazioni pratiche per gli indici a voci multiple includono l'indicizzazione di un elenco di tag o la creazione di un indice full-text.

```dart
@collection
class Product {
  Id? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` divide una stringa in parole secondo la specifica [Unicode Annex #29](https://unicode.org/reports/tr29/), quindi funziona correttamente per quasi tutte le lingue.

**Dati:**

| id  | description                  | descriptionWords             |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

Le voci con parole duplicate vengono visualizzate solo una volta nell'indice.

**Indici generati:**

| descriptionWords | id        |
| ---------------- | --------- |
| comfortable      | [1, 2]    |
| blue             | 1         |
| necktie          | 4         |
| plain            | 3         |
| pullover         | 2         |
| red              | [2, 3, 4] |
| super            | 4         |
| t-shirt          | [1, 3]    |

Questo indice può ora essere usato per prefisso (o uguaglianza) dove clausole delle singole parole della descrizione.

:::tip
Invece di memorizzare direttamente le parole, considera anche l'utilizzo del risultato di un [algoritmo fonetico](https://en.wikipedia.org/wiki/Algoritmo_fonetico) come [Soundex](https://en.wikipedia.org/wiki/ Soundex).
:::
