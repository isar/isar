---
title: Multi-Isolate usage
---

# Multi-Isolate usage

Instead of threads, all Dart code runs inside of isolates. Each isolate has its own memory heap, ensuring that none of the state in an isolate is accessible from any other isolate.

Isar can be accessed from multiple isolates at the same time and even watchers work across isolates. In this recipe we will check out how to use Isar in a multi-isolate environment.

## When to use multiple isolates

Isar transactions are executed in parallel even if they run in the same isolate. In some cases it is still beneficial to access Isar from multiple isolates.

The reason is that Isar spends quite some time on encoding and decoding data from and to Dart objects. You can think of it like encoding and decoding JSON (just more efficient). These operations run inside the isolate from which the data is accessed and naturally block other code in the isolate. In other words: Isar performs some of the work in your Dart isolate.

If you only need to read or write a few hundred objects at once, it is fine to do it in the UI isolate. But if you have huge transactions or the UI thread is already busy, you should consider using a separate isolate.

## Example

The first thing we need to do is to open Isar in the new isolate. Since the instance of Isar is already open in the main isolate, `Isar.open()` will return the same instance.

`compute()` starts a new isolate in Flutter and runs the given function in it.

```dart
void main() {
    final dir = await getApplicationSupportDirectory();

    // Open Isar in the UI isolate
    final isar = await Isar.open(
        name: 'myInstance',
        schemas: [PostSchema],
        path: dir.path,
    );

    // listen to changes in the database
    isar.posts.watchLazy(() {
        print('omg the posts changed!');
    });

    // start a new isolate and create 10000 posts
    compute(createDummyPosts, 10000).then(() {
        print('isolate finished');
    });

    // after some time:
    // > omg the posts changed!
    // > isolate finished
}

// function that will be executed in the new isolate
Future createDummyPosts(int count) async {
    // we don't need the path here because the instance is already open
    final isar = await Isar.open(
        name: 'myInstance',
        schemas: [PostSchema],
    );

    final posts = List.generate(count, (i) => Post()..title = 'Post $i');
    // we use a synchronous transactions in isolates
    isar.writeTxnSync((isar) {
        isar.posts.insertAllSync(posts);
    });
}
```

There are a few interesting things to note in the example above:

- `isar.posts.watchLazy()` is called in the UI isolate and is notified even if the posts are changed in another isolate.
- We did not need to specify the path of the instance because it is already open in the main isolate.
- Instances are referenced by name. The default name is `isar` but in this example we set it to `myInstance`.
- We used a synchronous transaction to create the posts. Blocking our new isolate is no problem and synchronous transactions are a little faster.
