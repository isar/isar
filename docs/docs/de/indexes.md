---
title: Indizes
---

# Indizes

Indizes sind Isars mächtigstes Feature. Viele eingebettete Datenbanken bieten "normale" Indizes (wenn überhaupt), aber Isar hat auch Komposit- und Mehrfach-Indizes. Zu verstehen, wie Indizes funktionieren ist grundlegend um die Abfrageleistung zu optimieren. Isar lässt dich wählen welchen Index du verwenden möchtest und wie du ihn benutzen willst. Wir beginnen mit einer schnellen Einführung was Indizes sind.

## Was sind Indizes?

Wenn eine Collection nicht indiziert ist, wird die Reihenfolge der Zeilen von der Abfrage aus sicherlich nicht als in irgendeiner Weise optimiert erkennbar sein. Daher muss die Abfrage linear alle Objekte durchsuchen. In anderen Worten, die Abfrage muss alle Objekte durchsuchen, um diejenigen zu finden, die zu den Bedingungen passen. Wie du dir bestimmt vorstellen kannst, kann das seine Zeit dauern. Durch jedes einzelne Objekt zu gucken ist nicht sehr effizient.

Zum Beispiel ist diese `Product`-Collection komplett unsortiert.

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

**Daten:**

| id  | name      | price |
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

Eine Abfrage, die versucht alle Produkte zu finden, die mehr als 30€ kosten, muss alle neun Zeilen durchsuchen. Das ist kein Problem für nur neun Zeilen, aber könnte ein Problem für 100k Zeilen werden.

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

Um die Leistung dieser Abfrage zu verbessern, indizieren wir die Eigenschaft `price`. Ein Index ist wie eine sortierte Nachschlagetabelle.

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

**Generierter Index:**

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

Jetzt kann die Abfrage deutlich schneller durchgeführt werden. Es kann direkt zu den letzten drei Indexzeilen gesprungen werden und die entsprechenden Objekte anhand ihrer ID gefunden werden.

### Sortierung

Eine andere coole Sache: Indizes können superschnell sortieren. Sortierte Abfragen sind kostenintensiv, weil die Datenbank alle Ergebnisse in den Speicher laden muss, bevor sie sortiert werden. Sogar wenn du einen Offset oder eine Limitierung angibst, werden diese erst nach dem Sortieren angewandt.

Stell dir vor, wir wollten die vier günstigsten Produkte finden. Wir könnten die folgende Abfrage verwenden:

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

In diesem Beispiel müsste die Datenbank alle (!) Objekte laden, sie nach dem Preis sortieren und die vier Produkte mit dem niedrigsten Preis zurückgeben.

Wie du dir vermutlich vorstellen kannst, kann das mit dem vorherigen Index sehr viel effizienter gemacht werden. Die Datenbank nimmt die ersten vier Zeilen des Indexes und gibt die zugehörigen Objekte zurück, da sie schon in der korrekten Reihenfolge sind.

Um einen Index zum Sortieren zu verwenden würden wir die Abfrage so schreiben:

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

Die `.anyX()` Where-Klausel teilt Isar mit, einen Index nur zum Sortieren zu verwenden. Du kannst also eine Where-Klausel wie `.priceGreaterThan()` benutzen und sortierte Ergenisse erhalten.

## Eindeutige Indizes

Ein eindeutiger Index stellt sicher, dass der Index keine doppelten Werte enthält. Er kann aus einem oder mehreren Eigenschaften bestehen. Wenn ein eindeutiger Index eine Eigenschaft hat, sind die Werte dieser Eigenschaft eindeutig. Wenn ein eindeutiger Index mehr als eine Eigenschaft hat, dann ist die Kombination der Werte dieser Eigenschaften eindeutig.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

Jeder Versuch Daten in einen eindeutigen Index einzufügen oder zu aktualisieren, die ein Dukplikat verursachen würden, resultieren in einem Fehler:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> Ok

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

// Versucht einen Benutzer mit dem gleichen Benutzernamen einzufügen
await isar.users.put(user2); // -> Fehler: Eindeutigkeitsbeschränkung verletzt
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## Indizes ersetzen

Manchmal ist es nicht von Vorteil einen Fehler zu verursachen, wenn eine Eindeutigkeitsbeschränkung verletzt wird. Stattdessen möchtest du vielleicht das vorhandene Objekt mit dem Neuen ersetzen. Das kann erreicht werden, indem die Eigenschaft `replace` des Indexes auf `true` gesetzt wird.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

Jetzt, wenn wir versuchen einen Benutzer mit einem vorhandenen Benutzernamen einzufügen, wird Isar den Vorhandenen mit dem neuen Benutzer ersetzen.

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

Ersetzbare Indizes generieren auch `putBy()`-Methoden, die es dir ermöglichen Objekte zu aktualisieren statt sie zu ersetzen. Die vorhandene ID wird wiederverwendet und Links bleiben erhalten.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// Nutzer existiert nicht, also ist es das gleiche wie put()
await isar.users.putByUsername(user1);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

Wie du sehen kannst, wird die ID des zuerst eingefügten Benutzers wiederverwendet.

## Indizes ohne Berücksichtigung auf Groß-/Kleinschreibung

