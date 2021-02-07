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
- 🔎 **Full text search**. Make searching fast and fun
- 📱 **Multiplatform**. iOS, Android, Desktop and the web (soon™)
- 💙 **Made for Flutter.** Easily use it in your Flutter app
- 🧪 **ACID semantics**. Rely on consistency
- ⏱ **Asynchronous.** Parallel query operations & multi-isolate support
- ⚠️ **Static typing** with compile time checked and autocompleted queries

### Schema definition
```dart
@Collection()
class Post with IsarObject {

  @ObjectId() // implicit unique index
  String uuid;

  @Index(stringType: StringIndexType.words, caseSensitive: false) // Search index
  String title;

  List<String> comments
}
```

### CRUD operations

All basic crud operations are available via the IsarCollection.

```dart
final newPost = Post()
  ..id = uuid()
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

### Query

Isar has a powerful query language that allows you to make use of your indexes, filter distinct objects, use complex `and()` and `or()` groups and sort the results. 

```dart
final isar = await openIsar();

final databasePosts = isar.posts
  .where()
  .titleWordBeginsWith('dAtAb') // use search index
  .limit(10)
  .findAll()

final postsWithFirstCommentOrTitle = isar.posts
  .where()
  .sortedById() // use implicit ObjectId index
  .filter()
  .commentsAnyEqualTo('first', caseSensitive: false)
  .or()
  .titleEqualTo('first')
  .findAll();
```

### Watch

With Isar you can watch Collections, Objects or Queries. A watcher is notified after a transactions commits succesfully and the target actually changes.
Watchers can be lazy and not reload the data or they can be non-lazy and fetch the new results in background.

```dart
Stream<void> collectionStream = isar.posts.watch(lazy: true);

Stream<List<Post>> queryStream = databasePosts.watch(lazy: false);

queryStream.listen((newResult) {
  // do UI updates
})
```