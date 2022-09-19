---
title: Schema
---

# Schema

When using Isar, you're dealing with Collections. A collection can only contain a single type of Dart object. To let Isar know which objects you want to store, you need to annotate your classes with `@collection`. The Isar code generator will take care of the rest. All the collections combined are called the "database schema".

## Annotating classes

The Isar generator will find all classes annotated with `@collection`.

```dart
@collection
class Contact {
  Id? id;

  late String firstName;

  late String lastName;

  late bool isStarred;
}
```

| Config        | Description                                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Control whether fields of parent classes and mixins will be stored in Isar. Enabled by default.                  |
| `accessor`    | Allows you to rename the default collection accessor (for example `isar.contacts` for the `Contact` collection). |
| `ignore`      | Allows ignoring certain properties. These are also respected for super classes.                                  |

### Isar Id

All model classes need to define an id property with type `Id` that uniquely identifies an object. `Id` is just an alias for `int` that allows the Isar Generator to recognize the id property.

```dart
@collection
class Contact {
  Id? id;

  String? firstName;

  String? lastName;

  bool? isStarred;
}
```

Isar automatically indexes id fields, which allows you to efficiently read and modify objects based on their id.

You can either set ids yourself or request Isar to assign an auto-increment id. If the `id` field is `null` and not `final`, Isar will assign an auto-increment id. If you want a non-nullable auto-increment id, you can use `Isar.autoIncrement` instead of `null`.

:::tip
Auto increment ids are not reused when an object is deleted. The only way to reset auto-increment ids is to clear the database.
:::

### Ignoring fields

By default, all public fields of a class will be persisted. By annotating a property or getter with `@ignore`, you can exclude it from persistence. Keep in mind that it is not good practice to store information in Isar objects that are not persisted.

### Renaming classes and fields

Sometimes it is useful to store classes or fields with a different name than the Dart class or field name. This can be achieved by annotating the class or field with `@Name`. The following collection is stored the same as the `Contact` class above.

```dart
@collection
@Name("Contact")
class MyContactClass1 {

  @Name("id")
  Id myObjectId;

  @Name("firstName")
  String theFirstName;

  @Name("lastName")
  String familyNameOrWhatever;

  bool isStarred;
}
```

Especially if you want to rename fields or classes that are already stored in the database, you should consider using the `@Name` annotation. Otherwise, the database will just delete and re-create the field or collection.

## Supported types

Isar supports the following data types:

- `bool`
- `int`
- `double`
- `DateTime`
- `String`
- `List<bool>`
- `List<int>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

Additionally, embedded objects and enums are supported. We'll cover those below.

## byte, short, float

For many use cases, you don't need the full range of a 64-bit integer or double. Isar supports additional types that allow you to save space and memory when storing smaller numbers.

| Type       | Size in bytes | Range                                                   |
| ---------- |-------------- | ------------------------------------------------------- |
| **byte**   | 1             | 0 to 255                                                |
| **short**  | 4             | -2,147,483,647 to 2,147,483,647                         |
| **int**    | 8             | -9,223,372,036,854,775,807 to 9,223,372,036,854,775,807 |
| **float**  | 4             | -3.4e38 to 3.4e38                                       |
| **double** | 8             | -1.7e308 to 1.7e308                                     |

The additional number types are just aliases for the native Dart types so using a `short` for example works the same as using an `int`.

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

All of these types can also be used in lists. For example, for storing bytes you should use `List<byte>`.

## Nullable types

It is important to understand how nullability works in Isar:
Number types do **NOT** have a dedicated `null` representation. Instead, a specific value will be used:

| Type       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` | 
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN` |
| **double** |  `double.NaN` |

`bool`, `String` and `List` have a separate `null` representation.

This behavior enables performance improvements and it allows you to change the nullability of your fields freely without requiring migration or special code to handle `null` values.

:::warning
The `byte` type does not support null values.
:::

## DateTime

Isar does not store timezone information of your dates. Instead it converts `DateTime`s to UTC before storing them. Isar returns all dates in local time.

`DateTime`s are stored with microsecond precision. In browsers, only millisecond precision is supported because of JavaScript limitations.

## Enum

Isar allows storing and using enums like other Isar types. You have to choose however how the enum should be represented on the disk. Isar supports four different strategies:

| EnumType    | Description 
| ----------- | -----------
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

It's often useful to have nested objects in your collection model. There is no limit to how deep you can nest objects. Keep in mind however that updating a deeply nested object will require writing the whole object tree to the database.
  
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