Alle Indizes auf `String`- und `List<String>`-Eigenschaften beachten standardmäßig die Groß-/Kleinschreibung. Wenn du einen Index erstellen willst, der die Groß-/Kleinschreibung nicht berücksichtigt, kannst du die `caseSensitive`-Option verwenden:

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

## Index-Typen

Es gibt verschiedene Typen von Indizes. Meistens wirst du einen `IndexType.value`-Index verwenden wollen, aber Hash-Indizes sind effizienter.

### Wert-Index

Wert-Indizes sind der Standardtyp und der Einzige, der für alle Eigenschaften erlaubt ist, die nicht Strings oder Listen enthalten. Eigenschaftswerte werden verwendet, um den Index zu erstellen. Im Fall von Listen, werden die Elemente der Liste verwendet. Es ist der flexibelste, aber auch platzraubendste der drei Index-Typen.

:::tip
Benutze `IndexType.value` für Primitives, Strings, wenn du `startsWith()`-Where-Klauseln brauchst, und Listen, wenn du nach einzelnen Elementen suchst.
:::

### Hash-Index

Strings und Listen können gehasht werden um den für den Index benötigten Speicher drastisch zu verringern. Der Nachteil eines Hash-Indexes ist, dass sie nicht für Präfixsuchen (`startsWith()`-Where-Klauseln) verwendet werden können.

:::tip
Verwende `IndexType.hash` für Strings und Listen, wenn du die `startsWith`- und `elementEqualTo`-Where-Klauseln nicht benötigst.
:::

### HashElements-Index

Stringlisten können als Ganzes gehasht werden (indem man `IndexType.hash` verwendet) oder die Elemente der Liste können seperat gehasht werden (indem man `IndexType.hashElements` nutzt) wodurch ein Mehreintragsindex mit gehashten Elementen erzeugt wird.

:::tip
Nutze `IndexType.hashElements` für `List<String>` bei denen du `elementEqualTo`-Where-Klauseln benötigst.
:::

## Komposit-Indizes

Ein Komposit-Index ist ein Index auf mehrere Eigenschaften. Isar erlaubt es dir zusammengesetzte Indizes mit bis zu drei Eigenschaften zu erstellen.

Komposit-Indizes sind auch als Mehr-Spalten-Indizes bekannt.

Es ist vermutlich am besten mit einem Beispiel zu starten. Wir erstellen eine Personen-Collection und definieren einen zusammengesetzten Index auf die Alters- und Namenseigenschaften:

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

**Daten:**

| id  | name   | age | hometown  |
| --- | ------ | --- | --------- |
| 1   | Daniel | 20  | Berlin    |
| 2   | Anne   | 20  | Paris     |
| 3   | Carl   | 24  | San Diego |
| 4   | Simon  | 24  | Munich    |
| 5   | David  | 20  | New York  |
| 6   | Carl   | 24  | London    |
| 7   | Audrey | 30  | Prague    |
| 8   | Anne   | 24  | Paris     |

**Generierter Index:**

| age | name   | id  |
| --- | ------ | --- |
| 20  | Anne   | 2   |
| 20  | Daniel | 1   |
| 20  | David  | 5   |
| 24  | Anne   | 8   |
| 24  | Carl   | 3   |
| 24  | Carl   | 6   |
| 24  | Simon  | 4   |
| 30  | Audrey | 7   |

Der generierte zusammengesetzte Index enthält alle Personen sortiert nach ihrem Alter und ihrem Namen.

Komposit-Indizes sind super, wenn du effiziente Abfragen, sortiert nach mehreren Eigenschaften, stellen willst. Sie erlauben auch anspruchsvolle Where-Klauseln mit mehreren Eigenschaften:

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

Die letzte Eigenschaft eines zusammengesetzten Index unterstützt auch Bedingungen wie `startsWith()` oder `lessThan()`:

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## Mehrfach-Indizes

Wenn du eine Liste mit `IndexType.value` indizierst, wird Isar automatische einen Mehrfach-Index erzeugen und jeder Eintrag in der Liste wird mit dem Objekt indiziert. Das funktioniert für alle Listentypen.

Zu sinnvollen Anwendungen für Mehrfach-Indizes zählen das Indizieren einer Liste an Tags oder einen Volltext-Index zu erstellen.

```dart
@collection
class Product {
  Id? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` trennt einen String nach der [Unicode Annex #29](https://unicode.org/reports/tr29/)-Spezifikation in Worte, sodass es für fast alle Sprachen richtig funktioniert.

**Daten:**

| id  | description                  | descriptionWords             |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

Einträge mit doppelten Worten tauchen nur einmal im Index auf.

**Generierter Index:**

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

Dieser Index kann nun für (Gleichheits- oder) Präfix-Where-Klauseln der individuellen Worte der Beschreibung verwendet werden.

:::tip
Statt Worte direkt zu speichern kannst du auch in Betracht ziehen das Ergebnis einer [Phonetischen Suche](https://de.wikipedia.org/wiki/Phonetische_Suche) wie von dem Algorithmus [Soundex](https://de.wikipedia.org/wiki/Soundex) zu verwenden.
:::
