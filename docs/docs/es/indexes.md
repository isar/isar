---
title: Índices
---

# Índices

Los índices son la característica más poderosa de Isar. Muchas bases de datos embebidas ofrecen índices "normales" (o nada), pero Isar también tiene índices compuestos y multi-entrada. Entender cómo funcionan los índices es esencial para optimizar el rendimiento de las consultas. Isar te permite elegir qué índice quieres usar y cómo quieres usarlo. Comenzaremos con un inicio rápido sobre qué son los índices.

## Qué son los índices?

Cuando una colección no está indexada, el orden de las filas no será identificable por la consulta como optimizada en ninguna forma, y tu consulta tendrá que buscar entonces a través de todos los objectos de forma lineal. En otras palabras, la consulta deberá buscar a través de cada objeto para encontrar los que coincidan con las condiciones. Como puedes imaginarte, eso puede tardar mucho. Buscar a través de cada objeto no es muy eficiente.

Por ejemplo, esta colección `Product` está completamente desordenada.

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

**Datos:**

| id  | name      | price |
| --- | --------- | ----- |
| 1   | Book      | 15    |
| 2   | Table     | 55    |
| 3   | Chair     | 25    |
| 4   | Pencil    | 3     |
| 5   | Lightbulb | 12    |
| 6   | Carpet    | 60    |
| 7   | Pillow    | 30    |
| 8   | Computer  | 650   |
| 9   | Soap      | 2     |

Una consulta que intente buscar todos los productos que cuestan más de $30 tiene que buscar a través de todas las nueve filas. No es un problema para nueve filas, pero podría ser un problema para 100k filas.

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

Para mejorar el rendimiento de esta consulta, indexamos la propiedad `price`. Un índice es como una tabla de búsqueda ordenada:

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

**Índices generados:**

| price                | id                 |
| -------------------- | ------------------ |
| 2                    | 9                  |
| 3                    | 4                  |
| 12                   | 5                  |
| 15                   | 1                  |
| 25                   | 3                  |
| 30                   | 7                  |
| <mark>**55**</mark>  | <mark>**2**</mark> |
| <mark>**60**</mark>  | <mark>**6**</mark> |
| <mark>**650**</mark> | <mark>**8**</mark> |

Ahora, la ejecución de la consulta puede ser considerablemente más rápida. El ejecutor puede saltar directamente a los últimos 3 índices y buscar los objetos correspondientes por su id.

### Ordenando

Otra cosa genial: los índices permiten ordenar súper rápido. Las consultas ordenadas son costosas porque la base de datos tiene que cargar todos los resultados en memoria antes de ordenarlos. Incluso si especificaste un offset y un límite, éstos se aplican después de ordenar.

Imaginemos que queremos encontrar los cuatro productos más baratos. Podríamos usar la siguiente consulta:

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

En este ejemplo, la base de datos tendría que cargar todos los objetos (!), ordenarlos por precio, y retornar los 4 productos con el menor precio.

Como puedes imaginar, ésto puede hacerse mucho más eficiente usando el índice anterior. La base de datos toma las cuatro primeras filas del índice y retorna los objetos correspondientes ya que éstos ya están en el orden correcto.

Para usar el índice para ordenar, escribiríamos la consulta como sigue:

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

La cláusula `where` `.anyX()` le dice a Isar que use un ídice sólo para ordenar. También puedes usar una cláusula `where` como `.priceGreaterThan()` y obtener los resultados ordenados.

## Índices únicos

Un índice único asegura que el índice no contiene valores duplicados. Puede consistir en una o múltiples propiedades. Si un índice único tiene una propiedad, los valores en esta propiedad serán únicos. Si el índice único tiene más de una pro[iedad, la combinación de los valores en estas propiedades es única.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

Cualquier intento de insertar o actualizar datos en un índice único que provoque un duplicado resultará en un error:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> ok

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

// try to insert user with same username
await isar.users.put(user2); // -> error: unique constraint violated
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## Índices con reemplazo

A veces no es deseable arrojar un error si una condición de único es violada. En su lugar, podrías querer reemplazar el objeto existente con el nuevo. Ésto se puede lograr estableciendo la propiedad `replace` del índice a `true`.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

Ahora cuando querramos insertar un usuario con nombre de usuario existente, Isar reemplazará el usuario existente con el nuevo.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1);
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
print(await isar.user.where().findAll());
// > [{id: 2, username: 'user1' age: 30}]
```

Los índices con reemplazo también generan métodos `putBy()` que permiten actualizar los objetos en lugar de reemplazarlos. El id existente es reusado, **_and links are still populated_**.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// user does not exist so this is the same as put()
await isar.users.putByUsername(user1);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

Como puedes ver, el id del primer usuario insertado es reusado.

## Índices mayúsculas-minúsculas

Todos los índices en las propiedades `String` y `List<String>` por defecto distinguen entre mayúsculas y minúsculas. Si quieres que tu índice no haga esta distinción, puedes usar la opción `caseSensitive`:

```dart
@collection
class Person {
  Id? id;

