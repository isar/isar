---
title: Schema
---

# Schema

Wenn du Isar benutzt, um deine App-Daten zu speichern, dann hast du mit Ansammlungen zu tun. Eine Ansammlung ist wie die Tabelle einer Datenbank in der angeschlossenen Isar Datenbank und kann nur einen einzigen Typen von Dart Objekt enthalten. Jedes Ansammlungs-Objekt repräsentiert eine Zeile mit Daten in der zugehörigen Ansammlung.

Die Definition einer Ansammlung wird "Schema" genannt. Der Isar-Generator macht die meiste Arbeit für dich und generiert den Großteil des Codes den du benötigst, um die Ansammlung zu benutzen.

## Aufbau einer Ansammlung

Jede Ansammlung in Isar wird über die Anmerkung `@collection` oder `@Collection()` an einer Klasse definiert. Eine Isar-Ansammlung enthält Felder für jede Spalte in der zugehörigen Tabelle der Datenbank, auch eine, die dem Primär-Schlüssel entspricht.

Der folgende Code ist ein Beispiel einer simplen Ansammlung, welche eine `User`-Tabelle mit den Spalten ID, Vorname und Nachname definiert:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
Um ein Feld persistent zu machen, muss Isar Zugriff auf das Feld haben. Du kannst sicherstellen, dass Isar Zugriff auf ein Feld hat, indem du es öffentlich machst, oder indem du Getter- und Setter-Methoden definierst.
:::

Es gibt ein paar optionale Parameter, um die Ansammlung anzupassen:

| Konfiguration | Beschreibung                                                                                                                  |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Steuert, ob Felder von Elternklassen und Mixins in Isar gespeichert werden. Standardmäßig aktiviert.                          |
| `accessor`    | Erlaubt dir den Standard des Ansammlungszugriffs umzubenennen (zum Beispiel zu `isar.contacts` für die `Contact`-Ansammlung). |
| `ignore`      | Erlaubt es bestimmte Eigenschaften zu ignorieren. Diese werden auch bei Super-Klassen angewendet.                             |

### Isar ID

Jede Ansammlungs-Klasse muss eine ID-Eigenschaft vom Typen `Id` definieren, die ein Objekt eindeutig identifiziert. `Id` ist eigentlich nur ein Alias für `int`, der es dem Isar Generator ermöglicht die ID-Eigenschaft zu erkennen.

Isar indiziert ID Felder automatisch, was dir ermöglicht Objekte effizient anhand ihrer ID zu erhalten und modifizieren.

Du kannst eintweder IDs selbst zuweisen oder Isar fragen eine sich automatisch erhöhende ID festzulegen. Wenn das `id`-Feld `null` und nicht `final` ist, wird Isar eine sich automatisch inkrementierende ID setzen. Wenn du eine nicht null-bare automatisch inrementierende ID haben möchtest, kannst du `Isar.autoIncrement` anstatt von `null` verwenden.

:::tip
Automatisch inkrementierende IDs werden nicht wiederverwendet, wenn ein Objekt gelöscht wird. Der einzige Weg automatisch-inkrementierende IDs zurückzusetzen ist die Datenbank zu leeren.
:::

### Ansammlungen und Felder umbenennen

Isar benutzt standardmäßig den Klassennamen als Ansammlungsnamen. Genauso verwendet Isar in der Datenbank Feldnamen als Spaltennamen. Wenn du willst, dass eine Ansamlung oder ein Feld einen anderen Namen hat, dann füge die Anmerkung `@Name` hinzu. Das folgende Beispiel demonstriert angepasste Namen für Ansammlungen und Felder:

```dart
@collection
@Name("User")
class MyUserClass1 {

  @Name("id")
  Id myObjectId;

  @Name("firstName")
  String theFirstName;

  @Name("lastName")
  String familyNameOrWhatever;
}
```

Du solltest besonders dann, wenn du Dart Felder oder Klassen umbenennen willst, überlegen die `@Name`-Anmerkung zu verwenden. Sonst wird die Datenbank das Feld oder die Ansammlung löschen und neu erzeugen.

### Felder ignorieren

Isar sichert/erhält alle öffentlichen Felder einer Ansammlungs-Klasse. Wenn du eine Eigenschaft oder einen Getter mit `@ignore` markierst, kannst du diese von der Sicherung ausschließen, wie im folgenden Code-Schnipsel gezeigt:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;

  @ignore
  String? password;
}
```

In Fällen, in denen die Ansammlung Felder von der Elternansammlung erhält, ist es meist leichter die `ignore`-Eigenschaft der `@Collection`-Anmerkung zu verwenden:

```dart
@collection
class User {
  Image? profilePicture;
}

@Collection(ignore: {'profilePicture'})
class Member extends User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

Wenn eine Ansammlung ein Feld mit einem Typen enthält, der nicht von Isar unterstützt wird, musst du das Feld ignorieren.

