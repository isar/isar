---
title: Consultas
---

# Consultas

Las consultas se utilizan para buscar registros que coincidan con ciertas condiciones, por ejemplo:

- Buscar todos los contactos favoritos
- Buscar contactos con nombre distinto
- Borrar todos los contactos que no tengan definido un apellido

Dado que las consultas se ejecutan en la base de datos y no en Dart, son realmente rápidas. Si utilizas índices de manera inteligente, puedes mejorar el rendimiento de las consultas todavía más. A continuación, aprederás cómo esribir consultas y cómo lograr que sean lo más rápidas posible.

Existen dos métodos diferentes para firltrar tus registros: Filtros y cláusulas where. Comenzaremos hechando un vistazo a cómo funcionan los filtros.

## Filtros

Los filtros son fáciles de usar y de entener. Dependiendo del tipo de tus propiedades, existen operaciones de filtrado diferentes con nombres bien definidos.

Los filtros funcionan evaluando una expresión para cada objeto en la colección que está siendo filtrada. Si la expresión resuelve en verdadero, Isar incluye el objeto en los resultados. Los filtros no afectan el orden de los resultados.

Usaremos el modelo siguiente para los ejemplos:

```dart
@collection
class Shoe {
  Id? id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### Query conditions

Dependiendo del tipo de campo, tienes diferentes condiciones disponibles.

| Condición                | Descripción                                                                                                                                                 |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.equalTo(value)`        | Coincide con valores que son iguales a `value`.                                                                                                             |
| `.between(lower, upper)` | Conicide con valores que están entre `lower` y `upper`.                                                                                                     |
| `.greaterThan(bound)`    | Coincide con valores que son mayores que `bound`.                                                                                                           |
| `.lessThan(bound)`       | Coincide con valores que son menores que `bound`. Los valores `null` serán incluídos por defecto ya que `null` se considera menor que cualquier otro valor. |
| `.isNull()`              | Coincide con valores `null`.                                                                                                                                |
| `.isNotNull()`           | Coindice con valores que no son `null`.                                                                                                                     |
| `.length()`              | Las consultas de tamaño de listas, strings y links filtran objectos basados en el número de elementos en una lista o link.                                  |

Asumeindo que la base de datos contiene cuatro zapatos de talle 39, 40, 46 y uno con talle no asignado (`null`). A menos que utilice orden de resultados, los valores serán ordenados por su id.

```dart

isar.shoes.filter()
  .sizeLessThan(40)
  .findAll() // -> [39, null]

isar.shoes.filter()
  .sizeLessThan(40, include: true)
  .findAll() // -> [39, null, 40]

isar.shoes.filter()
  .sizeBetween(39, 46, includeLower: false)
  .findAll() // -> [40, 46]

```

### Operadores lógicos

Puedes encadenar expresiones usando los operadores lógicos siguientes:

| Operador   | Descripción                                                                          |
| ---------- | ------------------------------------------------------------------------------------ |
| `.and()`   | Se evalúa como verdadero si ambas expresiones de izquierda y derecha son verdaderas. |
| `.or()`    | Se evalúa como verdadero si alguna de las expresiones es verdadera.                  |
| `.xor()`   | Se evalúa como verdadero si sólo una de las expresiones es verdadera.                |
| `.not()`   | Invierte (niega) el resultado de la expresión siguiente.                             |
| `.group()` | Agrupa condiciones y permite especificar un orden de evaluación.                     |

Si quieres buscar todos los zapatos de talle 46, puedes hacer lo siguiqnte:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

Si quieres usar más de una condición, puedes combinar múltiples filtros usando los operadores **and** `.and()`, **or** `.or()` y **xor** `.xor()`.

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // Optional. Filters are implicitly combined with logical and.
  .isUnisexEqualTo(true)
  .findAll();
```

Esta consulta es equivalente a: `size == 46 && isUnisex == true`.

También puedes agrupar condiciones usando `.group()`:

```dart
final result = await isar.shoes.filter()
  .sizeBetween(43, 46)
  .and()
  .group((q) => q
    .modelNameContains('Nike')
    .or()
    .isUnisexEqualTo(false)
  )
  .findAll()
