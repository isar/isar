---
title: Quickstart
---

# Quickstart

Holy smokes you're here! Let's do this. We're going to be short on words and quick on code in this quickstart.

## 1. Add dependencies

First, add Isar to your project. Add the following packages to your `pubspec.yaml`. Always use the latest version.

```yaml
dependencies:
  isar: $latest
  isar_flutter_libs: $latest # contains the binaries (not required for web)

dev_dependencies:
  isar_generator: $latest
  build_runner: any
```

Replace `$latest` with the latest Isar version.

For non-Flutter projects, you need to manually include the Isar Core binaries.

## 2. Annotate classes

Annotate your classes with `@Collection` and choose an id field.

```dart
part 'contact.g.dart';

@Collection()
class Contact {
  @Id()
  int? id;

  late String name;
}
```

## 3. Run code generator

Execute the following command to start the `build_runner`:

```
dart run build_runner build
```

If you are using Flutter, try:

```
flutter pub run build_runner build
```

## 4. Open Isar instance

This opens an Isar instance at a valid location.

```dart
final dir = await getApplicationSupportDirectory();

final isar = await Isar.open(
  schemas: [ContactSchema],
  directory: dir.path,
);
```

## 5. Write and read from database

Once your instance is open, you can start using the database.

```dart
final contact = Contact()
  ..name = "My first contact";

await isar.writeTxn((isar) async {
  contact.id = await isar.contacts.put(contact);
});

final allContacts = await isar.contacts.where().findAll();
```

## Other resources

You're a visual learner? Check out this great series to get started with Isar:

<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/videoseries?list=PLKKf8l1ne4_hMBtRykh9GCC4MMyteUTyf" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