:::warning
Beachte, dass es keine gute Vorgehensweise ist, Informationen in Isar-Objekten zu speichern, die nicht erhalten bleiben.
:::

## Unterstützte Typen

Isar unterstützt die folgenden Datentypen:

- `bool`
- `byte`
- `short`
- `int`
- `float`
- `double`
- `DateTime`
- `String`
- `List<bool>`
- `List<byte>`
- `List<short>`
- `List<int>`
- `List<float>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

Zusätzlich sind eingebettete Objekte und Enums unterstützt. Wir behandeln diese weiter unten.

## byte, short, float

In vielen Fällen benötigst du nicht den gesamten Bereich eines 64-bit Integers oder Doubles. Isar unterstützt zusätzliche Typen, die es dir erlauben Speicher beim speichern kleinerer Zahlen zu sparen.

| Typ        | Größe in bytes | Bereich                                                  |
| ---------- | -------------- | -------------------------------------------------------- |
| **byte**   | 1              | 0 bis 255                                                |
| **short**  | 4              | -2.147.483.647 bis 2.147.483.647                         |
| **int**    | 8              | -9.223.372.036.854.775.807 bis 9.223.372.036.854.775.807 |
| **float**  | 4              | -3,4e38 bis 3,4e38                                       |
| **double** | 8              | -1,7e308 bis 1,7e308                                     |

Die zusätzlichen Zahl-Typen sind nur Aliase für die nativen Dart-Typen, also beispielsweise `short` zu benutzen funktioniert genauso wie wenn du `int` nutzen würdest.

Hier ist eine Beispiel-Ansammlung, welche alle der eben genannten Typen enthält:

```dart
@collection
class TestCollection {
  Id? id;

  late byte byteValue;

  short? shortValue;

  int? intValue;

  float? floatValue;

  double? doubleValue;
}
```

Alle Zahlen-Typen können auch in Listen verwendet werden. Um Bytes zu speichern solltest du `List<byte>` benutzen.

## Null-bare Typen

Zu verstehen wie Null-barkeit in Isar funktioniert ist essentiell: Zahl-typen haben keine bestimmte `null`-Darstellung. Stattdessen wird ein bestimmter Wert genutzt:

| Typ        | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    | `int.MIN`     |
| **float**  | `double.NaN`  |
| **double** | `double.NaN`  |

`bool`, `String`, und `List`  haben eine seperate `null`-Darstellung.

Dieses Verhalten erlaubt Leistungsverbesserungen, und ermöglicht es die Null-narkeit deiner Felder frei zu ändern, ohne eine Migration oder speziellen Code zum handhaben von `null`-Werten zu benötigen.

:::warning
Der `byte`-Typ unterstützt keine Null-Werte.
:::

## DateTime

Isar speichert keine Zeitzoneninformationen von deinen Daten. Stattdessen wandelt es `DateTime`s zu UTC um, bervor es diese speichert. Isar gibt alle Daten in lokaler Zeit zurück.

`DateTime`s werden mit Mikrosekunden-Präzision gespeichert. In Browsern ist, aufgrund von JavaScript-Limitationen, nur Millisekunden-Präzision möglich.

## Enum

Isar allows storing and using enums like other Isar types. You have to choose, however, how Isar should represent the enum on the disk. Isar supports four different strategies:

| EnumType    | Description                                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------- |
| `ordinal`   | The index of the enum is stored as `byte`. This is very efficient but does not allow nullable enums |
| `ordinal32` | The index of the enum is stored as `short` (4-byte integer).                                        |
| `name`      | The enum name is stored as `String`.                                                                |
| `value`     | A custom property is used to retrieve the enum value.                                               |

:::warning
`ordinal` and `ordinal32` depend on the order of the enum values. If you change the order, existing databases will return incorrect values.
:::

Let's check out an example for each strategy.

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // same as EnumType.ordinal
  late TestEnum byteIndex; // cannot be nullable

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // cannot be nullable

  @Enumerated(EnumType.ordinal32)
  TestEnum? shortIndex;

  @Enumerated(EnumType.name)
  TestEnum? name;

  @Enumerated(EnumType.value, 'myValue')
  TestEnum? myValue;
}

enum TestEnum {
  first(10),
  second(100),
  third(1000);

  const TestEnum(this.myValue);

  final short myValue;
}
```

Of course, Enums can also be used in lists.

## Embedded objects

It's often helpful to have nested objects in your collection model. There is no limit to how deep you can nest objects. Keep in mind, however, that updating a deeply nested object will require writing the whole object tree to the database.

```dart
@collection
class Email {
  Id? id;

  String? title;

  Recepient? recipient;
}

@embedded
class Recepient {
  String? name;

  String? address;
}
```

Embedded objects can be nullable and extend other objects. The only requirement is that they are annotated with `@embedded` and have a default constructor without required parameters.
