---
title: Abfragen
---

# Abfragen

Mit Abfragen kannst du Einträge finden, die bestimmten Bedinungen entsprechen, zum Beispiel:

- Finde alle markierten Kontakte
- Finde unterscheidbare Vornamen in den Kontakten
- Lösche alle Kontakte, die keinen Nachnamen definiert haben

Weil Abfragen auf der Datenbank ausgeführt werden, und nicht in Dart, sind sie sehr schnell. Wenn du Indizes sinnvoll benutzt, dann kannst du deine Abfrageleistung sogar weiter verbessern. Als nächstes lernst du, wie man Abragen schreibt und wie du sie so schnell wie möglich machen kannst.

Es gibt zwei verschiedene Methoden, Einträge zu filtern: Filter und Where-Bedingungen<!--where clauses-->. Wir starten indem wir uns die Funktionsweise von Filtern ansehen.

## Filter

Filter sind leicht zu benutzen und zu verstehen. Abhängig von den Typen deiner Eigenschaften gibt es verschiedene verfügbare Filteroperationen mit größtenteils selbsterklärenden Namen.

Filter funktionieren, indem sie einen Ausdruck für jedes Objekt der zu filternded Collection evaluieren. Wenn der Ausdruck zu `true` aufgelöst wird, dann fügt Isar das Objekt zu den Ergebnissen hinzu.
Filter haben keinen Einfluss auf die Reihenfolge der Ergebnisse.

Wir benutzen das folgende Modell für die Beispiele witer unten:

```dart
@collection
class Shoe {
  Id? id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### Abfragebedingungen

Abhängig vom Feld-Typen gibt es verschiedene mögliche Bedingungen.

| Bedingung                | Beschreibung                                                                                                                                        |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.equalTo(value)`        | Trifft auf Werte zu, die mit dem angegebenen `value` übereinstimmen.                                                                                |
| `.between(lower, upper)` | Trifft auf Werte zu, die zwischen `lower` und `upper` liegen.                                                                                       |
| `.greaterThan(bound)`    | Trifft auf Werte zu, de größer als `bound` sind.                                                                                                    |
| `.lessThan(bound)`       | Trifft auf Werte zu, die kleiner als `bound` sind. `null`-Werte werden eingeschlossen, da `null` als kleiner als jeder andere Wert betrachtet wird. |
| `.isNull()`              | Trifft auf Werte zu, die `null` sind.                                                                                                               |
| `.isNotNull()`           | Trifft auf Werte zu, die nicht `null` sind.                                                                                                         |
| `.length()`              | Abfragen nach Längen von Listen, Strings und Links filtern Objekte basierend auf der Anzahl der Elemente in einer Liste oder in einem Link.         |

Nehmen wir an, dass die Datenbank vier Schuhe mit den Gößen 39, 40, 46 und einen mit einer nicht festgelegten Größe (`null`). Wenn du keinen Sortierung durchführst, werden die Werte nach ID sortiert zurückgegeben.

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

### Logische Operatoren

Du kannst Aussagen zusammensetzen, indem du die folgenden logischen Operatoren verwendest:

| Operator   | Beschreibung                                                                         |
| ---------- | ------------------------------------------------------------------------------------ |
| `.and()`   | Ergibt `true`, wenn von linkem und rechtem Ausdruck beide `true` ergeben.            |
| `.or()`    | Ergibt `true`, wenn mindestens einer von beiden Ausdrücken `true` ergibt.            |
| `.xor()`   | Ergibt `true`, wenn genau einer von beiden Ausdrücken `true` ergibt.                 |
| `.not()`   | Negiert das Ergebnis des folgenden Ausdrucks.                                        |
| `.group()` | Gruppiert Bedingungen und ermöglicht es eine Reihenfolge des Auswertens festzulegen. |

Wenn du alle Schuhe mit der Größe 46 finden möchstes, kannst du die folgende Abfrage verwenden:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

Wenn du mehr als eine Bedingung angeben möchtest, kannst du mehrere Filter verbinden, indem du sie mit logischem **und** `.and()`, logischem **oder** `.or()` und logischem **exklusiven oder** `.xor()` verbindest.

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // Optional. Filter werden implizit mit einem logischen UND verbunden.
  .isUnisexEqualTo(true)
  .findAll();
