---
title: String ids
---

# String ids

This is one of the most frequent requests I get, so here is a tutorial on using String ids.

Isar does not natively support String ids, and there is a good reason for it: integer ids are much more efficient and faster. Especially for links, the overhead of a String id is too significant.

I understand that sometimes you have to store external data that uses UUIDs or other non-integer ids. I recommend storing the String id as a property in your object and using a fast hash implementation to generate a 64-bit int that can be used as Id.

```dart
@collection
class User {
  String? id;

  Id get isarId => fastHash(id!);

  String? name;

  int? age;
}
```

With this approach, you get the best of both worlds: Efficient integer ids for links and the ability to use String ids.

## Fast hash function

Ideally, your hash function should have high quality (you don't want collisions) and be fast. I recommend using the following implementation:

```dart
/// FNV-1a 64bit hash algorithm optimized for Dart Strings
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

If you choose a different hash function, ensure it returns a 64-bit int and avoid using a cryptographic hash function because they are much slower.

:::warning
Avoid using `string.hashCode` because it is not guaranteed to be stable across different platforms and versions of Dart.
:::
