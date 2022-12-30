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

### Renaming collections and fields

By default, Isar uses the class name as the collection name. Similarly, Isar uses field names as column names in the database. If you want a collection or field to have a different name, add the `@Name` annotation. The following example demonstrates custom names for collection and fields:

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

Especially if you want to rename Dart fields or classes that are already stored in the database, you should consider using the `@Name` annotation. Otherwise, the database will delete and re-create the field or collection.

### Ignoring fields

Isar persists all public fields of a collection class. By annotating a property or getter with `@ignore`, you can exclude it from persistence, as shown in the following code snippet:

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

In cases where a collection inherits fields from a parent collection, it's usually easier to use the `ignore` property of the `@Collection` annotation:

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

If a collection contains a field with a type that is not supported by Isar, you have to ignore the field.

:::warning
Keep in mind that it is not good practice to store information in Isar objects that are not persisted.
:::

## Supported types

Isar supports the following data types:

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

Additionally, embedded objects and enums are supported. We'll cover those below.

## byte, short, float

For many use cases, you don't need the full range of a 64-bit integer or double. Isar supports additional types that allow you to save space and memory when storing smaller numbers.

| Type       | Size in bytes | Range                                                   |
| ---------- | ------------- | ------------------------------------------------------- |
| **byte**   | 1             | 0 to 255                                                |
| **short**  | 4             | -2,147,483,647 to 2,147,483,647                         |
| **int**    | 8             | -9,223,372,036,854,775,807 to 9,223,372,036,854,775,807 |
| **float**  | 4             | -3.4e38 to 3.4e38                                       |
| **double** | 8             | -1.7e308 to 1.7e308                                     |

The additional number types are just aliases for the native Dart types, so using `short`, for example, works the same as using `int`.

Here is an example collection containing all of the above types:

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

All number types can also be used in lists. For storing bytes, you should use `List<byte>`.

## Nullable types

Understanding how nullability works in Isar is essential: Number types do **NOT** have a dedicated `null` representation. Instead, a specific value is used:

| Type       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN`  |
| **double** |  `double.NaN` |

`bool`, `String`, and `List` have a separate `null` representation.

This behavior enables performance improvements, and it allows you to change the nullability of your fields freely without requiring migration or special code to handle `null` values.

:::warning
The `byte` type does not support null values.
:::

## DateTime

Isar does not store timezone information of your dates. Instead, it converts `DateTime`s to UTC before storing them. Isar returns all dates in local time.

`DateTime`s are stored with microsecond precision. In browsers, only millisecond precision is supported because of JavaScript limitations.

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
