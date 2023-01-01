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

## Where-Klauseln

Where-Klauseln sind eine sehr mächtiges Werkzeug, aber es kann ein bisschen herausfordernd sein sie zu meistern.

Im Gegensatz zu Filtern nutzen Where-Klauseln die Indizes, die du im Schema definiert hast, um die Abfragebedingungen zu überprüfen. Einen Index abzufragen ist deutlich schneller als jeden Eintrag individuell zu filtern.

➡️ Lerne mehr: [Indizes](indexes)

:::tip
Als eine einfache Regel solltest du immer versuchen die Einträge so weit wie möglich mit Where-Klauseln einzugrenzen und das restliche Filtern mit Filtern machen.
:::

Du kannst Where-Klauseln nur mit logischem **oder** verbinden. In anderen Worten, du kannst mehrere Where-Klauseln zusammenfügen, aber du kannst nicht die Überschneidung mehrerer Where-Klauseln abfragen.

Lass uns Indizes zu der Schuh-Collection hinzufügen:

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

Hier gibt es zwei Indizes. Der Index auf `size` erlaubt es uns Where-Klauseln wie `.sizeEqualTo()` zu verwenden. Der zusammengesetzte Index auf `isUnisex` erlaubt es uns Whereö-Klauseln wie `.isUnisexSizeEqualTo()` zu nutzen. Aber auch `.isUnisexEqualTo()` ist möglich, weil du immer jedes Präfix eines Indexes benutzen kannst.

Wir können unsere Abfrage von vorher, die Unisex-Schuhe der Größe 46 findet, also mithilfe des zusammengesetzten Indizes umschreiben. Diese Abfrage sollte deutlich schneller sein, als die vorherige:

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

Where-Klauseln haben zwei weitere Superkräfte: Sie geben dir "kostenloses" Sortieren und eine superschnelle Eindeutigkeitsoperation.

### Where-Klauseln und Filter verbinden

Erinnerst du dich an die `shoes.filter()`-Abfragen? Das ist in Wirklichkeit nur eine Kurzform für `shoes.where().filter()`. Du kannst (und solltest) Where-Klauseln und Filter in der gleichen Abfrage verbinden, um die Vorteile beider zu nutzen:

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

Die Where-Klausel wird zuerst angewendet, um die Anzahl an Objekten die gefiltert werden müssen zu reduzieren. Dann wird der Filter auf die übrig gebliebenen Objekte angewendet.

## Sortierung

Du kannst definieren, wie Ergebnisse deiner Abfrage sortiert werden sollen, indem du die Methoden `.sortBy()`, `.sortByDesc()`, `.thenBy()` und `.thenByDesc()` nutzt.

Um alle Schuhe nach Modellnamen in aufsteigender und nach der Größe in absteigender Reihenfolge sortiert zu bekommen, ohne einen Index zu benutzen:

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

Viele Ergebnisse zu sortieren kann teuer sein, besonders, weil das Sortieren vor dem Offset und vor der Limitierung stattfindet. Die Sortiermethoden benutzen niemals Indizes. Glücklicherweise können wir wieder Sortierung mit Where-Klauseln verwenden und so unsere Abfrage blitzschnell machen, auch wenn wir eine Million Objekte sortieren müssen.

### Sortierung mit Where-Klauseln

Wenn du eine **einzige** Where-Klausel in deiner Abfrage nutzt, sind die Ergebnisse schon nach dem Index sortiert. Das ist eine große Sache!

Nehmen wir an, wir haben Schuhe in den Größen `[43, 39, 48, 40, 42, 45]` und wir wollen alle Schuhe mit einer Größe größer als `42` haben und sie auch nach Größe sortiert haben:

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // Sortiert die Ergebnisse auch nach Größe
  .findAll(); // -> [43, 45, 48]
```

Wie du sehen kannst, sind die Ergebnisse nach dem `size`-Index sortiert. Wenn du die Reihenfolge der Where-Klausel umkehren möchtest, kannst du `sort` auf `Sort.desc` setzen:

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

Manchmal willst du keine Where-Klausel verwenden, aber trotzdem von der impliziten Sortierung profitieren. Dann kannst du die Where-Klausel `any` verwenden:

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

Wenn du einen verbundenen Index verwendest, werden die Ergebnisse nach allen Feldern des Indexes sortiert.

:::tip
Für den Fall, dass deine Ergebnisse sortiert sein müssen, versuche einen Index zu benutzen. Besonders wenn du mit `offset()` oder `limit()` arbeitest:
:::

Manchmal ist es nicht möglich oder sinnvoll einen Index zur Sortierung zu nutzen. Für solche Fälle solltest du Indizes benutzen, um die Anzahl an zu sortierenden Einträgen so weit wie möglich zu verringern.

## Eindeutige Werte

Um nur Einträge mit eindeutigen Werten zurückzubekommen, kannst du das Unterscheidbarkeitsprädikat verwenden. Zum Beispiel, um herauszufinden, wie viele unterscheidbare Schuhmodelle es in deiner Isar-Datenbank gibt:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

Du kannst auch mehrere Unterscheidbarkeitsbedingungen verketten, um alle Schuhe mit unterscheidbaren Modell-Größe-Kombinationen zu finden:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

Nur das erste Ergebnis jeder Unterscheidbarkeitskombination wird zurückgegeben. Um das zu kontrollieren kannst du Where-Klauseln und Sortieroperationen verwenden.

### Unterscheidbare Where-Klauseln

Wenn du einen uneindeutigen Index hast, kann es sein, dass du alle seine unterscheidbaren Werte haben möchtest. Du könntest die `distinctBy`-Operation des vorherigen Abschnitts verwenden, aber sie wird erst nach dem Sortieren und Filtern angewandt, sodass ein bisschen Overhead entsteht.
Wenn du nur eine einzelne Where-Klausel verwendest, kannst du stattdessen dem Index vertrauen die Unterscheidbarkeitsoperation durchzuführen.

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
Theoretisch könntest du sogar mehrere Where-Klauseln für Sortierung und Unterscheidbarkeit nutzen. Die einzige Einschränkung besteht darin, dass sich diese Where-Klauseln nicht überschneiden und denselben Index verwenden dürfen.<!--Check if you should use 'same' or 'different' index, also fix for english docs-->
Für die richtige Sortierung müssen sie auch in Sortierreihenfolge angewandt werden. Sei sehr vorsichtig, wenn du dich darauf verlässt.
:::

## Offset & Limitierung

Es ist oft eine gute Idee die Anzahl an Ergebnissen einer Abfrage zu beschränken, für beispielsweise träge Listenansichten. Du kannst das bekommen, indem du ein `limit()` setzt:

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

Indem du ein `offset()` setzt, kannst du die Ergebnisse deiner Abfrage in mehrere Auflistungen aufteilen.

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

Weil das instanziieren eines Dart-Objekts meistens der teuerste Teil beim Ausführen einer Abfrage ist, ist es eine gute Idee nur die Objekte zu laden, die du benötigst.

## Reihenfolge der Ausführung

Isar führt Abfragen immer in der gleichen Reihenfolge aus:

1. Primär- oder Sekundärindex durchlaufen, um Objekte zu finden (Where-Klauseln anwenden)
2. Objekte filtern
3. Ergebnisse sortieren
4. Unterscheidbarkeitsoperation durchführen
5. Offset & Limit auf Ergebnisse anwenden
6. Ergebnisse zurückgeben

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
