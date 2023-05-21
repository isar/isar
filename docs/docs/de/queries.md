---
title: Abfragen
---

# Abfragen

Mit Abfragen kannst du Einträge finden, die bestimmten Bedingungen entsprechen, zum Beispiel:

- Finde alle markierten Kontakte
- Finde eindeutige Vornamen in den Kontakten
- Lösche alle Kontakte, die keinen Nachnamen definiert haben

Weil Abfragen nicht in Dart, sondern auf der Datenbank ausgeführt werden, sind sie sehr schnell. Wenn du Indizes sinnvoll benutzt, kannst du deine Abfrageleistung sogar weiter steigern. Als nächstes lernst du, wie man Abfragen schreibt und wie du sie so schnell wie möglich machen kannst.

Es gibt zwei verschiedene Methoden um Einträge zu filtern: Filter und Where-Klauseln. Wir beginnen indem wir uns die Funktionsweise von Filtern ansehen.

## Filter

Filter sind leicht zu benutzen und zu verstehen. Abhängig von den Typen deiner Eigenschaften gibt es verschiedene verfügbare Filteroperationen mit größtenteils selbsterklärenden Namen.

Filter funktionieren, indem sie einen Ausdruck für jedes Objekt der zu filternden Collection auswerten. Wenn der Ausdruck `true` ergibt, fügt Isar das Objekt zu den Ergebnissen hinzu.
Filter haben keinen Einfluss auf die Reihenfolge der Ergebnisse.

Wir benutzen das folgende Modell für die Beispiele weiter unten:

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

Nehmen wir an, dass die Datenbank vier Schuhe mit den Gößen 39, 40, 46 und einen mit einer nicht festgelegten Größe (`null`) hat. Wenn du keine Sortierung durchführst, werden die Werte nach ID geordnet zurückgegeben.

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

Du kannst Bedingungen verbinden, indem du die folgenden logischen Operatoren verwendest:

| Operator   | Beschreibung                                                                         |
| ---------- | ------------------------------------------------------------------------------------ |
| `.and()`   | Ergibt `true`, wenn von linkem und rechtem Ausdruck beide `true` ergeben.            |
| `.or()`    | Ergibt `true`, wenn mindestens einer von beiden Ausdrücken `true` ergibt.            |
| `.xor()`   | Ergibt `true`, wenn genau einer von beiden Ausdrücken `true` ergibt.                 |
| `.not()`   | Negiert das Ergebnis des nachfolgenden Ausdrucks.                                    |
| `.group()` | Gruppiert Bedingungen und ermöglicht es eine Reihenfolge der Auswertung festzulegen. |

Wenn du alle Schuhe mit der Größe 46 finden möchstest, kannst du die folgende Abfrage verwenden:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

Wenn du mehr als eine Bedingung angeben möchtest, kannst du mehrere Filter verbinden, indem du sie mit logischem **und** `.and()`, logischem **oder** `.or()` oder logischem **exklusiven oder** `.xor()` verbindest.

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // Optional. Filter werden implizit mit einem logischen UND verbunden.
  .isUnisexEqualTo(true)
  .findAll();
```

Diese Abfrage ist äquivalent zu: `size == 46 && isUnisex == true`.

Du kannst auch Bedingungen gruppieren, indem du `.group()` benutzt:

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

Zusätzlich zu den vorher genannten Abfragebedingungen, bieten String-Werte ein paar mehr Bedingungen. Platzhalter, ähnlich zu beispielsweise Regex, erlauben mehr Flexibilität beim Suchen.

| Bedingung            | Beschreibung                                                                   |
| -------------------- | ------------------------------------------------------------------------------ |
| `.startsWith(value)` | Trifft auf String-Werte zu, die mit dem angegebenen `value` beginnen.          |
| `.contains(value)`   | Trifft auf String-Werte zu, die das angegebene `value` enthalten.              |
| `.endsWith(value)`   | Trifft auf String-Werte zu, die mit dem angegebenen `value` enden.             |
| `.matches(wildcard)` | Trifft auf String-Werte zu, die dem angegebenen `wildcard`-Muster entsprechen. |

**Groß-/Kleinschreibung**  
Alle String-Operationen haben eine optionale `caseSensitive`-Eigenschaft, die standardmäßig `true` ist.

**Platzhalter**  
Der [Ausdruck eines Platzhalter-Strings](https://de.wikipedia.org/wiki/Wildcard_(Informatik)) ist ein String, der normale Zeichen mit zwei speziellen Platzhalter-Zeichen verwendet:

- Der `*` Platzhalter trifft auf keines oder mehr von jedem Zeichen zu.
- Der `?` Platzhalter trifft auf jedes Einzelzeichen zu.  
  Zum Beispiel trifft der Platzhalter-String `"d?g"` auf `"dog"`, `"dig"` und `"dug"` zu, nicht aber auf `"ding"`, `"dg"` oder `"a dog"`.

### Abfragemodifikatoren

Manchmal ist es notwendig eine Abfrage auf Bedingungen aufzubauen oder für verschiedene Werte zu bauen. Isar hat ein sehr mächtiges Werkzeug um bedingte Abfragen zu bauen:

| Modifikator           | Beschreibung                                                                                                                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.optional(cond, qb)` | Erweitert die Abfrage nur, wenn die Bedingung `cond`, `true` ist. Das kann fast überall in einer Abfrage verwendet werden, beispielsweise um sie über eine Bedingung zu sortieren oder begrenzen. |
| `.anyOf(list, qb)`    | Erweitert die Abfrage für jeden Wert in `values` und verbindet die Bedingungen mit einem logischen **oder**.                                                                                      |
| `.allOf(list, qb)`    | Erweitert die Abfrage für jeden Wert in `values` und verbindet die Bedingungen mit einem logischen **und**.                                                                                       |

