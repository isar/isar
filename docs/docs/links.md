---
title: Links
---

# Links

Links allow you to express relationships between objects, such as a comment's author (User). You can model `1:1`, `1:n`, and `n:n` relationships with Isar links. Using links is less ergonomic than using embedded objects, and you should use embedded objects whenever possible.

Think of the link as a separate table that contains the relation. It's similar to SQL relations but has a different feature set and API.

## IsarLink

`IsarLink<T>` can contain no or one related object, and it can be used to express a to-one relationship. `IsarLink` has a single property called `value` which holds the linked object.

Links are lazy, so you need to tell the `IsarLink` to load or save the `value` explicitly. You can do this by calling `linkProperty.load()` and `linkProperty.save()`.

:::tip
The id property of the source and target collections of a link should be non-final.
:::

For non-web targets, links get loaded automatically when you use them for the first time. Let's start by adding an IsarLink to a collection:

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

  final teacher = IsarLink<Teacher>();
}
```

We defined a link between teachers and students. Every student can have exactly one teacher in this example.

First, we create the teacher and assign it to a student. We have to `.put()` the teacher and save the link manually.

```dart
final mathTeacher = Teacher()..subject = 'Math';

final linda = Student()
  ..name = 'Linda'
  ..teacher.value = mathTeacher;

await isar.writeTxn(() async {
  await isar.students.put(linda);
  await isar.teachers.put(mathTeacher);
  await linda.teacher.save();
});
```

We can now use the link:

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

Let's try the same thing with synchronous code. We don't need to save the link manually because `.putSync()` automatically saves all links. It even creates the teacher for us.

```dart
final englishTeacher = Teacher()..subject = 'English';

final david = Student()
  ..name = 'David'
  ..teacher.value = englishTeacher;

isar.writeTxnSync(() {
  isar.students.putSync(david);
});
```

## IsarLinks

It would make more sense if the student from the previous example could have multiple teachers. Fortunately, Isar has `IsarLinks<T>`, which can contain multiple related objects and express a to-many relationship.

`IsarLinks<T>` extends `Set<T>` and exposes all the methods that are allowed for sets.

`IsarLinks` behaves much like `IsarLink` and is also lazy. To load all linked object call `linkProperty.load()`. To persist the changes, call `linkProperty.save()`.

Internally both `IsarLink` and `IsarLinks` are represented in the same way. We can upgrade the `IsarLink<Teacher>` from before to an `IsarLinks<Teacher>` to assign multiple teachers to a single student (without losing data).

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

This works because we did not change the name of the link (`teacher`), so Isar remembers it from before.

```dart
final biologyTeacher = Teacher()..subject = 'Biology';

final linda = isar.students.where()
  .filter()
  .nameEqualTo('Linda')
  .findFirst();

print(linda.teachers); // {Teacher('Math')}

linda.teachers.add(biologyTeacher);

await isar.writeTxn(() async {
  await linda.teachers.save();
});

print(linda.teachers); // {Teacher('Math'), Teacher('Biology')}
```

## Backlinks

I hear you ask, "What if we want to express reverse relationships?". Don't worry; we'll now introduce backlinks.

Backlinks are links in the reverse direction. Each link always has an implicit backlink. You can make it available to your app by annotating an `IsarLink` or `IsarLinks` with `@Backlink()`.

Backlinks do not require additional memory or resources; you can freely add, remove and rename them without losing data.

We want to know which students a specific teacher has, so we define a backlink:

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

We need to specify the link to which the backlink points. It is possible to have multiple different links between two objects.

## Initialize links

`IsarLink` and `IsarLinks` have a zero-arg constructor, which should be used to assign the link property when the object is created. It is good practice to make link properties `final`.

When you `put()` your object for the first time, the link gets initialized with source and target collection, and you can call methods like `load()` and `save()`. A link starts tracking changes immediately after its creation, so you can add and remove relations even before the link is initialized.

:::danger
It is illegal to move a link to another object.
:::
