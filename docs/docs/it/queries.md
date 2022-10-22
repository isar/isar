---
title: Query
---

# Query

La query è il modo in cui trovi i record che soddisfano determinate condizioni, ad esempio:

- Trova tutti i contatti speciali
- Trova nomi distinti nei contatti
- Elimina tutti i contatti che non hanno il cognome definito

Poiché le query vengono eseguite sul database e non in Dart, sono molto veloci. Quando usi in modo intelligente gli indici, puoi migliorare ulteriormente le prestazioni delle query. Di seguito, imparerai come scrivere query e come renderle il più velocemente possibile.

Esistono due diversi metodi per filtrare i record: i filtri e le clausole where. Inizieremo dando un'occhiata a come funzionano i filtri.

## Filtri

I filtri sono facili da usare e da capire. A seconda del tipo di proprietà, sono disponibili diverse operazioni di filtro, la maggior parte delle quali ha nomi autoesplicativi.

I filtri funzionano valutando un'espressione per ogni oggetto della raccolta che viene filtrata. Se l'espressione si risolve in `true`, Isar include l'oggetto nei risultati. I filtri non influiscono sull'ordine dei risultati.

Utilizzeremo il seguente modello per gli esempi seguenti:

```dart
@collection
class Shoe {
  Id? id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### Condizioni di query

A seconda del tipo di campo, sono disponibili diverse condizioni.

| Condizione | Descrizione |
| ----------| ------------|
| `.equalTo(value)` | Corrisponde a valori uguali al `value` specificato. |
| `.between(lower, upper)` | Corrisponde ai valori compresi tra `lower` and `upper`. |
| `.greaterThan(bound)` | Corrisponde a valori maggiori di `bound`. |
| `.lessThan(bound)` | Corrisponde a valori inferiori a `bound`. I valori `null` verranno inclusi per impostazione predefinita perché `null` è considerato inferiore a qualsiasi altro valore. |
| `.isNull()` | Corrisponde a valori `null'.|
| `.isNotNull()` | Corrisponde a valori che non sono `null'.|
| `.length()` | Le query su List, String e lunghezza del collegamento filtrano gli oggetti in base al numero di elementi in un elenco o in un collegamento. |

Supponiamo che il database contenga quattro scarpe con le taglie 39, 40, 46 e una con una taglia non impostata (`null`). A meno che non si esegua l'ordinamento, i valori verranno restituiti ordinati per id.

```dart

isar.shoes.filter()
  .sizeLessThan(40)
  .findAll() // -> [39, null]

isar.shoes.filter()
  .sizeLessThan(40, include: true)
  .findAll() // -> [39, null, 40]

isar.shoes.filter()
  .sizeBetween(39, 46, includeLower: false)
  .findAll() // -> [40, 46]

```

### Operatori logici

È possibile comporre predicati utilizzando i seguenti operatori logici:

| Operatore   | Descrizione |
| ---------- | ----------- |
| `.and()`   | Valuta come `true` se entrambe le espressioni della lato sinistro e della lato destro restituiscono `true`. |
| `.or()`    | Valuta come `true` se una delle espressioni restituisce `true`. |
| `.xor()`   | Valuta come `true` se esattamente un'espressione restituisce `true`. |
| `.not()`   | Nega il risultato della seguente espressione. |
| `.group()` | Raggruppa le condizioni e consente di specificare l'ordine di valutazione. |

Se vuoi trovare tutte le scarpe nella taglia 46, puoi utilizzare la seguente query:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

Se vuoi usare più di una condizione, puoi combinare più filtri usando **and** logico `.and()`, **or** logico `.or()` e **xor** logico `. xor()`.

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // Optional. Filters are implicitly combined with logical and.
  .isUnisexEqualTo(true)
  .findAll();
```

Questa query equivale a: `size == 46 && isUnisex == true`.

Puoi anche raggruppare le condizioni usando `.group()`:

```dart
final result = await isar.shoes.filter()
  .sizeBetween(43, 46)
  .and()
  .group((q) => q
    .modelNameContains('Nike')
    .or()
    .isUnisexEqualTo(false)
  )
  .findAll()
```

