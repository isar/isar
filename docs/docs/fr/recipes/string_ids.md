---
title: Identifiants en chaîne de caractères
---

# Identifiants en chaîne de caractères

C'est l'une des demandes les plus fréquemment reçues. Voici donc un tutoriel sur l'utilisation des ids en `String`.

Isar ne supporte pas nativement les ids `String`, et il y a une bonne raison à cela: les ids entiers sont beaucoup plus efficaces et rapides. En particulier pour les liens, la complexité d'un identifiant de type `String` est trop importante.

Il arrive parfois que l'on doive stocker des données externes qui utilisent des UUID ou autres identifiants non entiers. Il est recommandé de stocker la chaîne id comme une propriété de votre objet et d'utiliser une implémentation de hachage rapide pour générer un int 64 bits qui peut être utilisé comme Id.

```dart
@collection
class User {
  String? id;

  Id get isarId => fastHash(id!);

  String? name;

  int? age;
}
```

Avec cette approche, nous obtenons le meilleur des deux mondes: des identifiants entiers efficaces pour les liens et la possibilité d'utiliser des identifiants de type `String`.

## Fonction de hachage rapide

Idéalement, notre fonction de hachage devrait avoir une haute qualité (nous ne voulons pas de collisions) et être rapide. Il est recommandé d'utiliser l'implémentation suivante:

```dart
/// Algorithme de hachage FNV-1a 64 bits optimisé pour les chaînes de caractères Dart
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

Si vous choisissez une fonction de hachage différente, assurez-vous qu'elle renvoie un int 64 bits et évitez d'utiliser une fonction de hachage cryptographique, car elle est beaucoup plus lente.

:::warning
Évitez d'utiliser `string.hashCode`, car sa stabilité n'est pas garantie sur les différentes plateformes et versions de Dart.
:::