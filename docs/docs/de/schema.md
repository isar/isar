---
title: Schema
---

# Schema

Wenn du Isar benutzt, um deine App-Daten zu speichern, dann hast du mit Collections zu tun. Eine Collection ist wie die Tabelle einer Datenbank in der angeschlossenen Isar-Datenbank und kann nur einen einzigen Typen von Dart Objekt enthalten. Jedes Collection-Objekt repräsentiert eine Zeile mit Daten in der zugehörigen Collection.

Die Definition einer Collection wird "Schema" genannt. Der Isar-Generator macht die meiste Arbeit für dich und generiert den Großteil des Codes den du benötigst, um die Collection zu benutzen.

## Aufbau einer Collection

Jede Collection in Isar wird über die Annotation `@collection` oder `@Collection()` an einer Klasse definiert. Eine Isar-Collection enthält Felder für jede Spalte in der zugehörigen Tabelle der Datenbank, auch eine, die dem Primärschlüssel entspricht.

Der folgende Code ist ein Beispiel einer simplen Collection, welche eine `User`-Tabelle mit den Spalten ID, Vorname und Nachname definiert:

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

Es gibt ein paar optionale Parameter, um die Collection anzupassen:

| Konfiguration | Beschreibung                                                                                                                        |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Steuert, ob Felder von Elternklassen und Mixins in Isar gespeichert werden. Standardmäßig aktiviert.                                |
| `accessor`    | Erlaubt dir den Standardnamen des Collection-Accessors umzubenennen (zum Beispiel zu `isar.contacts` für die `Contact`-Collection). |
| `ignore`      | Erlaubt es bestimmte Eigenschaften zu ignorieren. Diese werden auch bei Superklassen angewendet.                                    |

### Isar ID

Jede Collection-Klasse muss eine ID-Eigenschaft vom Typen `Id` definieren, die ein Objekt eindeutig identifiziert. `Id` ist eigentlich nur ein Alias für `int`, der es dem Isar Generator ermöglicht die ID-Eigenschaft zu erkennen.

Isar indiziert ID Felder automatisch, was dir ermöglicht Objekte effizient anhand ihrer ID zu erhalten und modifizieren.

Du kannst eintweder IDs selbst zuweisen oder Isar fragen eine sich automatisch erhöhende ID festzulegen. Wenn das `id`-Feld `null` und nicht `final` ist, wird Isar eine auto-increment ID setzen. Wenn du eine nicht null-bare auto-increment ID haben möchtest, kannst du `Isar.autoIncrement` anstatt von `null` verwenden.

:::tip
Auto-increment IDs werden nicht wiederverwendet, wenn ein Objekt gelöscht wird. Der einzige Weg auto-increment IDs zurückzusetzen ist die Datenbank zu leeren.
:::

### Collections und Felder umbenennen

Isar benutzt standardmäßig den Klassennamen als Collectionnamen. Genauso verwendet Isar in der Datenbank Feldnamen als Spaltennamen. Wenn du willst, dass eine Collection oder ein Feld einen anderen Namen hat, dann füge die Annotation `@Name` hinzu. Das folgende Beispiel demonstriert angepasste Namen für Collections und Felder:

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

Du solltest besonders dann, wenn du Dart-Felder oder -Klassen umbenennen willst, überlegen, die `@Name`-Annotation zu verwenden. Sonst wird die Datenbank das Feld oder die Collection löschen und neu erzeugen.

### Felder ignorieren

Isar stell sicher, dass alle öffentlichen Felder einer Collecion-Klasse erhalten bleiben. Wenn du eine Eigenschaft oder einen Getter mit `@ignore` annotierst, kannst du diese von der Sicherstellung ausschließen, wie im folgenden Code-Schnipsel gezeigt:

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

In Fällen, in denen deine Collection Felder von der Eltern-Collection erhält, ist es meist leichter die `ignore`-Eigenschaft der `@Collection`-Annotation zu verwenden:

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

Wenn eine Collection ein Feld mit einem Typen enthält, der nicht von Isar unterstützt wird, musst du das Feld ignorieren.

:::warning
Beachte, dass es keine gute Vorgehensweise ist, Informationen in Isar-Objekten zu speichern, die nicht gesichert werden.
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