Questa query equivale a `size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)`.

Per negare una condizione o un gruppo, usa la logica **not** `.not()`:

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

Questa query equivale a `size != 46 && isUnisex != true`.

### Condizioni di stringa

Oltre alle condizioni di query precedenti, i valori String offrono alcune condizioni in più che puoi utilizzare. I caratteri jolly simili a Regex, ad esempio, consentono una maggiore flessibilità nella ricerca.

| Condizione            | Descrizione                                                       |
| -------------------- | ----------------------------------------------------------------- |
| `.startsWith(value)` | Corrisponde ai valori di stringa che iniziano con il `valore` fornito.          |
| `.contains(value)`   | Corrisponde ai valori di stringa che contengono il `valore` fornito.          |
| `.endsWith(value)`   | Corrisponde ai valori di stringa che terminano con il `valore` fornito.         |
| `.matches(wildcard)` | Corrisponde ai valori di stringa che corrispondono al modello `jolly` fornito. |

**Maiuscole/minuscole**
Tutte le operazioni sulle stringhe hanno un parametro `caseSensitive` opzionale che per impostazione predefinita è `true`.

**Wildcards:**  
**Caratteri jolly:**
Una [espressione di stringa con caratteri jolly](https://en.wikipedia.org/wiki/Wildcard_character) è una stringa che utilizza caratteri normali con due caratteri jolly speciali:

- Il carattere jolly `*` corrisponde a zero o più caratteri
- Il carattere jolly `?` corrisponde a qualsiasi carattere.
   Ad esempio, la stringa di caratteri jolly `"d?g"` corrisponde a `"dog"`, `"dig"` e `"dug"`, ma non a `"ding"`, `"dg"` o `" un cane"`.

### Modificatori di query

A volte è necessario creare una query in base ad alcune condizioni o per valori diversi. Isar ha uno strumento molto potente per la creazione di query condizionali:

| Modificatore              | Descrizione                                          |
| --------------------- | ---------------------------------------------------- |
| `.optional(cond, qb)` | Estende la query solo se la `condition` è `true`. Questo può essere utilizzato quasi ovunque in una query, ad esempio per ordinarlo o limitarlo in modo condizionale. |
| `.anyOf(list, qb)`    | Estende la query per ogni valore in `values` e combina le condizioni utilizzando la logica **or**. |
| `.allOf(list, qb)`    | Estende la query per ogni valore in `values` e combina le condizioni utilizzando **and** logici. |

In questo esempio, costruiamo un metodo in grado di trovare scarpe con un filtro opzionale:

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // only apply filter if sizeFilter != null
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

Se vuoi trovare tutte le scarpe che hanno una di più misure di scarpe, puoi scrivere una query convenzionale o utilizzare il modificatore `anyOf()`:

```dart
final shoes1 = await isar.shoes.filter()
  .sizeEqualTo(38)
  .or()
  .sizeEqualTo(40)
  .or()
  .sizeEqualTo(42)
  .findAll();

final shoes2 = await isar.shoes.filter()
  .anyOf(
    [38, 40, 42],
    (q, int size) => q.sizeEqualTo(size)
  ).findAll();

// shoes1 == shoes2
```

I modificatori di query sono particolarmente utili quando si desidera creare query dinamiche.

### Liste

Si possono interrogare anche le liste:

```dart
class Tweet {
  Id? id;

  String? text;

  List<String> hashtags = [];
}
```

È possibile eseguire query in base alla lunghezza della lista:

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

Questi sono equivalenti al codice Dart `tweets.where((t) => t.hashtags.isEmpty);` e `tweets.where((t) => t.hashtags.length > 5);`. Puoi anche interrogare in base agli elementi dell'elenco:

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

Questo equivale al codice Dart `tweets.where((t) => t.hashtags.contains('flutter'));`.

### Oggetti incorporati

Gli oggetti incorporati sono una delle funzionalità più utili di Isar. Possono essere interrogati in modo molto efficiente utilizzando le stesse condizioni disponibili per gli oggetti di livello superiore. Supponiamo di avere il seguente modello:

```dart
@collection
class Car {
  Id? id;

  Brand? brand;
}

@embedded
class Brand {
  String? name;

  String? country;
}
```

Vogliamo interrogare tutte le auto che hanno un marchio con il nome `"BMW"` e il paese `"Germania"`. Possiamo farlo usando la seguente query:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

Cerca sempre di raggruppare le query nidificate. La query precedente è più efficiente della seguente. Anche se il risultato è lo stesso:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### Collegamenti

Se il tuo modello contiene [link o backlink](links) puoi filtrare la tua query in base agli oggetti collegati o al numero di oggetti collegati.

:::warning
Tieni presente che le query di collegamento possono essere costose perché Isar ha bisogno di cercare oggetti collegati. Considera invece l'utilizzo di oggetti incorporati.
:::

```dart
@collection
class Teacher {
  Id? id;

  late String subject;
}

@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

Vogliamo trovare tutti gli studenti che hanno un insegnante di matematica o inglese:

```dart
final result = await isar.students.filter()
  .teachers((q) {
    return q.subjectEqualTo('Math')
      .or()
      .subjectEqualTo('English');
  }).findAll();
```

I filtri di collegamento restituiscono `true` se almeno un oggetto collegato soddisfa le condizioni.

Cerchiamo tutti gli studenti che non hanno insegnanti:
  
```dart
final result = await isar.students.filter().teachersLengthEqualTo(0).findAll();
```

o in alternativa:

```dart
final result = await isar.students.filter().teachersIsEmpty().findAll();
```

## Clausole Where

Le clausole where sono uno strumento molto potente, ma può essere un po' difficile metterle in pratica.

A differenza dei filtri le clausole where utilizzano gli indici definiti nello schema per verificare le condizioni della query. Interrogare un indice è molto più veloce che filtrare ogni record individualmente.

➡️ Scopri di più: [Indici](indexes)

:::tip
Come regola di base, dovresti sempre cercare di ridurre il più possibile i record usando le clausole where e fare il filtraggio rimanente usando i filtri.
:::

Puoi combinare solo le clausole where usando **or** logici. In altre parole, puoi sommare più clausole where insieme, ma non puoi interrogare l'intersezione di più clausole where.

Aggiungiamo gli indici alla collezione di scarpe:

```dart
@collection
class Shoe with IsarObject {
  Id? id;

  @Index()
  Id? size;

  late String model;

  @Index(composite: [CompositeIndex('size')])
  late bool isUnisex;
}
```

Ci sono due indici. L'indice su `size` ci permette di usare clausole where come `.sizeEqualTo()`. L'indice composito su `isUnisex` consente dove clausole come `isUnisexSizeEqualTo()`. Ma anche `isUnisexEqualTo()` perché puoi sempre usare qualsiasi prefisso di un indice.

Ora possiamo riscrivere la query precedente che trova scarpe unisex della taglia 46 utilizzando l'indice composito. Questa query sarà molto più veloce della precedente:

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

Le clausole where hanno altri due superpoteri: ti danno l'ordinamento "gratuito" e un'operazione distinta super veloce.

### Combinare clausole where e filtri

Ricordi le query `shoes.filter()`? In realtà è solo una scorciatoia per `shoes.where().filter()`. Puoi (e dovresti) combinare dove clausole e filtri nella stessa query per utilizzare i vantaggi di entrambi:

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

La clausola where viene applicata per prima per ridurre il numero di oggetti da filtrare. Quindi il filtro viene applicato agli oggetti rimanenti.

## Ordinamento

È possibile definire come ordinare i risultati durante l'esecuzione della query utilizzando i metodi `.sortBy()`, `.sortByDesc()`, `.thenBy()` e `.thenByDesc()`.

Per trovare tutte le scarpe ordinate per nome del modello in ordine crescente e taglia in ordine decrescente senza utilizzare un indice:

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

Ordinare molti risultati può essere costoso, soprattutto perché l'ordinamento avviene prima dell'offset e del limit. I metodi di ordinamento sopra non fanno mai uso di indici. Fortunatamente, possiamo di nuovo utilizzare l'ordinamento della clausola where e rendere la nostra query fulminea anche se dobbiamo ordinare un milione di oggetti.

### Ordinamento delle clausole where

Se utilizzi una clausola **singola** nella query, i risultati sono già ordinati in base all'indice. Questo è un grosso problema!

Supponiamo di avere scarpe nelle taglie `[43, 39, 48, 40, 42, 45]` e di voler trovare tutte le scarpe con una taglia maggiore di `42` e anche ordinarle per taglia:

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // also sorts the results by size
  .findAll(); // -> [43, 45, 48]
```

Come puoi vedere, il risultato è ordinato in base all'indice `size`. Se vuoi invertire l'ordinamento della clausola where, puoi impostare `sort` su `Sort.desc`:

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

A volte non si desidera utilizzare una clausola where ma comunque beneficiare dell'ordinamento implicito. Puoi usare la clausola `any` where:

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

Se utilizzi un indice composto, i risultati vengono ordinati in base a tutti i campi dell'indice.

:::tip
Se hai bisogno che i risultati siano ordinati, considera l'utilizzo di un indice a tale scopo. Soprattutto se lavori con `offset()` e `limit()`.
:::

A volte non è possibile o utile utilizzare un indice per l'ordinamento. In questi casi, dovresti utilizzare gli indici per ridurre il più possibile il numero di voci risultanti.

## Valori univoci

Per restituire solo voci con valori univoci, utilizzare il predicato distinto. Ad esempio, per scoprire quanti diversi modelli di scarpe hai nel tuo database Isar:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

Puoi anche concatenare più condizioni distinte per trovare tutte le scarpe con combinazioni di taglia modello distinte:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

Viene restituito solo il primo risultato di ogni combinazione distinta. È possibile utilizzare le clausole where e le operazioni di ordinamento per controllarlo.

### Clausola where distinta

Se hai un indice non univoco, potresti voler ottenere tutti i suoi valori distinti. Potresti usare l'operazione `distinctBy` della sezione precedente, ma viene eseguita dopo l'ordinamento e i filtri, quindi c'è un po' di sovraccarico.
Se utilizzi solo una singola clausola where, puoi invece fare affidamento sull'indice per eseguire l'operazione distinta.

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
In teoria, potresti anche usare più clausole where per l'ordinamento e la distinzione. L'unica restrizione è per quelle clausole where che non si sovrappongono e utilizzano lo stesso indice. Per un corretto ordinamento, devono anche essere applicati in ordine di ordinamento. Stai molto attento se fai affidamento su questo!
:::

## Offset e limit

Spesso è una buona idea limitare il numero di risultati di una query per le visualizzazioni lazy di liste. Puoi farlo impostando un `limit()`:

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

Impostando un `offset()` puoi anche impaginare i risultati della tua query.

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

Poiché la creazione di un'istanza di oggetti Dart è spesso la parte più costosa dell'esecuzione di una query, è una buona idea caricare solo gli oggetti necessari.

## Ordine di esecuzione

Isar esegue le query sempre nello stesso ordine:

1. Attraversa l'indice primario o secondario per trovare gli oggetti (applica le clausole where)
2. Filtra gli oggetti
3. Ordina i risultati
4. Applicare un'operazione distinta
5. Risultato offset e limite
6. Restituisci i risultati

## Operazioni di query

Negli esempi precedenti, abbiamo usato `.findAll()` per recuperare tutti gli oggetti corrispondenti. Ci sono più operazioni disponibili, tuttavia:

| Operazione        | Descrizione                                                                                                         |
| ---------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.findFirst()`   | Recupera solo il primo oggetto corrispondente o `null` se nessuno corrisponde.                                                  |
| `.findAll()`     | Recupera tutti gli oggetti corrispondenti.                                                                                      |
| `.count()`       | Conta quanti oggetti corrispondono alla query.                                                                             |
| `.deleteFirst()` | Elimina il primo oggetto corrispondente dalla raccolta.                                                               |
| `.deleteAll()`   | Elimina tutti gli oggetti corrispondenti dalla raccolta.                                                                    |
| `.build()`       | Compila la query per riutilizzarla in seguito. Ciò consente di risparmiare il costo per creare una query se si desidera eseguirla più volte. |

## Query sulla proprietà

Se sei interessato solo ai valori di una singola proprietà, puoi utilizzare una query di proprietà. Basta creare una query normale e selezionare una proprietà:

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

L'utilizzo di una sola proprietà consente di risparmiare tempo durante la deserializzazione. Le query sulle proprietà funzionano anche per gli oggetti e gli elenchi incorporati.

## Aggregazione

Isar supporta l'aggregazione dei valori di una query di proprietà. Sono disponibili le seguenti operazioni di aggregazione:

| Operazione    | Descrizione                                                    |
| ------------ | -------------------------------------------------------------- |
| `.min()`     | Trova il valore minimo o `null` se nessuno corrisponde.             |
| `.max()`     | Trova il valore massimo o `null` se nessuno corrisponde.             |
| `.sum()`     | Somma tutti i valori.                                               |
| `.average()` | Calcola la media di tutti i valori o 'NaN' se nessuno corrisponde. |

L'utilizzo delle aggregazioni è molto più veloce rispetto alla ricerca di tutti gli oggetti corrispondenti e all'esecuzione manuale dell'aggregazione.

## Query dinamiche

:::danger
Questa sezione molto probabilmente non è rilevante per te. È sconsigliato utilizzare query dinamiche a meno che non sia assolutamente necessario (e raramente lo fai).
:::

Tutti gli esempi precedenti hanno utilizzato QueryBuilder e i metodi di estensione statica generati. Forse vuoi creare query dinamiche o un linguaggio di query personalizzato (come Isar Inspector). In tal caso, puoi usare il metodo `buildQuery()`:

| Parametro       | Descrizione                                                                                 |
| --------------- | ------------------------------------------------------------------------------------------- |
| `whereClauses`  | Le clausole where della query.                                                             |
| `whereDistinct` | Se le clausole where devono restituire valori distinti (utile solo per clausole where singole). |
| `whereSort`     | L'ordine di scorrimento delle clausole where (utile solo per le clausole where singole).             |
| `filter`        | Il filtro da applicare ai risultati.                                                        |
| `sortBy`        | Un elenco di proprietà da ordinare.                                                            |
| `distinctBy`    | Un elenco di proprietà da distinguere.                                                        |
| `offset`        | L'offset dei risultati.                                                                  |
| `limit`         | Il numero massimo di risultati da restituire.                                                    |
| `property`      | Se non-null, vengono restituiti solo i valori di questa proprietà.                                 |

Creiamo una query dinamica:

```dart
final shoes = await isar.shoes.buildQuery(
  whereClauses: [
    WhereClause(
      indexName: 'size',
      lower: [42],
      includeLower: true,
      upper: [46],
      includeUpper: true,
    )
  ],
  filter: FilterGroup.and([
    FilterCondition(
      type: ConditionType.contains,
      property: 'model',
      value: 'nike',
      caseSensitive: false,
    ),
    FilterGroup.not(
      FilterCondition(
        type: ConditionType.contains,
        property: 'model',
        value: 'adidas',
        caseSensitive: false,
      ),
    ),
  ]),
  sortBy: [
    SortProperty(
      property: 'model',
      sort: Sort.desc,
    )
  ],
  offset: 10,
  limit: 10,
).findAll();
```

La seguente query è equivalente:

```dart
final shoes = await isar.shoes.where()
  .sizeBetween(42, 46)
  .filter()
  .modelContains('nike', caseSensitive: false)
  .not()
  .modelContains('adidas', caseSensitive: false)
  .sortByModelDesc()
  .offset(10).limit(10)
  .findAll();
```
