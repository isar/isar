<p align="center">
  <a href="https://isar.dev">
    <img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/isar.svg?sanitize=true" height="128">
  </a>
  <h1 align="center">Isar Database</h1>
</p>

<p align="center">
  <a href="https://github.com/isar/isar/actions/workflows/test.yml">
    <img src="https://img.shields.io/github/workflow/status/isar/isar/Dart%20CI/main?label=tests&labelColor=333940&logo=github">
  </a>
  <a href="https://pub.dev/packages/isar">
    <img src="https://img.shields.io/pub/v/isar?label=pub.dev&labelColor=333940&logo=dart">
  </a>
  <a href="https://github.com/isar/isar/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/isar/isar?color=%23007A88&labelColor=333940&logo=apache">
  </a>
</p>

<p align="center">
  <a href="https://isar.dev">Quickstart</a> •
  <a href="https://isar.dev/schema">Documentation</a> •
  <a href="https://github.com/isar/samples">Sample Apps</a> •
  <a href="https://github.com/isar/isar/discussions">Support & Ideas</a> •
  <a href="https://pub.dev/packages/isar">Pub.dev</a>
</p>


> #### Isar [ee-zahr]:
> 1. River in Bavaria, Germany.
> 2. Database that will make your life easier.


### Features

- 💙 **Made for Flutter**. Easy to use, no config, no boilerplate
- 🚀 **Highly scalable** from hundreds to hundreds of thousands of records
- 🍭 **Feature rich**. Composite & multi indexes, query modifiers, JSON support and more
- 🔎 **Full-text search**. Make searching fast and fun
- 📱 **Multiplatform**. iOS, Android, Desktop and the web (soon™)
- 🧪 **ACID semantics**. Rely on consistency
- ⏱ **Asynchronous**. Parallel query operations & multi-isolate support
- 💃 **Static typing**. Compile-time checked and autocompleted queries

### 1. Add to pubspec.yaml

```yaml
dependencies:
  isar: $latest
  isar_flutter_libs: $latest # contains the binaries
  isar_connect: $latest # if you want to use the Isar Inspector

dev_dependencies:
  isar_generator: $latest
  build_runner: any
```

Replace `$latest` with the latest Isar version.

### 2. Define a Collection
```dart
@Collection()
class Post {
  int? id; // auto increment id

  late String title;

  @Index(type: IndexType.value) // Search index
  List<String> get titleWords => Isar.splitWords(title);
}
```

### 3. Open an instance
```dart
initializeIsarConnect(); // if you want to use the Isar Inspector

final dir = await getApplicationSupportDirectory(); // path_provider package
final isar = await Isar.open(
  schemas: [PostSchema],
  path: dir.path,
);
```


## Isar Inspector

The [Isar Inspector](https://github.com/isar/isar/releases/latest) allows you to inspect the Isar instances & collections of your app in real time. You can execute queries, switch between instances and sort the data.

<img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/isar-inspector.png?sanitize=true">


## CRUD operations

All basic crud operations are available via the IsarCollection.

```dart
final newPost = Post()..title = 'Amazing new database';

await isar.writeTxn((isar) {
  newPost.id = await isar.posts.put(newPost); // insert
});

final existingPost = await isar.get(newPost.id!); // get

await isar.writeTxn((isar) {
  await isar.posts.delete(existingPost.id!); // delete
});
```

## Queries

Isar has a powerful query language that allows you to make use of your indexes, filter distinct objects, use complex `and()` and `or()` groups and sort the results.

```dart
final usersWithPrefix = isar.users
  .where()
  .nameStartsWith('dan') // use index
  .limit(10)
  .findAll()

final usersLivingInMunich = isar.users
  .filter()
  .ageGreaterThan(32)
  .or()
  .addressMatches('*Munich*', caseSensitive: false) // address containing 'munich' (case insensitive)
  .optional(
    shouldSort, // only apply if shouldSort == true
    (q) => q.sortedByAge(), 
  )
  .findAll()
```

## Links

You can easily define relationships between objects. In Isar they are called links and backlinks:

```dart
@Collection()
class Teacher {
    int? id;

    late String subject;

    @Backlink(to: 'teacher')
    var students = IsarLinks<Student>();
}

@Collection()
class Student {
    int? id;

    late String name;

    var teacher = IsarLink<Teacher>();
}
```

## Watchers

With Isar, you can watch Collections, Objects, or Queries. A watcher is notified after a transaction commits successfully and the target actually changes.
Watchers can be lazy and not reload the data or they can be non-lazy and fetch new results in the background.

```dart
Stream<void> collectionStream = isar.posts.watchLazy;

Stream<List<Post>> queryStream = databasePosts.watch();

queryStream.listen((newResult) {
  // do UI updates
})
```

### License

```
Copyright 2022 Simon Leier

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