```

Esta consulta es equivalente a `size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)`.

Para negar una condición o grupo, usa el operador lógico **not** `.not()`:

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

Esta consulta es equivalente a `size != 46 && isUnisex != true`.

### Condiciones sobre Strings

Adicionalmente a las condiciones mencionadas anteriormente, los valores de tipo String ofrecen algunas condiciones más. Por ejemplo, los comodines para expresiones regulares permiten mayor flexibilidad en las búsquedas.

| Condition            | Description                                         |
| -------------------- | --------------------------------------------------- |
| `.startsWith(value)` | Coincide con strings que comiencen con `value`.     |
| `.contains(value)`   | Coincide con strings que contengan `value`.         |
| `.endsWith(value)`   | Coincide con strings que terminen con `value`.      |
| `.matches(wildcard)` | Coincide según la evaluación del patrón `wildcard`. |

**Sensibilidad a las mayúsculas y minúsculas**  
Todas las operaciones con strings tienen un parámetro opcional `caseSensitive` para distinguir entre mayúsculas y minúsculas que por defecto está seteado en verdadero.

**Comodines:**  
Una [expresión comodín](https://es.wikipedia.org/wiki/Car%C3%A1cter_comod%C3%ADn) es una cadena de texto (string) que utiliza caracteres normales combinados con dos caracteres especiales comodines:

- El comodín `*` coincide con ninguno o más de cualquier caracter.
- El comodín `?` coincide con un caracter cualquiera.
  Por ejemplo, la cadena comodín `"d?g"` coincide con `"dog"`, `"dig"`, y `"dug"`, Pero no con `"ding"`, `"dg"`, o `"a dog"`.

### Modificadores de consultas

A veces es necesario construir una consulta basándose en algunas condiciones o para diferentes valores. Isar posee una herramienta muy poderosa para construir consultas condicionales:

| Modificador           | Descripción                                                                                                                                                                                  |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.optional(cond, qb)` | Extiende la consulta únicamente si la `condición` es verdadera. Esto puede usarse en cualquier lugar en una consulta, por ejemplo para aplicar ordenamiento o límites de manera condicional. |
| `.anyOf(list, qb)`    | Extiende la consulta para cada valor en `values` y combina las condiciones usando el operador lógico **or**.                                                                                 |
| `.allOf(list, qb)`    | Extiende la consulta para cada valor en `values` y combina las condiciones usando el operador lógico **and**.                                                                                |

En este ejemplo, construiremos un método que puede buscar zapatos con un filtro opcional:

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // only apply filter if sizeFilter != null
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

Si quieres buscar zapatos entre múltiples talles, puedes usar una consulta convencional o usar el modificador `anyOf()`:

```dart
final shoes1 = await isar.shoes.filter()
  .sizeEqualTo(38)
  .or()
  .sizeEqualTo(40)
  .or()
  .sizeEqualTo(42)
  .findAll();

final shoes2 = await isar.shoes.filter()
  .anyOf(
    [38, 40, 42],
    (q, int size) => q.sizeEqualTo(size)
  ).findAll();

// shoes1 == shoes2
```

Los modificadores de consultas son especialmente útiles si quieres construir consultas dinámicas.

### Listas

Incluso se puede construir consultas sobre listas:

```dart
class Tweet {
  Id? id;

  String? text;

  List<String> hashtags = [];
}
```

Puedes consultar basándote en la longitud de la lista:

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

Éstos son equivalenets al código Dart `tweets.where((t) => t.hashtags.isEmpty);` y `tweets.where((t) => t.hashtags.length > 5);`. También puedes consultar basándote en los elementos de la lista:

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

Esto es equivalente al código Dart `tweets.where((t) => t.hashtags.contains('flutter'));`.

### Objetos embebidos