```

Diese Abfrage ist äquivalent zu: `size == 46 && isUnisex == true`.

Du kannst auch Bedinungen gruppieren, indem du `.group()` benutzt:

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

Diese Abfrage ist äquivalent zu: `size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)`.

Um eine Bedingung oder Gruppe zu negieren kannst du das logische **oder** `.not()` verwenden:

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

Diese Abfrage ist äquivalent zu: `size != 46 && isUnisex != true`.

### String-Bedingungen

Zusätzlich zu den vorher genannten Abfragebedingungen bieten String-Werte ein paar mehr Bedingungen, die du benutzen kannst. Platzhalter, ähnlich zu beispielsweise Regex, erlauben mehr Flexibilität beim Suchen.

| Bedingung            | Beschreibung                                                                   |
| -------------------- | ------------------------------------------------------------------------------ |
| `.startsWith(value)` | Trifft auf String-Werte zu, die mit dem angegebenen `value` beginnen.          |
| `.contains(value)`   | Trifft auf String-Werte zu, die das angegebene `value` enthalten.              |
| `.endsWith(value)`   | Trifft auf String-Werte zu, die mit dem angegebenen `value` enden.             |
| `.matches(wildcard)` | Trifft auf String-Werte zu, die dem angegebenen `wildcard`-Muster entsprechen. |

**Groß-/Kleinschreibung**  
Alle String-Operationen haben eine optionalen `caseSensitive`-Eigenschaft, die standardmäßig `true` ist.

**Platzhalter**  
Der [Ausdruck eine Platzhalter-Strings](https://de.wikipedia.org/wiki/Wildcard_(Informatik)) ist ein String der normale Zeichen mit zwei speziellen Platzhalter-Zeichen verwendet:

- Der `*` Platzhalter trifft auf keines oder mehr von jedem Zeichen zu.
- Der `?` Platzhalter trifft auf jedes Einzelzeichen zu.  
  Zum Beispiel trifft der Platzhalter-String `"d?g"` auf `"dog"`, `"dig"` und `"dug"` zu, nicht aber auf `"ding"`, `"dg"` oder `"a dog"`.

### Abfragemodifikatoren

Manchmal ist es notwendig eine Abfrage auf Bedingungen aufzubauen oder für verschiedene Werte zu bauen. Isar hat ein sehr mächtiges Werkzeug um bedingte Abfragen zu bauen:

| Modifikator           | Beschreibung                                                                                                                                                                                     |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `.optional(cond, qb)` | Erweitert die Abfrage nur, wenn die Bedinung `cond`, `true` ist. Das kann fast überall in einer Abfrage verwendet werden, beispielsweise um sie über eine Bedingung zu sortieren oder begrenzen. |
| `.anyOf(list, qb)`    | Erweitert die Abfrage für jeden Wert in `values` und verbindet die Bedingungen mit einem logischen **oder**.                                                                                     |
| `.allOf(list, qb)`    | Erweitert die Abfrage für jeden Wert in `values` und verbindet die Bedingungen mit einem logischen **und**.                                                                                      |

In diesem Beispiel bauen wir eine Methode, die Schuhe mit einem optionale Filter finden kann:

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // Wendet den Filter nur an, wenn sizeFilter != null
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

Wenn du alle Schuhe finden möchtest, die eine von mehreren Schugrößen haben, kannst du entweder eine konventionelle Abfrage schreiben oder den `anyOf()` Modifikator verwenden:

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

Abfragemodifikatoren sind besonders dann sinnvoll, wenn du dynamische Abfragen bauen möchtest.

### Listen

Abfragen können sogar auf Listen gestellt werden:

```dart
class Tweet {
  Id? id;

  String? text;

