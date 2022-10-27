---
title: 字符串 Id
---

# 字符串 Id

这是我遇到的最常见的请求之一，所以就有了这篇教程。

Isar 原生不支持字符串 Id，这是经过深思熟虑的：原因是整型 Id 比字符串 Id 性能更好。尤其是在处理关联上，使用字符串 Id 会显著增加额外的性能开销。

我理解，有时候你需要存储一些使用 UUID 或非整型 Id 的数据。我建议将这些字符串 Id 作为对象的属性，并用其快速散列化后的 64 位整型作为 Isar 对象的 Id。

```dart
@collection
class User {
  String? id;

  Id get isarId => fastHash(id!);

  String? name;

  int? age;
}
```

通过这个办法，你既可以高效地使用整型 Id 来处理关联，又保留了原有数据中的字符串 Id。

## 快速散列函数

理想情况下，你的散列函数应该兼具高可用性（没人希望崩溃或意外发生）和高性能。我推荐使用下方代码实现：

```dart
/// 针对 Dart 字符串优化的 64 位哈希算法 FNV-1a
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
```

如果你选择其他散列函数，确保它返回 64 位整型，避免使用加密散列函数，因为它们非常慢。

:::warning
避免使用 `string.hashCode`，因为无法保证它能够适用于各个平台，或适配各个版本的 Dart。
:::