Los objetos embebidos son una de las funcionalidades más útiles de Isar. Se pueden consultar de manera muy eficiente usando las mismas condiciones disponibles para los objetos raíz. Asumiendo que tenemos el siguiente modelo:

```dart
@collection
class Car {
  Id? id;

  Brand? brand;
}

@embedded
class Brand {
  String? name;

  String? country;
}
```

Necesitamos consultar todos los autos que sean de la marca `"BMW"` y del país `"Germany"`. Podemos hacerlo con la siguiente consulta:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

Siempre trata de agrupar las consultas anidadas. La consulta anterior es más eficiente que ésta siguiente auque el resultado es el mismo:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### Enlaces

Si tus modelos contienen [links or backlinks](links) puedes filtrar tus consultas basándote en el objeto enlazado o la cantidad de objetos enlazados.

:::warning
Ten en cuenta que las consultas sobre enlaces pueden ser costosas ya que Isar necesita buscar en los objetos enlazados. Considera usar objetos embebidos en su lugar.
:::

```dart
@collection
class Teacher {
  Id? id;

  late String subject;
}

@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

Podemos buscar todos los estudiantes que tienen un maestro de Matemáticas o de Inglés:

```dart
final result = await isar.students.filter()
  .teachers((q) {
    return q.subjectEqualTo('Math')
      .or()
      .subjectEqualTo('English');
  }).findAll();
```

Los filtros sobre enlaces se evalúan en verdadero si al menos unos de los objetos enlazados coincide con la condición.

Busquemos todos los estudiantes que no tienen maestro:

```dart
final result = await isar.students.filter().teachersLengthEqualTo(0).findAll();
```

o:

```dart
final result = await isar.students.filter().teachersIsEmpty().findAll();
```

## Cláusulas `where`

Las cláusulas `where` son una herramienta muy poderosa, pero puede ser algo desafiante lograr usarlas de la manera correcta.

En contraste con los filtros, las cláusulas `where` usan los índices que definiste en el esquema para verificar las condiciones de la consulta. Consultar un índice es mucho más rápido que filtrar cada registro individualmente.

➡️ Ver más en: [Índices](indexes)

:::tip
Como regla básica, deberías intentar reducir la cantidad de registros lo mayor posible usando cláusulas `where` y luego hacer el filtrado restante usando filtros.
:::

Sólo puedes combinar cláusulas `where` usando operaciones lógicas **or**. En otras palabras, puedes sumar múltiples cláusulas `where`, pero no puedes consultar la intersección de múltiples de ellas.

Agreguemos ídices a nuestra colección shoe:

```dart
@collection
class Shoe with IsarObject {
  Id? id;

  @Index()
  Id? size;

  late String model;

  @Index(composite: [CompositeIndex('size')])
  late bool isUnisex;
}
```

Tenemos dos índices. El índice en `size` nos permite usar cláusulas `where` como `.sizeEqualTo()`. El índice compuesto en `isUnisex` nos permite usar cláusulas como `isUnisexSizeEqualTo()`. Pero también `isUnisexEqualTo()` porque siempre puedes usar cualquier prefijo de un índice.

Ahora podemos reescribir la consulta anterior que busca zapatos unisex de talle 46 usando el índice compuesto. Esta consulta será mucho más rápida que la anterior:

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

Las cláusulas `where` tienen dos superpoderes adicionales: Te brindad ordenado "libre" y una súper rápida operación `distinct`.

### Combinando cláusulas `where` y filtros

Recuerdas la consulta `shoes.filter()`? Es en realidad un atajo para `shoes.where().filter()`. Puedes (y deberías) combinar cláusulas `where` y filtros en la misma consulta para usar los beneficios de ambos:

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

La cláusula `where` se aplica primero para reducir el número de objetos a ser filtrados. Luego se aplica el filtro a los objetos restantes.

## Ordenando

Puedes definir cómo se deben ordenar los resultados cuando se ejecuta una consulta usando los métodos `.sortBy()`, `.sortByDesc()`, `.thenBy()` y `.thenByDesc()`.

Para buscar todos los zapatos ordenados por nombre de modelo en orden ascendente sin usar un índice:

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

Ordenar un gran número de resultados puede ser costoso, especialmente dado que el ordenamiento sucede antes que el salto y los límites. Los métodos de ordenamiento anteriores nunca hacen uso de índices. Afortunadamente, también podemos hacer ordenamiento usando cláusulas `where` y hacer que nuestra consulta sea rápida como un rayo aún si tenemos que ordenar un millón de objetos.

### Ordenando con cláusulas `where`

Si usas una sola cláusula `where` en tu consulta, los resultados ya están ordenados por su índice. Eso ya es mucho!

Supongamos que tenemos zapatos en talle `[43, 39, 48, 40, 42, 45]` y queremos buscar todos los zapatos de talle mayor a `42` y además los queremos ordenados por talle:

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // also sorts the results by size
  .findAll(); // -> [43, 45, 48]
```