In vielen Fällen benötigst du nicht den gesamten Bereich eines 64-bit Integers oder Doubles. Isar unterstützt zusätzliche Typen, die es dir erlauben Speicherpaltz beim Speichern kleinerer Zahlen zu sparen.

| Typ        | Größe in bytes | Bereich                                                  |
| ---------- | -------------- | -------------------------------------------------------- |
| **byte**   | 1              | 0 bis 255                                                |
| **short**  | 4              | -2.147.483.647 bis 2.147.483.647                         |
| **int**    | 8              | -9.223.372.036.854.775.807 bis 9.223.372.036.854.775.807 |
| **float**  | 4              | -3,4e38 bis 3,4e38                                       |
| **double** | 8              | -1,7e308 bis 1,7e308                                     |

Die zusätzlichen Zahl-Typen sind nur Aliase für die nativen Dart-Typen, also beispielsweise `short` zu benutzen funktioniert genau, wie wenn du `int` nutzen würdest.

Hier ist eine Beispiel-Collection, welche alle der eben genannten Typen enthält:

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

Zu verstehen wie Null-barkeit in Isar funktioniert ist essentiell: Zahlen-Typen haben **KEINE** gemeinsame festgelegte `null`-Darstellung. Stattdessen wird ein bestimmter Wert genutzt:

| Typ        | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    | `int.MIN`     |
| **float**  | `double.NaN`  |
| **double** | `double.NaN`  |

`bool`, `String`, und `List` haben eine seperate `null`-Darstellung.

Dieses Verhalten erlaubt Leistungsverbesserungen, und ermöglicht es die Null-barkeit deiner Felder frei zu ändern, ohne eine Migration oder speziellen Code zum handhaben von `null`-Werten zu benötigen.

:::warning
Der `byte`-Typ unterstützt keine Null-Werte.
:::

## DateTime

Isar speichert keine Zeitzoneninformationen von deinen Daten. Stattdessen wandelt es `DateTime`s zu UTC um, bervor es diese speichert. Isar gibt jedes Datum in lokaler Zeit zurück.

`DateTime`s werden mit Mikrosekunden-Präzision gespeichert. In Browsern ist, aufgrund von JavaScript-Limitationen, nur Millisekunden-Präzision möglich.

## Enum

Isar ermöglicht es Enums wie andere Isar-Typen zu nutzen und zu speichern. Du musst aber wählen, wie Isar den Enum auf dem Datenträger abbilden soll. Isar unterstützt vier verschiedene Strategien:

| Enum-Typ     | Beschreibung                                                                                                   |
| ------------ | -------------------------------------------------------------------------------------------------------------- |
| `ordinal`    | Der Index des Enums wird als `byte` gespeichert. Das ist sehr effizienzt, aber erlaubt keine Null-baren Enums. |
| `ordinal32`  | Der Index des Enums wird als `short` (4-Byte-Integer) gespeichert. Erlaubt keine Null-baren Enums.             |
| `name`       | Der Name des Enums wird als `String` gespeichert.                                                              |
| `value`      | Eine angepasste Eigenschaft wird genutzt, um den Enum-Wert abzurufen.                                          |

:::warning
`ordinal` und `ordinal32` basieren auf der Reihenfolge der Enum-Werte. Wenn du die Reihenfolge änderst, werden existierende Datenbanken falsche Werte zurückgeben.
:::

Schauen wir uns ein Beispiel für jede Strategie an.

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // entspricht EnumType.ordinal
  late TestEnum byteIndex; // ist nicht Null-bar

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // ist nicht Null-bar

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

Natürlich können Enums auch in Listen benutzt werden.

## Eingebettete Objekte

Es ist oft hilfreich verschachtelte Objekte in deinem Collection-Modell zu haben. Daher gibt es keine Begrenzung, wie tief die Verschachtelung von Objekten sein kann. Beachte jedoch, dass der gesamte Objekt-Baum in die Datenbank geschrieben werden muss, um ein sehr tief verschachteltes Objekt zu aktualisieren.

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

Eingebettete Objekte können Null-bar sein und andere Objekte erweitern. Die einzige Voraussetzung ist, dass sie mit `@embedded` annotiert werden und einen Standardkonstruktor ohne erforderliche Parameter haben.
