---
title: Links
---

# Links

Links allow you to express relationships between objects — such as the author (User) of a Comment, or the Post the comment belongs to. You can express 1:1, 1:n, n:n relationships with Isar links.

## IsarLink

`IsarLink<T>` can contain zero or one related objects so it can be used to express a to-one relationship. `IsarLink` has a single property called `value` which holds the linked object.

Links are lazy so you need to explicitly tell the `IsarLink` to load or save the `value`. You can do this by calling `linkProperty.load()` and `linkProperty.save()`.

Let's start by adding an IsarLink to a collection:

```dart
@Collection()
class Teacher {
  int? id;

  late String subject;
}

@Collection()
class Student {
  int? id;

  late String name;

  final teachers = IsarLink<Teacher>();
}
```

We defined a link between teachers and students. Every student can have exactly one teacher in this example. We call the link `teachers` for the example in the next section.

```dart
final mathTeacher = Teacher()..subject = 'Math';

final linda = Student()
  ..name = 'Linda'
  ..teachers.value = mathTeacher;

await isar.writeTxn((isar) async {
  await isar.students.put(linda);
});
```

First we create a the teacher and assign it to a student. As you can see in this example, we have to `put()` the student manually (obviously) but the link is saved automatically and also takes care of adding the `mathTeacher` to the database.

Later, we change the link value and save it in a write transaction.

## IsarLinks

It would make more sense if the student from the previous example could have multiple teachers. Fortunately Isar has `IsarLinks<T>` which can contain multiple related objects and express a to-many relationship.

`IsarLinks<T>` extends `Set<T>` so it exposes all the methods that are allowed for sets.

`IsarLinks` behaves much like `IsarLink` and is also lazy. To load all linked object call `linkProperty.load()`. To persist the changes call `linkProperty.save()`.

Internally both `IsarLink` and `IsarLinks` are represented in the same way. This allows us to upgrade the `IsarLink<Teacher>` from before to an `IsarLinks<Teacher>` to assign multiple teachers to a single student (without losing data).

```dart
@Collection()
class Student {
  int? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

This works because we did not change the name of the link (`teachers`) so Isar remembers it from before.

```dart
final englishTeacher = Teacher()..subject = 'English';

final linda = isar.students.where()
  .filter()
  .nameEqualTo('Linda')
  .findFirst();

await linda.teachers.load();
print(linda.teachers); // {Teacher('Math')}

linda.teachers.add(englishTeacher);

await isar.writeTxn((isar) async {
  await linda.teachers.save();
});

print(linda.teachers); // {Teacher('Math'), Teacher('English')}
```

## Backlinks

I hear you ask "What if we want to express reverse relationships?". Don't worry, we'll now introduce backlinks.

Backlinks are links in reverse direction. Each link always has an implicit backlink. You can make it available to your app by annotating an `IsarLink` or `IsarLinks` with `@Backlink()`.

Backlinks do not require additional memory or resources and you can freely add, remove and rename them without losing data.

We want to know which students a specific teacher has so we define a backlink:

```dart
@Collection()
class Teacher {
  int? id;

  late String subject;

  @Backlink(to: 'teachers')
  final students = IsarLinks<Student>();
}
```

We need to specify the link to which the backlink points. It is possible to have multiple different links between two objects.

## Initialize links

`IsarLink` and `IsarLinks` both have a zero-arg constructor which should be used to assign the link property when the object is created. It is good practice to make link properties `final`.

When you `put()` your object for the first time, the link gets initialized with source and target collection and you can call methods like `load()` and `save()`. A link starts tracking changes immediately after its creation so you can add and remove relations even before the link is initialized.

It is illegal to move a link to another object and will lead to undefined behavior.