  @Index(caseSensitive: false)
  late String name;

  @Index(caseSensitive: false)
  late List<String> tags;
}
```

## Tipos de índices

Existen diferentes tipos de índices. La mayoría del tiempo, querrás usar un índice tipo `IndexType.value`, pero los índices hash son más eficientes.

### Índice valor

El índice valor es el tipo por defecto y el único posible para todas las propiedades que no sean se tipo String o List. Para construir el índice se utilizan los valores de las propiedades. En el caso de las listas, se utilizan sus elementos. De los tres tipos de índices disponibles, es el más flexible como así también el que más espacio utiliza.

:::tip
Usa `IndexType.value` para primitivas, Strings donde necesites una cláusula `startsWith()`, y listas si quieres buscar por elementos individuales.
:::

### Índice hash

Los strings y las listas pueden reducirse para disminuir significativamente el espacio en disco que requiere el índice. La desventaja es que no puede usarse para búsqueda por prefijo (cláusulas `startsWith`).

:::tip
Usa `IndexType.hash` para strings y listas si no necesitas utilizar cláusulas `startsWith` ni `elementEqualTo`.
:::

### Índice hashElements

Las listas de string pueden reducirse como un todo (usando `IndexType.hash`), o los elementos de la lista pueden reducirse individualmente (usando `IndexType.hashElements`), creando un índice multi-entrada con los elementos reducidos.

:::tip
Usa `IndexType.hashElements` para `List<String>` sin nevesitas aplicar cláusulas `elementEqualTo`.
:::

## Índices compuestos

Un índice compuesto es un índice con múltiples propiedades. Isar te permite crear índices compuestos de hasta tres propiedades.

Los índices compuestos también son conocidos como índices multi-columna.

Probablemente sea mejor comenzar con un ejemplo. Creamos una colleción person y definimos un índice compuesto en las propiedades age y name:

```dart
@collection
class Person {
  Id? id;

  late String name;

  @Index(composite: [CompositeIndex('name')])
  late int age;

  late String hometown;
}
```

**Datos:**

| id  | name   | age | hometown  |
| --- | ------ | --- | --------- |
| 1   | Daniel | 20  | Berlin    |
| 2   | Anne   | 20  | Paris     |
| 3   | Carl   | 24  | San Diego |
| 4   | Simon  | 24  | Munich    |
| 5   | David  | 20  | New York  |
| 6   | Carl   | 24  | London    |
| 7   | Audrey | 30  | Prague    |
| 8   | Anne   | 24  | Paris     |

**Índice generado:**

| age | name   | id  |
| --- | ------ | --- |
| 20  | Anne   | 2   |
| 20  | Daniel | 1   |
| 20  | David  | 5   |
| 24  | Anne   | 8   |
| 24  | Carl   | 3   |
| 24  | Carl   | 6   |
| 24  | Simon  | 4   |
| 30  | Audrey | 7   |

El índice compuesto generado contiene a todas las personas ordenadas por su edad y su nombre.

Los índices compuestos son geniales si necesitas crear consultas eficientes ordenadas por propiedades múltiples. También te pemiten utilizar cláusulas `where` avanzadas:

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

La última propiedad del índice compuesto también soporta condiciones como `startsWith()` o `lessThan()`:

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## Índices multi-entrada

Si indexas una lista usando `IndexType.value`, Isar automáticamente creará un índice multi-entrada, y cada elemento en la lista será indexado hacia el objeto, Funciona para cualquier tipo de lista.

Aplicaciones prácticas del uso de índices multi-entrada incluyen indexar una lista de etiquetas o crear un índice de texto completo.

```dart
@collection
class Product {
  Id? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` divide la cadena en palabras de acuerdo con la especificación [Unicode Annex #29](https://unicode.org/reports/tr29/), por lo tanto funciona correctamente para cualquier idioma.

**Data:**

| id  | description                  | descriptionWords             |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

Entradas con palabras duplicadas paraecen sólo una vez en el índice.

**Índice generado:**

| descriptionWords | id        |
| ---------------- | --------- |
| comfortable      | [1, 2]    |
| blue             | 1         |
| necktie          | 4         |
| plain            | 3         |
| pullover         | 2         |
| red              | [2, 3, 4] |
| super            | 4         |
| t-shirt          | [1, 3]    |

Este índice ahora puede usarse para cláusulas por prefijo (o igualdad) de las palabras individuales de la descripción.

:::tip
En lugar de guardar las palabaras directamente, considera usar los resultados de un [algoritmo de fonética](https://en.wikipedia.org/wiki/Phonetic_algorithm) como [Soundex](https://es.wikipedia.org/wiki/Soundex).
:::