Como puedes ver, el resultado está ordenado por el índice `size`. Si quieres invertir el orden, puedes establecer `sort` a `Sort.desc`:

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

Es posible que no quieras usa la cláusula `where` pero sí beneficiarte del ordenamiento implícito. Puedes usar la cláusula `any`:

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

Si usas un índice compuesto, los resultados son ordenados según todos los campos en el índice.

:::tip
Si necesitas ordenar tus resultados, considera usar índices para eso. Especialmente si trabajas con `offset()` y `limit()`.
:::

A veces no es posible o no es útil usar índices para ordenar. En esos casos, usa índices para reducir el número de resultados lo más posible.

## Valores únicos

Para retornar sólo entradas con valores únicos, utiliza el predicado `distinct`. Por ejemplo, para saber cuántos modelos diferentes de zapatos tienes en base de datos Isar:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

También puedes encadenar múltiples condiciones `distinct` para buscar todos los zapatos con distinta combinación de modelo-talle:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

Sólo se retorna el primer valor de cada combinación distinta. Puedes usar cláusulas `where` y operaciones de ordenamiento para controlarlos.

### Cláusula `where` `distinct`

Si tienes un ídice que no es único, podrías querer obtener todos sus valores distintos. Podrías usar la operación `distinctBy` de la sección anterior, pero se ejecuta después del ordenamiento y filtrado, por lo que hay algunas operaciones adicionales.
Si solo usas una sola cláusula `where`, puedes por el contrario confiar en el índice para ejecutar la operación `distinct`.

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
En teoría, podrías incluso usar múltiples cláusulas `where` para ordenamiento y distintos. La única restricción es que aquellas cláusulas `where` no se superpongan y usen el mismo índice. Para un correcto ordenamiento, también tienen que ser aplicadas en el orden de ordenamiento. Debes ser muy cuidadoso si utilizas estos métodos!
:::

## Offset y Límite

A menudo es buena idea limitar el número de resultados de una consulta para vistas de listas perezosas. Puedes hacer esto estableciendo un `limit()`:

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

Estableciendo un `offset()` puedes también paginar los resultados de su consulta.

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

Dado que el instanciado de objetos Dart es a menudo la parte más costosa cuando se ejecuta una consulta, es una buena idea cargar sólo los objectos que necesitas.

## Orden de ejecución

Isar ejecuta las consultas siempre en el mismo orden:

1. Atravesar índices primarios o secundarios para buscar objetos (aplicar las cláusulas `where`)
2. Filtrar objetos
3. Ordenar resultados
4. Aplicar operaciones `distinct`
5. Aplicar `offset` y `limit` a los resultados
6. Retornar los resultados

## Operaciones de consulta

En los ejemplos anteriores, usamos `.findAll()` para recuperar todas las coincidencias de objectos. Sin embargo, hay más operaciones disponibles:

