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
  <a href="">Getting Started</a> •
  <a href="">Documentation</a> •
  <a href="">Examples</a> •
  <a href="https://github.com/isar/isar/discussions">Support & Ideas</a> •
  <a href="https://pub.dev/packages/isar">Pub.dev</a>
</p>

<p align="center">⚠️ Very unstable and not ready for serious usage ⚠<p>

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
