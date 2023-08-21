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
  <a href="https://github.com/isar/isar/actions/workflows/test.yaml">
    <img src="https://img.shields.io/github/actions/workflow/status/isar/isar/test.yaml?branch=main&label=tests&labelColor=333940&logo=github">
  </a>
  <a href="https://app.codecov.io/gh/isar/isar">
    <img src="https://img.shields.io/codecov/c/github/isar/isar?logo=codecov&logoColor=fff&labelColor=333940&flag=isar">
  </a>
  <a href="https://t.me/isardb">
    <img src="https://img.shields.io/static/v1?label=join&message=Isar%20%26%20Hive&labelColor=333940&logo=telegram&logoColor=white&color=229ED9">
  </a>
  <a href="https://twitter.com/simcdev">
    <img src="https://img.shields.io/twitter/follow/simcdev?style=social">
  </a>
</p>

<p align="center">
  <a href="https://isar.dev">Quickstart</a> •
  <a href="https://isar.dev/schema">Documentation</a> •
  <a href="https://github.com/isar/isar/tree/main/examples/">Sample Apps</a> •
  <a href="https://github.com/isar/isar/discussions">Support & Ideas</a> •
  <a href="https://pub.dev/packages/isar">Pub.dev</a>
</p>

> #### Isar [ee-zahr]:
>
> 1. River in Bavaria, Germany.
> 2. [Crazy fast](#benchmarks) NoSQL database that is a joy to use.

⚠️ ISAR V4 IS NOT READY FOR PRODUCTION USE ⚠️  
If you want to use Isar in production, please use the stable version 3.

## Features

- 💙 **Made for Flutter**. Easy to use, no config, no boilerplate
- 🚀 **Highly scalable** The sky is the limit (pun intended)
- 🍭 **Feature rich**. Composite & multi-entry indexes, query modifiers, JSON support etc.
- ⏱ **Asynchronous**. Parallel query operations & multi-isolate support by default
- 🦄 **Open source**. Everything is open source and free forever!

Isar database can do much more (and we are just getting started)

- 🕵️ **Full-text search**. Make searching fast and fun
- 📱 **Multiplatform**. iOS, Android, Desktop
- 🧪 **ACID semantics**. Rely on database consistency
- 💃 **Static typing**. Compile-time checked and autocompleted queries
- ✨ **Beautiful documentation**. Readable, easy to understand and ever-improving

Join the [Telegram group](https://t.me/isardb) for discussion and sneak peeks of new versions of the DB.

If you want to say thank you, star us on GitHub and like us on pub.dev 🙌💙

## Quickstart

Holy smokes you're here! Let's get started on using the coolest Flutter database out there...

### 1. Add to pubspec.yaml

```yaml
dependencies:
  isar: 4.0.0
  isar_flutter_libs: 4.0.0 # contains Isar Core

dev_dependencies:
  build_runner: any
```

### 2. Annotate a Collection

```dart
part 'email.g.dart';

@collection
class Email {
  Email({
    this.id,
    this.title,
    this.recipients,
    this.status = Status.pending,
  });

  final int id;

  @Index(type: IndexType.value)
  final String? title;

  final List<Recipient>? recipients;

  final Status status;
}

@embedded
class Recipient {
  String? name;

  String? address;
}

enum Status {
  draft,
  pending,
  sent,
}
```

### 3. Open a database instance

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [EmailSchema],
  directory: dir.path,
);
```

### 4. Query the database

```dart
final emails = isar.emails.where()
  .titleContains('awesome', caseSensitive: false)
  .sortByStatusDesc()
  .limit(10)
  .findAll();
```

## Isar Database Inspector

The Isar Inspector allows you to inspect the Isar instances & collections of your app in real-time. You can execute queries, edit properties, switch between instances and sort the data.

<img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/inspector.gif">

To launch the inspector, just run your Isar app in debug mode and open the Inspector link in the logs.

## CRUD operations

All basic crud operations are available via the `IsarCollection`.

```dart
final newEmail = Email()..title = 'Amazing new database';

await isar.writeAsync(() {
  isar.emails.put(newEmail); // insert & update
});

final existingEmail = isar.emails.get(newEmail.id!); // get

await isar.writeAsync(() {
  isar.emails.delete(existingEmail.id!); // delete
});
```

## Database Queries

Isar database has a powerful query language that allows you to make use of your indexes, filter distinct objects, use complex `and()`, `or()` and `.xor()` groups, query links and sort the results.

```dart
final importantEmails = isar.emails
  .where()
  .titleStartsWith('Important') // use index
  .limit(10)
  .findAll()

final specificEmails = isar.emails
  .filter()
  .recipient((q) => q.nameEqualTo('David')) // query embedded objects
  .or()
  .titleMatches('*university*', caseSensitive: false) // title containing 'university' (case insensitive)
  .findAll()
```

## Database Watchers

With Isar database, you can watch collections, objects, or queries. A watcher is notified after a transaction commits successfully and the target changes.
Watchers can be lazy and not reload the data or they can be non-lazy and fetch new results in the background.

```dart
Stream<void> collectionStream = isar.emails.watchLazy();

Stream<List<Post>> queryStream = importantEmails.watch();

queryStream.listen((newResult) {
  // do UI updates
})
```

## Benchmarks

Benchmarks only give a rough idea of the performance of a database but as you can see, Isar NoSQL database is quite fast 😇

| <img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/benchmarks/insert.png" width="100%" /> | <img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/benchmarks/query.png" width="100%" /> |
| ---------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| <img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/benchmarks/update.png" width="100%" /> | <img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/benchmarks/size.png" width="100%" />  |

If you are interested in more benchmarks or want to check how Isar performs on your device you can run the [benchmarks](https://github.com/isar/isar_benchmark) yourself.

## Unit tests

If you want to use Isar database in unit tests or Dart code, call `await Isar.initializeIsarCore(download: true)` before using Isar in your tests.

Isar NoSQL database will automatically download the correct binary for your platform. You can also pass a `libraries` map to adjust the download location for each platform.

Make sure to use `flutter test -j 1` to avoid tests running in parallel. This would break the automatic download.

## Contributors ✨

Big thanks go to these wonderful people:

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/AlexisL61"><img src="https://avatars.githubusercontent.com/u/30233189?v=4" width="100px;" alt=""/><br /><sub><b>Alexis</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/buraktabn"><img src="https://avatars.githubusercontent.com/u/49204989?v=4" width="100px;" alt=""/><br /><sub><b>Burak</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/CarloDotLog"><img src="https://avatars.githubusercontent.com/u/13763473?v=4" width="100px;" alt=""/><br /><sub><b>Carlo Loguercio</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Frostedfox"><img src="https://avatars.githubusercontent.com/u/84601232?v=4" width="100px;" alt=""/><br /><sub><b>Frostedfox</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/hafeezrana"><img src="https://avatars.githubusercontent.com/u/87476445?v=4" width="100px;" alt=""/><br /><sub><b>Hafeez Rana</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/h1376h"><img src="https://avatars.githubusercontent.com/u/3498335?v=4" width="100px;" alt=""/><br /><sub><b>Hamed H.</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Jtplouffe"><img src="https://avatars.githubusercontent.com/u/32107801?v=4" width="100px;" alt=""/><br /><sub><b>JT</b></sub></a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ritksm"><img src="https://avatars.githubusercontent.com/u/111809?v=4" width="100px;" alt=""/><br /><sub><b>Jack Rivers</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/nohli"><img src="https://avatars.githubusercontent.com/u/43643339?v=4" width="100px;" alt=""/><br /><sub><b>Joachim Nohl</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/vothvovo"><img src="https://avatars.githubusercontent.com/u/20894472?v=4" width="100px;" alt=""/><br /><sub><b>Johnson</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/VoidxHoshi"><img src="https://avatars.githubusercontent.com/u/55886143?v=4" width="100px;" alt=""/><br /><sub><b>LaLucid</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/letyletylety"><img src="https://avatars.githubusercontent.com/u/16468579?v=4" width="100px;" alt=""/><br /><sub><b>Lety</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/lodisy"><img src="https://avatars.githubusercontent.com/u/8101584?v=4" width="100px;" alt=""/><br /><sub><b>Michael</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Moseco"><img src="https://avatars.githubusercontent.com/u/10720298?v=4" width="100px;" alt=""/><br /><sub><b>Moseco</b></sub></a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/inkomomutane"><img src="https://avatars.githubusercontent.com/u/57417802?v=4" width="100px;" alt=""/><br /><sub><b>Nelson  Mutane</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/oscarpalomar"><img src="https://avatars.githubusercontent.com/u/13899772?v=4" width="100px;" alt=""/><br /><sub><b>Oscar Palomar</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Viper-Bit"><img src="https://avatars.githubusercontent.com/u/24822764?v=4" width="100px;" alt=""/><br /><sub><b>Peyman</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/leisim"><img src="https://avatars.githubusercontent.com/u/13610195?v=4" width="100px;" alt=""/><br /><sub><b>Simon Choi</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ika020202"><img src="https://avatars.githubusercontent.com/u/42883378?v=4" width="100px;" alt=""/><br /><sub><b>Ura</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/blendthink"><img src="https://avatars.githubusercontent.com/u/32213113?v=4" width="100px;" alt=""/><br /><sub><b>blendthink</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mnkeis"><img src="https://avatars.githubusercontent.com/u/41247357?v=4" width="100px;" alt=""/><br /><sub><b>mnkeis</b></sub></a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/nobkd"><img src="https://avatars.githubusercontent.com/u/44443899?v=4" width="100px;" alt=""/><br /><sub><b>nobkd</b></sub></a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

### License

```
Copyright 2023 Simon Choi

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
