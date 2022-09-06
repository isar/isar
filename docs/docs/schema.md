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

  Id id = Isar.autoIncrement;

  String firstName;

  String lastName;

  bool isStarred;
}
```

| Config        | Description                                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Control whether fields of parent classes and mixins will be stored in Isar. Enabled by default.                  |
| `accessor`    | Allows you to rename the default collection accessor (for example `isar.contacts` for the `Contact` collection). |

### Id

All model classes need to define an id by a property with type `Id` that uniquely identifies an object. Only `int` properties may be used as id. If a class has a field called `id`.

```dart
@collection
class Pet {

  Id id; // field is called id

  String name;
}
```

Isar automatically indexes id fields, which allows you to efficiently read and modify objects based on their id.

You can either set ids yourself or request Isar to assign an auto-increment id. If the `id` field is `null`, Isar will use an auto-increment id. You can also assign `Isar.autoIncrement` to the id field to request an auto-increment id.

The default isar auto incremented value is -9223372036854775808. Isar assigns the id during the write txn. so if the  id type is final then it can not assign the auto incremented id. If you want to make the id final for whatever reason you should manually create a new object with the actual id returned by the put operation
:::tip
Auto increment ids are not reused when an object is deleted. That's how most databases do it.
:::

### Supported types

Isar supports the following data types:

- `bool`
- `int`
- `double`
- `DateTime`
- `String`
- `Enumerated`
- `Uint8List`
- `List<bool>`
- `List<int>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

It is important to understand how nullability works in Isar:
Number types do **NOT** have a dedicated `null`-representation. Instead a specific value will be used:

|            | VM            | Web         |
| ---------- | ------------- | ----------- |
| **int**    |  `int.MIN`    | `-Infinity` |
| **double** |  `double.NaN` | `-Infinity` |

`bool`, `String` and `List` have a separate `null` representation.

This behavior allows for nice performance improvements and it allows you to change the nullability of your fields freely without requiring migration or special code to handle `null`s.

:::warning
Web does not support `NaN`. This is an IndexedDB limitation.
:::

[//]: <➡️ Use `TypeConverter`s to store unsupported types like enums: [Type Converters](type_converters)>

### 8-byte and 4-byte numbers

`int` and `double` (64-bit) have an 8-byte representation in Dart. By default, this is also true for Isar. You can however change numbers to a 4-byte representation to save disk space by typing number fields with `short` and `float` (32-bit) respectively. `byte` is a 8-bit representation to save even more space. It is your responsibility to make sure that you do not store a number that requires larger space in `short`, `float` & `byte` fields.

Since JavaScript only supports 64-bit floating point numbers `short`, `byte` and `float` has no effect on web.

### DateTime

Isar does not store timezone information of your dates. Instead it converts `DateTime`s to UTC before storing them. Isar returns all dates in local time.

`DateTime`s are stored with microsecond precision. In browsers, only millisecond precision is supported because of JavaScript limitations.

### @embedded

Embedded objects can be added to collections or other embedded objects without using links. They allow you to store and query a deeply nested structure in Isar. Link is just a reference of an object in isar. But Embedded object is totally a separate object that lives inside the parent object.

You can link collections with each other. All it does is create an index containing the ids of both linked objects. You can update or delete the objects individually.
To query linked objects Isar needs a separate lookup. If you delete a linked object, the other one still exists.

Embedded objects don't live on their own. They are stored together with their parent so they cannot be updated independent of their parent. They don't have their own id, cannot contain links or indexes and when their parent is deleted, so are the embedded objects.
You don't need to load() embedded objects.

:::tip
An embedded object can't annotated as a collection and can't be indexed. But you can create a common superclass to overcome this.
:::

```dart
part 'email.g.dart';

@collection
class Email {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  String? title;

  List<Recipient>? recipients;

  @enumerated
  Status status = Status.pending;
}

@embedded
class Recipient {
  String? name;

  String? address;
}

enum Status {
  draft,
  sending,
  sent,
}

```

### @enumerated

Annotate your `enum` variables with '@enumerated` and That's it. Isar takes care of the rest.

### Ignoring fields

By default, all public fields of a class will be persisted. By annotating a field with `@Ignore()`, you can exclude it from persistence. Keep in mind that it is not good practice to store information in your Isar objects that is not persisted.

### Renaming classes and fields

You have to be careful when you want to rename a class or field. Most of the time the old class or field will just be dropped and recreated. With the `@Name()` annotation, you can name classes and fields in the database independantly from Dart. The following code will yield the exact same schema as the code above.

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

## Schema migration

It is possible to change the schema between releases of your app (for example by adding collections) but it is very important to follow the rules of schema migration.

You are allowed to do the following modifications:

- Add & remove collections
- Add & remove fields
- Change the nullability of a field (e.g. `int` -> `Id?` or `List<String?>?` -> `List<String>`)
- Add & remove indexes
- Add & remove links
- Change between `Link<MyCol>` and `Links<MyCol>` (no data will be lost)

:::warning

#### BE CAREFUL

If you rename a field or collection that is not annotated with `@Name()`, the field or collection will be dropped and recreated.
:::

Deleted fields will still remain in the database. You are not allowed to recreate deleted fields with a different type.

:::danger

#### ILLEGAL MODIFICATIONS

- Changing the type of fields in existing collections (even previously deleted ones)
- Creating a unique index for a property with duplicate values
  :::
