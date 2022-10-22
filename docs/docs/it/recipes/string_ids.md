---
title: ID stringa
---

# ID stringa

Questa è una delle richieste più frequenti che ricevo, quindi ecco un tutorial sull'uso di String ID.

Isar non supporta nativamente gli ID di stringa e c'è una buona ragione: gli ID interi sono molto più efficienti e veloci. Soprattutto per i collegamenti, l'overhead di un ID stringa è troppo significativo.

Comprendo che a volte devi archiviare dati esterni che utilizzano UUID o altri ID non interi. Consiglio di archiviare l'ID String come proprietà nell'oggetto e di utilizzare un'implementazione hash veloce per generare un int a 64 bit che può essere utilizzato come ID.

```dart
@collection
class User {
  String? id;

  Id get isarId => fastHash(id!);

  String? name;

  int? age;
}
```

Con questo approccio, ottieni il meglio da entrambi i mondi: ID interi efficienti per i collegamenti e la possibilità di utilizzare ID di stringa.

## Funzione hash veloce

Idealmente, la tua funzione hash dovrebbe avere un'alta qualità (non vuoi collisioni) ed essere veloce. Consiglio di utilizzare la seguente implementazione:

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

Se scegli una funzione hash diversa, assicurati che restituisca un int a 64 bit ed evita di usare una funzione hash crittografica perché sono molto più lente.

:::warning
Evita di usare `string.hashCode` perché non è garantito che sia stabile su piattaforme e versioni diverse di Dart.
:::