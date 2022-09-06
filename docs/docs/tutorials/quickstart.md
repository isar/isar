---
title: Quickstart
---

# Quickstart

Holy smokes you're here! Let's get started on using the coolest Flutter database out there...

We're going to be short on words and quick on code in this quickstart.

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

➡️ Learn more: [Dart](../dart)
```dart
await Isar.initializeIsarCore(download:true);
```

## 2. Annotate classes

Annotate your classes with `@collection` and choose an id field.

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
  schemas: [EmailSchema],
  directory: dir.path,
  inspector:true,
);
```

## 5. Write and read from database

Once your instance is open, you can start using the database.

All basic crud operations are available via the `IsarCollection`.

```dart
final newPost = Post()..title = 'Amazing new database';

await isar.writeTxn(() {
  newPost.id = await isar.posts.put(newPost); // insert & update
});

final existingPost = await isar.posts.get(newPost.id!); // get

await isar.writeTxn(() {
  await isar.posts.delete(existingPost.id!); // delete
});
```

## Other resources

You're a visual learner? Check out this great series to get started with Isar:

<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/videoseries?list=PLKKf8l1ne4_hMBtRykh9GCC4MMyteUTyf" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/pdKb8HLCXOA " title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
