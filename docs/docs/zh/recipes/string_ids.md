---
title: 字符串id
---

# 字符串id

这是我最常收到的请求之一，所以这里是关于使用字符串id的教程。

Isar不支持字符串id，理由很简单：整数id效率更高、速度更快。特别是对于链接来说，字符串id的开销太大。

我理解，有时你必须存储使用UUID或其他非整数ID的外部数据。我建议将字符串id作为一个字段存储在你的对象中，并使用一个快速的哈希算法来生成一个64位的int，可以作为Id使用。

```dart
@collection
class User {
  String? id;

  Id get isarId => fastHash(id!);

  String? name;

  int? age;
}
```

通过这种方法，你可以得到两方面的好处：为链接提供高效的整数id，同时也可以使用字符串id。

## 快速哈希方法

理想情况下，你的哈希函数应该有很高的质量（你不希望有碰撞），而且速度要快。我建议使用下面的实现：

```dart
/// 为Dart字符串优化的64位FNV-1a哈希算法
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

如果你选择一个不同的哈希函数，确保它返回一个64位的int，并应该避免使用加密哈希函数，因为它们要慢得多。

:::warning
避免使用`string.hashCode`，因为它不能保证在不同的平台和Dart的版本中都是稳定的。
:::
