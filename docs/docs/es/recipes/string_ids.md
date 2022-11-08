---
title: Ids de texto
---

# Ids de texto

Esta es uno de los pedidos más frecuentes para Isar, por eso les dejamos este tutorial sobre como usar ids de texto.

Isar no soporta ids de texto de forma nativa, y existe una buena razón para eso: los ids de enteros son mucho más eficientes y rápidos. Especialmente para enlaces, el gasto de un id de texto es demasiado significativo.

Es probable que necesites almacenar datos externos que usen UUIDs o otro id no entero. Se recomienda almacenar el id de texto como una propiedad del objeto y usar una función rápida de hash para generar un entero de 64 bits que pueda ser usado como Id.

```dart
@collection
class User {
  String? id;

  Id get isarId => fastHash(id!);

  String? name;

  int? age;
}
```

De esta maneras obtienes lo mejor de dos mundos: Ids enteros eficientes para los enlaces y la posibilidad de usar ids de texto.

## Función rápida de hash

Idealmente, tu función de hash debería ser rápida y de alta calidad (sin colisiones). La siguiente es una implementación recomendada:

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

Si eliges una función de hash diferente, asegúrate de que retorne un entero de 64-bit. Evita usar funciones hash criptográficas porque son mucho más lentas.

:::warning
Evita usar `string.hashCode` porque no está garantizada la estabilidad entre distintas plataformas y versiones de Dart.
:::
