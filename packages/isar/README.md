<p align="center">
  <a href="https://isar.dev">
    <img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/isar.svg?sanitize=true" height="128">
  </a>
  <h1 align="center">Isar Database</h1>
</p>

<p align="center">
<a href="https://pub.dev/packages/isar">
    <img src="https://img.shields.io/pub/v/isar?label=pub.dev&labelColor=333940&logo=dart">
  </a>
  <a href="https://github.com/isar/isar/actions/workflows/test.yml">
    <img src="https://img.shields.io/github/workflow/status/isar/isar/Dart%20CI/main?label=tests&labelColor=333940&logo=github">
  </a>
  <a href="https://t.me/isardb">
    <img src="https://img.shields.io/static/v1?label=join&message=isardb&labelColor=333940&logo=telegram&logoColor=white&color=229ED9">
  </a>
  <a href="https://github.com/isar/isar/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/isar/isar?color=%23007A88&labelColor=333940&logo=apache">
  </a>
  <a href="https://twitter.com/simonleier">
    <img src="https://img.shields.io/twitter/follow/simonleier?style=flat&label=Follow&color=1DA1F2&labelColor=333940&logo=twitter&logoColor=fff">
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
>
> 1. River in Bavaria, Germany.
> 2. Database that will make your life easier.

## Features

- 💙 **Made for Flutter**. Easy to use, no config, no boilerplate
- 🚀 **Highly scalable** The sky is the limit (pun intended)
- 🍭 **Feature rich**. Composite & multi-entry indexes, query modifiers, JSON support etc.
- ⏱ **Asynchronous**. Parallel query operations & multi-isolate support by default
- 🦄 **Open source**. Everything is open source and free forever!

Isar can do much more (and we are just getting started)

- 🕵️ **Full-text search**. Make searching fast and fun
- 📱 **Multiplatform**. iOS, Android, Desktop and FULL WEB SUPPORT!
- 🧪 **ACID semantics**. Rely on consistency
- 💃 **Static typing**. Compile-time checked and autocompleted queries
- ✨ **Beautiful documentation**. Readable, easy to understand and ever improving

Join the [Telegram group](https://t.me/isardb) for discussion and check out the [CONTRIBUTING.md](https://github.com/isar/isar/blob/main/CONTRIBUTING.md) doc.

If you want to say thank you, star us on GitHub and like us on pub.dev 🙌💙

## Quickstart

Holy smokes you're here! Let's get started...

### 1. Add to pubspec.yaml

```yaml
dependencies:
  isar: 3.0.0-dev.2
  isar_flutter_libs: 3.0.0-dev.2 # contains the binaries

dev_dependencies:
  isar_generator: 3.0.0-dev.2
  build_runner: any
```

### 2. Annotate a Collection

```dart
part 'post.g.dart';

@Collection()
class Post {
  int id = Isar.autoIncrement;

  late String title;

  late DateTime date;
}
```

### 3. Open an instance

```dart
final dir = await getApplicationSupportDirectory(); // path_provider package
final isar = await Isar.open(
  schemas: [PostSchema],
  directory: dir.path,
  inspector: true, // if you want to enable the inspector for debug builds
);
```

### 4. Query the database

```dart
final posts = await isar.posts.filter()
  .titleContains('awesome', caseSensitive: false)
  .sortByDateDesc()
  .limit(10)
  .findAll();
```

## Isar Inspector

The [Isar Inspector](https://github.com/isar/isar/releases/latest) allows you to inspect the Isar instances & collections of your app in real time. You can execute queries, switch between instances and sort the data.

<img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/isar-inspector.png?sanitize=true">

## CRUD operations

All basic crud operations are available via the IsarCollection.

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

## Queries

Isar has a powerful query language that allows you to make use of your indexes, filter distinct objects, use complex `and()` and `or()` groups, query links and sort the results.

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
    final students = IsarLinks<Student>();
}

@Collection()
class Student {
    int? id;

    late String name;

    final teacher = IsarLink<Teacher>();
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

## Bechmarks

Benchmarks only give a rough idea of the performance of a database but as you can see, Isar is quite fast 😇

<img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/benchmarks/insert.png" width="100%" /> | <img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/benchmarks/query.png" width="100%" />
--- | ---
<img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/benchmarks/delete.png" width="100%" /> | <img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/benchmarks/size.png" width="100%" />

If you are interested in more benchmarks or check how Isar performs on your device you can run the [benchmarks](https://github.com/isar/isar_benchmark) yourself.

## Unit tests

If you want to use Isar in unit tests or Dart code, call `await Isar.initializeIsarCore(download: true)` before using Isar in your tests.

Isar will automatically download the correct binary for your platform. You can also pass a `libraries` map to adjust the download location for each platform.

Make sure to use `flutter test -j 1` to avoid tests running in parallel. This would break the automatic download.

## Contributors ✨

Thanks goes to these wonderful people:

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/h1376h"><img src="https://avatars.githubusercontent.com/u/3498335?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Hamed H.</b></sub></a><br /><a href="https://github.com/isar/isar/commits?author=h1376h" title="Code">💻</a> <a href="#maintenance-h1376h" title="Maintenance">🚧</a></td>
    <td align="center"><a href="https://github.com/Jtplouffe"><img src="https://avatars.githubusercontent.com/u/32107801?v=4?s=100" width="100px;" alt=""/><br /><sub><b>JT</b></sub></a><br /><a href="https://github.com/isar/isar/commits?author=Jtplouffe" title="Tests">⚠️</a> <a href="https://github.com/isar/isar/issues?q=author%3AJtplouffe" title="Bug reports">🐛</a></td>
    <td align="center"><a href="https://www.linkedin.com/in/simon-leier/"><img src="https://avatars.githubusercontent.com/u/13610195?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Simon Leier</b></sub></a><br /><a href="https://github.com/isar/isar/issues?q=author%3Aleisim" title="Bug reports">🐛</a> <a href="https://github.com/isar/isar/commits?author=leisim" title="Code">💻</a> <a href="https://github.com/isar/isar/commits?author=leisim" title="Documentation">📖</a> <a href="https://github.com/isar/isar/commits?author=leisim" title="Tests">⚠️</a> <a href="#example-leisim" title="Examples">💡</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!

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