| Operaciones      | Descripción                                                                                                                    |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `.findFirst()`   | Recupera el primer objeto coincidente con la consulta o `null` si no se encontró ninguna.                                      |
| `.findAll()`     | Recupera todos los objetos para la consulta.                                                                                   |
| `.count()`       | Cuenta cuántos objetos coinciden con la consulta.                                                                              |
| `.deleteFirst()` | Elimina de la colección el primer objeto coincidente con la consulta.                                                          |
| `.deleteAll()`   | Elimina de la colección todos los objetos coincidentes con la consulta.                                                        |
| `.build()`       | Compila la consulta para ser usada luego. Esto ahorra el costo de contruir una consulta si tienes que ejecutarla muchas veces. |

## Consulta de propiedades

Si estás interesado solamente en los valores de un propiedad simple, puedes usar consulta de propiedades. Simplemente construye una consulta regular y selecciona una propiedad:

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

Usar una sola propiedad ahora tiempo durante el deserializado. Las consultas de propiedades también funcionan para los objetos embebidos y las listas.

## Agregación

Isar soporta el agregado de los valores de una consulta de propiedad. Las siguientes operaciones de agregación están disponibles:

| Operación    | Descripción                                                           |
| ------------ | --------------------------------------------------------------------- |
| `.min()`     | Busca el valor mínimo o `null` si ninguno coincide.                   |
| `.max()`     | Busca el valor máximo o `null` si ninguno coincide.                   |
| `.sum()`     | Suma todos los valores.                                               |
| `.average()` | Calcula el promedio de todos los valores o `NaN` si ninguno coincide. |

Usar agregaciones es mucho más rápido que buscar todos los valores y realizar las operaciones de forma manual.

## Consultas dinámicas

:::danger
Esta sección no debería ser relevante. El uso de consultas dinámicas está desaconsejado a menos que sea abosulamente necesario (lo cual es poco probable).
:::

Todos los ejemplos anteriores usan el QueryBuilder y los métodos estáticos generados. Podrías querer crear una consulta dinámica o un lenguaje de consultas personalizado (como el Isar Inspector). En ese caso, puedes usar el método `buildQuery()`:

| Parámetro       | Descripción                                                                                        |
| --------------- | -------------------------------------------------------------------------------------------------- |
| `whereClauses`  | La cláusula `where` de la consulta.                                                                |
| `whereDistinct` | Si las consultas deben retornan sólo valores distintos (solo útil para consultas `where` simples). |
| `whereSort`     | El orden de atravesado de la cláusula `where` (solo útil para consultas `where` simples).          |
| `filter`        | El filtro a aplicar al resultado.                                                                  |
| `sortBy`        | Una lista de propiedades para definir el orden del resultado.                                      |
| `distinctBy`    | Una lista de propiedades para aplicar `distinct`.                                                  |
| `offset`        | El offset de los resultados.                                                                       |
| `limit`         | El número máximo de resultados a retornar.                                                         |
| `property`      | Si no es null, sólo se retornan los valores de ésta propiedad.                                     |

Creemos una consulta dinámica:

```dart
final shoes = await isar.shoes.buildQuery(
  whereClauses: [
    WhereClause(
      indexName: 'size',
      lower: [42],
      includeLower: true,
      upper: [46],
      includeUpper: true,
    )
  ],
  filter: FilterGroup.and([
    FilterCondition(
      type: ConditionType.contains,
      property: 'model',
      value: 'nike',
      caseSensitive: false,
    ),
    FilterGroup.not(
      FilterCondition(
        type: ConditionType.contains,
        property: 'model',
        value: 'adidas',
        caseSensitive: false,
      ),
    ),
  ]),
  sortBy: [
    SortProperty(
      property: 'model',
      sort: Sort.desc,
    )
  ],
  offset: 10,
  limit: 10,
).findAll();
```

La siguiente consulta es equivalente:

```dart
final shoes = await isar.shoes.where()
  .sizeBetween(42, 46)
  .filter()
  .modelContains('nike', caseSensitive: false)
  .not()
  .modelContains('adidas', caseSensitive: false)
  .sortByModelDesc()
  .offset(10).limit(10)
  .findAll();
```