In diesem Beispiel bauen wir eine Methode, die Schuhe mit einem optionale Filter finden kann:

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // Wendet den Filter nur an, wenn sizeFilter != null ist
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

Wenn du alle Schuhe finden möchtest, die eine von mehreren Schuhgrößen haben, kannst du entweder eine konventionelle Abfrage schreiben oder den `anyOf()` Modifikator verwenden:

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

Diese sind äquivalent zu dem Dart-Code `tweets.where((t) => t.hashtags.isEmpty);` und `tweets.where((t) => t.hashtags.length > 5);`. Du kannst auch Abfragen basierend auf Listenelementen stellen:

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

Das ist äquivalent zum Dart-Code `tweets.where((t) => t.hashtags.contains('flutter'));`.

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

Wir wollen alle Autos abfragen, die eine Marke mit dem Namen `"BMW"` und dem Land `"Germany"` haben. Wir können das mit der folgenden Abfrage erreichen:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

Versuche immer verschachtelte Abfragen zu gruppieren. Die vorherige Abfrage ist effizienter als die folgende, auch wenn das Ergebnis gleich ist:

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

Link-Filter resultieren in `true`, wenn mindestens eines der verlinkten Objekte den Bedingungen entspricht.

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

Im Gegensatz zu Filtern nutzen Where-Klauseln die Indizes, die du im Schema definiert hast, um die Abfragebedingungen zu überprüfen. Einen Index abzufragen ist deutlich schneller als jeden Eintrag einzeln zu filtern.

➡️ Lerne mehr: [Indizes](indexes)

:::tip
Als eine einfache Regel solltest du immer versuchen die Einträge so weit wie möglich mit Where-Klauseln einzugrenzen und das restliche Filtern mit Filtern machen.
:::

Du kannst Where-Klauseln nur mit logischem **oder** verbinden. In anderen Worten, kannst du mehrere Where-Klauseln zusammenfügen, aber nicht die Überschneidung mehrerer Where-Klauseln abfragen.

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

Hier gibt es zwei Indizes. Der Index auf `size` erlaubt es uns Where-Klauseln wie `.sizeEqualTo()` zu verwenden. Der zusammengesetzte Index auf `isUnisex` erlaubt es uns Where-Klauseln wie `.isUnisexSizeEqualTo()` zu nutzen. Aber auch `.isUnisexEqualTo()` ist möglich, weil du immer jedes Präfix eines Indexes benutzen kannst.

Wir können unsere Abfrage von vorher, die Unisex-Schuhe der Größe 46 findet, also mithilfe des zusammengesetzten Indexes umschreiben. Diese Abfrage sollte deutlich schneller sein, als die vorherige:

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

Die Where-Klausel wird zuerst angewendet, um die Anzahl an Objekten, die gefiltert werden müssen, zu reduzieren. Dann wird der Filter auf die übrig gebliebenen Objekte angewendet.

## Sortierung

Du kannst definieren, wie Ergebnisse deiner Abfrage sortiert werden sollen, indem du die Methoden `.sortBy()`, `.sortByDesc()`, `.thenBy()` und `.thenByDesc()` nutzt.

Um alle Schuhe nach Modellnamen in aufsteigender und nach der Größe in absteigender Reihenfolge sortiert zu bekommen, ohne einen Index zu benutzen, aknnst du die folgende Abfrage stellen:

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

Wenn du einen Komposit-Index verwendest, werden die Ergebnisse nach allen Feldern des Indexes sortiert.

:::tip
Für den Fall, dass deine Ergebnisse sortiert sein müssen, versuche einen Index zu benutzen. Besonders wenn du mit `offset()` oder `limit()` arbeitest:
:::

Manchmal ist es nicht möglich oder sinnvoll einen Index zum Sortieren zu nutzen. Für solche Fälle solltest du Indizes benutzen, um zumindest die Anzahl an zu sortierenden Einträgen so weit wie möglich einzugrenzen.

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

Nur das erste Ergebnis jeder Unterscheidbarkeitskombination wird zurückgegeben. Um das zu überprüfen kannst du Where-Klauseln und Sortieroperationen verwenden.

### Unterscheidbare Where-Klauseln

