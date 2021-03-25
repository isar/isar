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
    <img src="https://img.shields.io/github/license/hivedb/hive?color=%23007A88&labelColor=333940&logo=apache">
  </a>
</p>

<p align="center">🚧 Very unstable and not ready for serious usage 🚧</p>

<p align="center">
  <a href="https://isar.dev">Quickstart</a> •
  <a href="https://isar.dev/schema">Documentation</a> •
  <a href="https://isar.dev">Examples</a> •
  <a href="https://github.com/isar/isar/discussions">Support & Ideas</a> •
  <a href="https://pub.dev/packages/isar">Pub.dev</a>
</p>


> #### Isar [ee-zahr]:
> 1. River in Bavaria, Germany.
> 2. Database that will make your life easier.


### Features

- ⚡️ **Launch your app instantly** no matter how much data you have
- 📈 **Highly scalable** from hundreds to tens of thousands of records
- 😎 **Lazy loaded**. Only load data when you need it
- 🔎 **Full-text search**. Make searching fast and fun
- 📱 **Multiplatform**. iOS, Android, Desktop and the web (soon™)
- 💙 **Made for Flutter**. Easily use it in your Flutter app
- 🧪 **ACID semantics**. Rely on consistency
- ⏱ **Asynchronous**. Parallel query operations & multi-isolate support
- ⚠️ **Static typing**. Compile-time checked and autocompleted queries
- 🔒 **Strong encryption**. Optional authenticated AES-256 GCM encryption

### Add to pubspec.yaml

```yaml
dependencies:
  isar: <current_version>
  isar_flutter_libs: <current_version> # contains the binaries
  isar_connect: <current_version> # if you want to use the Isar Inspector

dev_dependencies:
  isar_generator: <current_version>
  build_runner: any
```


## Isar Inspector

The [Isar Inspector](https://github.com/isar/isar-inspector) allows you to inspect the Isar instances & collections of your app in real time. You can execute queries, switch between instances and sort the data.

<img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/isar-inspector.png?sanitize=true">

## Schema definition
```dart
@Collection()
class Post {
  int? id; // auto increment id

  @Index(indexType: IndexType.words, caseSensitive: false) // Search index
  String title;

  List<String> comments
}
```

## CRUD operations

All basic crud operations are available via the IsarCollection.

```dart
final newPost = Post()
  ..id = uuid.v4()
  ..title = 'Amazing new database'
  ..comments = ['First'];

await isar.writeTxn((isar) {
  await isar.posts.put(newPost); // insert
});

final existingPost = await isar.get(newPost.id); // get

await isar.writeTxn((isar) {
  await isar.posts.delete(existingPost.id); // delete
});
```

## Queries

Isar has a powerful query language that allows you to make use of your indexes, filter distinct objects, use complex `and()` and `or()` groups and sort the results.

```dart
final isar = await openIsar();

final databasePosts = isar.posts
  .where()
  .titleWordBeginsWith('DaTAb') // use case insensitive search index
  .limit(10)
  .findAll()

final postsWithFirstCommentOrTitle = isar.posts
  .where()
  .filter()
  .commentsAnyEqualTo('first', caseSensitive: false)
  .or()
  .titleEqualTo('first')
  .findAll();
```

## Links

You can easily define relationships between objects. In Isar they are called links and backlinks:

```dart
@IsarCollection()
class Teacher {
    int id;

    String subject;

    @Backlink(to: 'teacher')
    final students = IsarLinks<Student>();
}

@IsarCollection()
class Student {
    int id;

    String name;

    final teacher = IsarLink<Teacher>();
}
```

## Watchers

With Isar, you can watch Collections, Objects, or Queries. A watcher is notified after a transaction commits successfully and the target actually changes.
Watchers can be lazy and not reload the data or they can be non-lazy and fetch new results in the background.

```dart
Stream<void> collectionStream = isar.posts.watch(lazy: true);

Stream<List<Post>> queryStream = databasePosts.watch(lazy: false);

queryStream.listen((newResult) {
  // do UI updates
})
```

### License

```
Copyright 2021 Simon Leier

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