  List<String> hashtags = [];
}
```

Du kannst eine Abfrage auf Basis der Listenlänge bauen:

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

Diese sind aquivalent zu dem Dart Code `tweets.where((t) => t.hashtags.isEmpty);` und `tweets.where((t) => t.hashtags.length > 5);`. Du kannst auch Abfragen basierend auf Listenelementen stellen:

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

Das ist äquivalent zum Dart Code `tweets.where((t) => t.hashtags.contains('flutter'));`.

### Eingebettete Objekte

Eingebettete Objekte sind eines von Isars nützlichsten Features. Sie können sehr einfach abgefragt werden mit gleichen Bedingungen für Objekte der obersten Ebene. Nehmen wir an, dass wir das folgende Modell haben:

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

Wir wollen alle Autos abfragen, die eine Marke mit dem Namen `"BMW"` und dem Land `"Germany"` haben. Wir können das mit der folgenden Abfrage machen:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

Versuche immer verschachtelte Abfragen zu gruppieren. Die vorherige Abfrage ist effizienter als die nächste, auch wenn das Ergebnis das gleiche ist:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### Links

Wenn dein Modell [Links oder Rückverlinkungen](links) enthält, kannst du deine Abfrage auf Basis der verlinkten Objekte oder der Anzahl an verlinkten Objekten filtern.

:::warning
Beachte, dass Link-Abfragen teuer sein können, weil Isar die verlinkten Objekte abrufen muss. Versuche stattdessen eingebettete Objekte zu verwenden.
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

Wir wollen alle Schüler finden, die einen Mathe- oder Englischlehrer haben:

```dart
final result = await isar.students.filter()
  .teachers((q) {
    return q.subjectEqualTo('Math')
      .or()
      .subjectEqualTo('English');
  }).findAll();
```

Link-Filter resultieren zu `true`, wenn mindestens eines der verlinkten Objekte den Bedingungen entspricht.

Suchen wir nach allen Schülern, die keine Lehrer haben:

```dart
final result = await isar.students.filter().teachersLengthEqualTo(0).findAll();
```

oder alternativ:

```dart
final result = await isar.students.filter().teachersIsEmpty().findAll();
```

## Where clauses

Where clauses are a very powerful tool, but it can be a little challenging to get them right.

In contrast to filters where clauses use the indexes you defined in the schema to check the query conditions. Querying an index is a lot faster than filtering each record individually.

➡️ Learn more: [Indexes](indexes)

:::tip
As a basic rule, you should always try to reduce the records as much as possible using where clauses and do the remaining filtering using filters.
:::

You can only combine where clauses using logical **or**. In other words, you can sum multiple where clauses together, but you can't query the intersection of multiple where clauses.

Let's add indexes to the shoe collection:

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

There are two indexes. The index on `size` allows us to use where clauses like `.sizeEqualTo()`. The composite index on `isUnisex` allows where clauses like `isUnisexSizeEqualTo()`. But also `isUnisexEqualTo()` because you can always use any prefix of an index.

We can now rewrite the query from before that finds unisex shoes in size 46 using the composite index. This query will be a lot faster than the previous one:

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

Where clauses have two more superpowers: They give you "free" sorting and a super fast distinct operation.

### Combining where clauses and filters

Remember the `shoes.filter()` queries? It's actually just a shortcut for `shoes.where().filter()`. You can (and should) combine where clauses and filters in the same query to use the benefits of both:

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

The where clause is applied first to reduce the number of objects to be filtered. Then the filter is applied to the remaining objects.

## Sorting

You can define how the results should be sorted when executing the query using the `.sortBy()`, `.sortByDesc()`, `.thenBy()` and `.thenByDesc()` methods.

To find all shoes sorted by model name in ascending order and size in descending order without using an index:

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

Sorting many results can be expensive, especially since sorting happens before offset and limit. The sorting methods above never make use of indexes. Luckily, we can again use where clause sorting and make our query lightning-fast even if we need to sort a million objects.

### Where clause sorting

If you use a **single** where clause in your query, the results are already sorted by the index. That's a big deal!

Let's assume we have shoes in sizes `[43, 39, 48, 40, 42, 45]` and we want to find all shoes with a size greater than `42` and also have them sorted by size:

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // also sorts the results by size
  .findAll(); // -> [43, 45, 48]
```

As you can see, the result is sorted by the `size` index. If you want to reverse the where clause sort order, you can set `sort` to `Sort.desc`:

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

