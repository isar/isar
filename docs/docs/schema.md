---
title: Schema
---

# Schema

When you use Isar to store your app's data, you're dealing with collections. A collection is like a database table in the associated Isar database and can only contain a single type of Dart object. Each collection object represents a row of data in the corresponding collection.

A collection definition is called "schema". The Isar Generator will do the heavy lifting for you and generate most of the code you need to use the collection.

## Anatomy of a collection

You define each Isar collection by annotating a class with `@collection` or `@Collection()`. An Isar collection includes fields for each column in the corresponding table in the database, including one that comprises the primary key.

The following code is an example of a simple collection that defines a `User` table with columns for ID, first name, and last name:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
To persist a field, Isar must have access to it. You can ensure Isar has access to a field by making it public or by providing getter and setter methods.
:::

There are a few optional parameters to customize the collection:

| Config        | Description                                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Control whether fields of parent classes and mixins will be stored in Isar. Enabled by default.                  |
| `accessor`    | Allows you to rename the default collection accessor (for example `isar.contacts` for the `Contact` collection). |
| `ignore`      | Allows ignoring certain properties. These are also respected for super classes.                                  |

### Isar Id

Each collection class has to define an id property with the type `Id` uniquely identifying an object. `Id` is just an alias for `int` that allows the Isar Generator to recognize the id property.

Isar automatically indexes id fields, which allows you to get and modify objects based on their id efficiently.

You can either set ids yourself or ask Isar to assign an auto-increment id. If the `id` field is `null` and not `final`, Isar will assign an auto-increment id. If you want a non-nullable auto-increment id, you can use `Isar.autoIncrement` instead of `null`.

:::tip
Auto increment ids are not reused when an object is deleted. The only way to reset auto-increment ids is to clear the database.
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
