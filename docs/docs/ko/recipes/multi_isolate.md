---
title: 다중-Isolate 사용법
---

# 다중-Isolate 사용법

스레드 대신, 모든 다트 코드는 isolate 안에서 돌아갑니다. 각 isolate 에는 고유한 메모리 힙이 있으므로, isolate 의 어떤 상태도 다른 isolate 에서 접근할 수 없습니다.

Isar can be accessed from multiple isolates at the same time, and even watchers work across isolates. In this recipe, we will check out how to use Isar in a multi-isolate environment.

## When to use multiple isolates

Isar transactions are executed in parallel even if they run in the same isolate. In some cases, it is still beneficial to access Isar from multiple isolates.

The reason is that Isar spends quite some time encoding and decoding data from and to Dart objects. You can think of it as encoding and decoding JSON (just more efficient). These operations run inside the isolate from which the data is accessed and naturally block other code in the isolate. In other words: Isar performs some of the work in your Dart isolate.

If you only need to read or write a few hundred objects at once, doing it in the UI isolate is not a problem. But for huge transactions or if the UI thread is already busy, you should consider using a separate isolate.

## Example

The first thing we need to do is to open Isar in the new isolate. Since the instance of Isar is already open in the main isolate, `Isar.open()` will return the same instance.

:::warning
Make sure to provide the same schemas as in the main isolate. Otherwise, you will get an error.
:::

`compute()` starts a new isolate in Flutter and runs the given function in it.

```dart
void main() {
  // Open Isar in the UI isolate
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [MessageSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  // listen to changes in the database
  isar.messages.watchLazy(() {
    print('omg the messages changed!');
  });

  // start a new isolate and create 10000 messages
  compute(createDummyMessages, 10000).then(() {
    print('isolate finished');
  });

  // after some time:
  // > omg the messages changed!
  // > isolate finished
}

// function that will be executed in the new isolate
Future createDummyMessages(int count) async {
  // we don't need the path here because the instance is already open
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [PostSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Message $i');
  // we use a synchronous transactions in isolates
  isar.writeTxnSync(() {
    isar.messages.insertAllSync(messages);
  });
}
```

There are a few interesting things to note in the example above:

- `isar.messages.watchLazy()` is called in the UI isolate and is notified of changes from another isolate.
- Instances are referenced by name. The default name is `default`, but in this example, we set it to `myInstance`.
- We used a synchronous transaction to create the mesasges. Blocking our new isolate is no problem, and synchronous transactions are a little faster.