Sometimes you don't want to use a where clause but still benefit from the implicit sorting. You can use the `any` where clause:

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

If you use a composite index, the results are sorted by all fields in the index.

:::tip
If you need the results to be sorted, consider using an index for that purpose. Especially if you work with `offset()` and `limit()`.
:::

Sometimes it's not possible or useful to use an index for sorting. For such cases, you should use indexes to reduce the number of resulting entries as much as possible.

## Unique values

To return only entries with unique values, use the distinct predicate. For example, to find out how many different shoe models you have in your Isar database:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

You can also chain multiple distinct conditions to find all shoes with distinct model-size combinations:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

Only the first result of each distinct combination is returned. You can use where clauses and sort operations to control it.

### Where clause distinct

If you have a non-unique index, you may want to get all of its distinct values. You could use the `distinctBy` operation from the previous section, but it's performed after sorting and filters, so there is some overhead.  
If you only use a single where clause, you can instead rely on the index to perform the distinct operation.

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
In theory, you could even use multiple where clauses for sorting and distinct. The only restriction is that those where clauses are not overlapping and use the same index. For correct sorting, they also need to be applied in sort order. Be very careful if you rely on this!
:::

## Offset & Limit

It's often a good idea to limit the number of results from a query for lazy list views. You can do so by setting a `limit()`:

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

By setting an `offset()` you can also paginate the results of your query.

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

Since instantiating Dart objects is often the most expensive part of executing a query, it is a good idea only to load the objects you need.

## Execution order

Isar executes queries always in the same order:

1. Traverse primary or secondary index to find objects (apply where clauses)
2. Filter objects
3. Sort results
4. Apply distinct operation
5. Offset & limit results
6. Return results

## Query operations

In the previous examples, we used `.findAll()` to retrieve all matching objects. There are more operations available, however:

| Operation        | Description                                                                                                         |
| ---------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.findFirst()`   | Retrieve only the first matching object or `null` if none matches.                                                  |
| `.findAll()`     | Retrieve all matching objects.                                                                                      |
| `.count()`       | Count how many objects match the query.                                                                             |
| `.deleteFirst()` | Delete the first matching object from the collection.                                                               |
| `.deleteAll()`   | Delete all matching objects from the collection.                                                                    |
| `.build()`       | Compile the query to reuse it later. This saves the cost to build a query if you want to execute it multiple times. |

## Property queries

If you are only interested in the values of a single property, you can use a property query. Just build a regular query and select a property:

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

Using only a single property saves time during deserialization. Property queries also work for embedded objects and lists.

## Aggregation

Isar supports aggregating the values of a property query. The following aggregation operations are available:

| Operation    | Description                                                    |
| ------------ | -------------------------------------------------------------- |
| `.min()`     | Finds the minimum value or `null` if none matches.             |
| `.max()`     | Finds the maximum value or `null` if none matches.             |
| `.sum()`     | Sums all values.                                               |
| `.average()` | Calculates the average of all values or `NaN` if none matches. |

Using aggregations is vastly faster than finding all matching objects and performing the aggregation manually.

## Dynamic queries

:::danger
This section is most likely not relevant to you. It is discouraged to use dynamic queries unless you absolutely need to (and you rarely do).
:::

All the examples above used the QueryBuilder and the generated static extension methods. Maybe you want to create dynamic queries or a custom query language (like the Isar Inspector). In that case, you can use the `buildQuery()` method:

| Parameter       | Description                                                                                 |
| --------------- | ------------------------------------------------------------------------------------------- |
| `whereClauses`  | The where clauses of the query.                                                             |
| `whereDistinct` | Whether where clauses should return distinct values (only useful for single where clauses). |
| `whereSort`     | The traverse order of the where clauses (only useful for single where clauses).             |
| `filter`        | The filter to apply to the results.                                                         |
| `sortBy`        | A list of properties to sort by.                                                            |
| `distinctBy`    | A list of properties to distinct by.                                                        |
| `offset`        | The offset of the results.                                                                  |
| `limit`         | The maximum number of results to return.                                                    |
| `property`      | If non-null, only the values of this property are returned.                                 |

Let's create a dynamic query:

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

The following query is equivalent:

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