Wenn du einen nicht eindeutigen Index hast, kann es sein, dass du alle seine unterscheidbaren Werte haben möchtest. Du könntest die `distinctBy`-Operation des vorherigen Abschnitts verwenden, aber sie wird erst nach dem Sortieren und Filtern angewandt, sodass ein bisschen Overhead entsteht.
Wenn du nur eine einzelne Where-Klausel verwendest, kannst du stattdessen dem Index vertrauen die Unterscheidbarkeitsoperation durchzuführen.

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
Theoretisch könntest du sogar mehrere Where-Klauseln für Sortierung und Unterscheidbarkeit nutzen. Die einzige Einschränkung besteht darin, dass sich diese Where-Klauseln nicht überschneiden, also nicht denselben Index verwenden dürfen. Für die richtige Sortierung müssen sie auch in Sortierreihenfolge angewandt werden. Sei sehr vorsichtig, wenn du dich darauf verlässt.
:::

## Offset & Limitierung

Es ist oft eine gute Idee die Anzahl an Ergebnissen einer Abfrage zu beschränken, für beispielsweise lazy Listenansichten. Du kannst das erreichen, indem du ein `limit()` setzt:

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

## Abfrageoperationen

In den vorangegangenen Beispielen haben wir `.findAll()` verwendet, um alle passenden Objekte zu erhalten. Es sind jedoch mehr Operationen verfügbar:

| Operation        | Beschreibung                                                                                                                                           |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `.findFirst()`   | Erhalte nur das erste passende Objekt oder `null` wenn kein passendes gefunden wird.                                                                   |
| `.findAll()`     | Erhalte alle passenden Objekte.                                                                                                                        |
| `.count()`       | Zählt, wieviele Objekte der Abfrage entsprechen.                                                                                                       |
| `.deleteFirst()` | Löscht das erste passende Objekt aus der Collection.                                                                                                   |
| `.deleteAll()`   | Löscht alle passenden Objekte aus der Collection.                                                                                                      |
| `.build()`       | Konstruiert eine Abfrage um sie später wiederzuverwenden. Das erspart die Kosten, eine Abfrage erneut zu bauen, wenn du sie mehrfach ausführen willst. |

## Abfragen auf Eigenschaften

Wenn du nur an den Werten einer bestimmten Eigenschaft interessiert bist, kannst du Abfragen auf Eigenschaften machen. Baue einfach eine normale Abfrage und wähle eine Eigenschaft:

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

Nur eine einzige Eigenschaft zu nutzen erspart Zeit bei der Deserialisierung. Abfragen auf Eigenschaften funktionieren auch bei eingebetteten Objekten und Listen.

## Aggregation

Isar unterstützt die Aggregation der Werte einer Abfrage auf Eigenschaften. Die folgenden Aggregatoroperationen sind verfügbar:

| Operation    | Beschreibung                                                         |
| ------------ | -------------------------------------------------------------------- |
| `.min()`     | Findet den minimalen Wert oder `null`, wenn keiner passt.            |
| `.max()`     | Findet den maximalen Wert oder `null`, wenn keiner passt.            |
| `.sum()`     | Addiert alle Werte.                                                  |
| `.average()` | Berechnet den Durchschnitt aller Werte oder `NaN` wenn keiner passt. |

Aggregatoren zu nutzen ist deutlich schneller, als alle passenden Objekte zu finden und die Aggregation manuell durchzuführen.

## Dynamische Abfragen

:::danger
Dieser Abschnitt ist höchstwahrscheinlich nicht wichtig für dich. Es ist davon abzuraten dynamische Abfragen zu nutzen, es sei denn du benötigst sie wirklich (was selten vorkommt).
:::

Alle der vorherigen Beispiele haben den QueryBuilder und seine statischen Erweiterungsmethoden genutzt. Vielleicht möchtest du dynamische Abfragen oder eine benutzerdefinierte Abfragesprache (wie den Isar Inspektor) bauen. In dem Fall kannst du die Methode `buildQuery()` verwenden:

| Parameter       | Beschreibung                                                                                               |
| --------------- | ---------------------------------------------------------------------------------------------------------- |
| `whereClauses`  | Die Where-Klauseln der Abfrage.                                                                            |
| `whereDistinct` | Ob Where-Klauseln nur unterscheidbare Werte zurückgeben sollen (nur sinnvoll für einzelne Where-Klauseln). |
| `whereSort`     | Die Durchlaufreihenfolge der Where-Klauseln (nur sinnvoll für einzelne Where-Klauseln).                    |
| `filter`        | Die Filter, die auf die Ergebnisse angewendet werden sollen.                                               |
| `sortBy`        | Eine Liste an Eigenschaften nach denen sortiert werden soll.                                               |
| `distinctBy`    | Eine Liste an Eigenschaften, an denen die Unterscheidbarkeit festgemacht wird.                             |
| `offset`        | Der Offset der Ergebnisse.                                                                                 |
| `limit`         | Die maximale Anzahl an Ergebnissen, die zurückgegeben werden.                                              |
| `property`      | Wenn nicht-null, werden nur die Werte dieser Eigenschaft zurückgegeben.                                    |

Bauen wir eine dynamische Abfrage:

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

Die folgende Abfrage ist äquivalent:

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
