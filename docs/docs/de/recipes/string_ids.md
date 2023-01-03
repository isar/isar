---
title: String-IDs
---

# String-IDs

Das hier ist eine der häufigsten Anfragen, die ich erhalte, daher ist hier ein Tutorial zur Verwendung von String-IDs.

Isar unterstützt String-IDs nicht nativ, was einen guten Grund hat: Integer-IDs sind viel effizienter und schneller. Besonders bei Links ist der Overhead einer String-ID zu signifikant.

Ich verstehe, dass du manchmal externe Daten speichern musst, die UUIDs oder andere nicht-Integer-IDs verwenden. Ich empfehle, die String-ID als Eigenschaft in deinem Objekt zu speichern und eine schnelle Hash-Implementation um 64-bit Integer zu generieren und als ID zu verwenden.

```dart
@collection
class User {
  String? id;

  Id get isarId => fastHash(id!);

  String? name;

  int? age;
}
```

Mit diesem Ansatz bekommst du das Beste aus beiden Welten: Effiziente Integer-IDs für Links und die Fähigkeit String-IDs zu nutzen.

## Schnelle Hash-Funktion

Idealerweise sollte deine Hash-Funktion eine hohe Qualität haben (du willst keine Kollisionen) und schnell sein. Ich empfehle die folgende Implementation:

```dart
/// FNV-1a 64bit Hash-Algorithmus optimiert für Dart-Strings
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

Wenn du eine andere Hash-Funktion wählst, stelle sicher, dass sie einen 64-bit Integer zurückgibt und vermeide kryptographische Hash-Funktionen, weil die sehr viel langsamer sind.

:::warning
Vermeide es `string.hashCode` zu verwenden, weil nicht garantiert werden kann, dass die Methode über verschiedenen Plattformen und Versionen von Dart hinweg stabil ist.
:::
