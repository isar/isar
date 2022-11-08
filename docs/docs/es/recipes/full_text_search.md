---
title: Full-text search
---

# Full-text search

Full-text search es una manera poderosa de buscar texto en la base de datos. Ya deberías estar familiarizado con la forma en que funcionan los [índices](/es/indexes), pero vayamos sobre lo básico.

Un índice funciona como una tabla de lookup, permitiéndole al motor de consulta encontrar rápidamente registros con un cierto valor. Por ejemplo, si tienes un campo `title` en tu objeto, puedes crear un índice en ese campo para hacer más rápida la búsqueda de objetos con un título determinado.

## Porqué full-text search es útil?

Puedes buscar texto fácilmente usando filtros. Existen algunas operaciones sobre string como por ejemplo `.startsWith()`, `.contains()` y `.matches()`. El problema con los filtros es que su tiempo de ejecución es de `O(n)` donde `n` es la cantidad de registros en la colección. Operaciones sobre strings como `.matches()` son especialmente costosas.

:::tip
Full-text search es mucho más rápido que los filtros, pero los índices tienen cietas limitaciones. En este receta vamos a explorar cómo sobrepasar esas limitaciones.
:::

## Exemplo básico

La idea es siempre la misma: En lugar de indexar el texto completo, indexamos las palabras en el texto así podemos buscar por ellos individualmente.

Creamos el índice full-text más básico:

```dart
class Message {
  Id? id;

  late String content;

  @Index()
  List<String> get contentWords => content.split(' ');
}
```

Ahora podemos buscar mensajes que contengan palabras específicas en el contenido:

```dart
final posts = await isar.messages
  .where()
  .contentWordsAnyEqualTo('hello')
  .findAll();
```

Esta consulta es súper rápida, pero existen algunos problemas:

1. Sólo podemos buscar palabras completas
2. No consideramos puntuación
3. No soportamos otros caracteres de separación de palabras

## Separando el texto de la forma correcta

Intentemos mejorar el ejemplo anterior. Podemos intentar desarrollar una expresión regular complicada para correjir la separación de las palabras, pero sería lento e incorrecto para casos de borde.

El [Anexo Unicode #29](https://unicode.org/reports/tr29/) define cómo separar palabras correctamente para la mayoría de los idiomas. Es algo complicado, pero afortunadamente Isar hace el trabajo pesado por nosotros:

```dart
Isar.splitWords('hello world'); // -> ['hello', 'world']

Isar.splitWords('The quick (“brown”) fox can’t jump 32.3 feet, right?');
// -> ['The', 'quick', 'brown', 'fox', 'can’t', 'jump', '32.3', 'feet', 'right']
```

## Quiero más control

Pan comido! Podemos cambiar nuestro índice para soportar también coincidencia por prefijo y por mayúsculas y minúsculas:

```dart
class Post {
  Id? id;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get titleWords => title.split(' ');
}
```

De manera predeterminada, Isar almacenará las palabras como valores hash que es rápido y eficiente en cuanto a espacio. Pero los hashes nos pueden usarse para coincidencia por prefijo. Usando `IndexType.value`, podemos cambiar el índice para usar las palabras directamente. Ésto nos ofrece la cláusula `.titleWordsAnyStartsWith()`:

```dart
final posts = await isar.posts
  .where()
  .titleWordsAnyStartsWith('hel')
  .or()
  .titleWordsAnyStartsWith('welco')
  .or()
  .titleWordsAnyStartsWith('howd')
  .findAll();
```

## También necesito `.endsWith()`

Por supuesto! Usaremos un truco para conseguir la coincidencia `.endsWith()`:

```dart
class Post {
    Id? id;

    late String title;

    @Index(type: IndexType.value, caseSensitive: false)
    List<String> get revTitleWords {
        return Isar.splitWords(title).map(
          (word) => word.reversed).toList()
        );
    }
}
```

No olvides invertir la terminación que quieres buscar:

```dart
final posts = await isar.posts
  .where()
  .revTitleWordsAnyStartsWith('lcome'.reversed)
  .findAll();
```

## Algoritmos de derivación

Desafortunadamente, los índices no soportan coincidencia por `.contains()` (ésto también es cierto para otras bases de datos). Pero existen algunas alternativas que vale la pena explorar. La elección depende fuertemente de su uso. Un ejemplo es indexar la raíz de la palabra en de la misma completa.

Un algoritmo de derivación (stemming algorithm) es un proceso de normalización linguística en el cual las diferentes formas de una palabra se reducen a una forma común:

```
connection
connections
connective          --->   connect
connected
connecting
```

Algoritmos populares son el [Porter stemming algorithm](https://tartarus.org/martin/PorterStemmer/) y el [Snowball stemming algorithms](https://snowballstem.org/algorithms/).

Existen también formas avanzadas como [lematización](https://es.wikipedia.org/wiki/Lematizaci%C3%B3n).

## Algoritmos de fonética

Un [algoritmo de fonética](https://en.wikipedia.org/wiki/Phonetic_algorithm) es un algoritmo para indexar palabras de acuerdo a su pronunciación. Es decir, te permite encontrar palabras que "suenan" parecido a las que estás buscando.

:::warning
La mayoría de los algoritmos de fonética sólo soportan un solo idioma.
:::

### Soundex

[Soundex](https://es.wikipedia.org/wiki/Soundex) es un algoritmo de fonética para indexar nombres por sonido, como se pronuncian en inglés. El objetivo es que los homófonos se codifiquen con la misma representación para que produzcan coincidencias a pesar de alguna menor diferencia de tipeo. Es un algoritmo directo, y existen múltiples versiones mejoradas.

Usando este algoritmo, ambos `"Robert"` y `"Rupert"` retornan la cadena `"R163"` mientras que `"Rubin"` entrega `"R150"`. `"Ashcraft"` y `"Ashcroft"` ambos entregan `"A261"`.

### Metáfono doble

El algoritmo de codificado fonético [Metáfono doble](https://es.wikipedia.org/wiki/Metaphone) es la segunda generación de este tipo de algoritmos. Contiene varias mejoras fundamentales de diseño sobre el algoritmo de metáfono original.

Doble Metáfono da cuenta de varias irregularidades en inglés de eslavo, alemán, celta, griego, francés, italiano, español, chino, y otros orígenes.
