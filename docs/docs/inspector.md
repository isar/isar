---
title: Isar Inspector
---

# Isar Database Inspector

The Isar Inspector allows you to inspect the Isar instances & collections of your app in real-time. You can execute queries, switch between instances and sort the data. Works on all platforms 💪 and you don't have to install it.

```dart

final isar = await Isar.open(
  schemas: [EmailSchema],
  directory: dir.path,
  inspector:true, // That's it.
);
```

<img src="https://raw.githubusercontent.com/isar/isar/main/.github/assets/isar-inspector.png?sanitize=true">
