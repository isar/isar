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
  <a href="https://github.com/isar/isar/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/hivedb/hive?color=%23007A88&labelColor=333940&logo=apache">
  </a>
</p>

<p align="center">
  <a href="https://isar.dev">Quickstart</a> •
  <a href="https://isar.dev/schema">Documentation</a> •
  <a href="https://isar.dev">Examples</a> •
  <a href="https://github.com/isar/isar/discussions">Support & Ideas</a> •
  <a href="https://pub.dev/packages/isar">Pub.dev</a>
</p>

<p align="center">🚧 Very unstable and not ready for serious usage 🚧<p>

> Isar is a fast and easy to use database for Flutter apps that offers a powerful query language.

- ⚡️ **Launch your app instantly** no matter how much data you have
- 📈 **Highly scalable** from hundreds to tens of thousands of records
- 😎 **Lazy loaded**. Only load data when you need it
- 🧪 **Full ACID semantics**. Rely on consistency
- 📱 **Multiplatform**. iOS, Android, and the web (soon™)
- 💙 **Made for Flutter.** Easily use it in your Flutter app
- ⏱ **Asynchronous.** Parallel query operations & multi-isolate support
- ⚠️ **Static typing** with compile time checked and autocompleted queries

### Schema definition
```dart
@Collection()
class Person with IsarObject {

  @Index(unique: true)
  String name;
  
  int age;
}
```

### Query
```dart
final isar = await openIsar();

final result = isar.users.where()
  .sortedByName() // use index
  .filter()
  .ageGreaterThan(20)
  .beginGroup()
    .nameEqualTo("Paul")
    .or()
    .nameEqualTo("Lisa")
  .endGroup()
  .findAll()
```
