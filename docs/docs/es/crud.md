---
title: Crear, Leer, Actualizar, Eliminar
---

# Crear, Leer, Actualizar, Eliminar (CRUD)

Cuando ya has definido tus colecciones, aprende cómo manipularlas!

## Abriendo Isar

Antes de hacer nada, necesitamos una instancia Isar. Cada instancia requiere un directorio con permisos de escritura donde el archivo de la base de datos pueda ser almacenado. Si no defines un directorio, Isar encontrará un directorio por defecto apropiado para la plataforma en uso.

Provee todos los esquemas que quieras usar con la instancia Isar. Si abres múltiples instancias, aún tienes que proveer todos los esquemas a cada instancia.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [ContactSchema],
  directory: dir.path,
);
```

Puedes usar la configuración por defecto o proveer algunos de los siguientes parámetros:

| Configuración       | Descripción                                                                                                                                                                                                                     |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`              | Abre múltiples instancias con distinto nombre. `"default"` es el nomre usado por defecto.                                                                                                                                       |
| `directory`         | La ubicación de almacenamiento para esta instancia. Puedes usar una ruta relativa o absoluta. `NSDocumentDirectory` para iOS y `getDataDirectory` para Android son los usados por defecto. No se requiere para web.             |
| `relaxedDurability` | Relaja la garantía de durabilidad para incrementar el rendimiento de escritura. En caso de falla del sistema (no de la aplicación), es posible perder la última transacción ejecutada. La corrupción de los datos no es posible |
| `compactOnLaunch`   | Condiciones a verificar cuando la base de datos deba ser compactada cuando se abra la instancia.                                                                                                                                |
| `inspector`         | Habilita el inspector para las compilaciones de depuración. Esta opción se ignora para las compilaciones de perfil y entrega.                                                                                                   |

Si existiera una instancia ya abierta al momento de llamar a `Isar.open()`, ésta retornará la instancia existente independientemente de los parámetros especificados. Ésto es útil para usar Isar en un isolate.

:::tip
Considera usar el paquete [path_provider](https://pub.dev/packages/path_provider) para obtener una ruta válida en todas las plataformas.
:::

La ubicación de almacenamiento del archivo de la base de datos Isar es `directory/name.isar`

## Leyendo la base de datos

Usa instancias `IsarCollection` para buscar, consultar y crear nuevos objetos de un tipo dado en Isar.

Para los ejemplos siguientes, asumimos que tenemos una colección `Recipe` definida como sigue:

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### Obtener una colección

Todas tus colecciones viven en la instancia Isar. Puedes obtener tu colección Recipes con:

```dart
final recipes = isar.recipes;
```

Eso fue fácil! Si no quieres usar los accesores de la colección, puedes usar el método `collection()`:

```dart
final recipes = isar.collection<Recipe>();
```

### Obtener un objeto (por su id)

Todavía no tenemos datos en la colección, pero pretendamos que tenemos así podemos obtener un objeto imaginario dado su id `123`

```dart
final recipe = await recipes.get(123);
```

`get()` retorna un `Future` con el objeto o `null` si éste no existe. Por defecto todas las operaciones Isar son asíncronas, y la mayoría de ellas tienen su versión síncrona:

```dart
final recipe = recipes.getSync(123);
```

:::warning
En tus isolate de UI, por defecto deberías usar los métodos en su versión asíncrona. Debido a que Isar es súper rápido, a menudo es aceptable usar la versión síncrona.
:::

Si quieres obtener múltiples objetos de una vez, utiliza `getAll()` o `getAllSync()`:

```dart
final recipe = await recipes.getAll([1, 2]);
```

### Consulta de objectos

En lugar de obtener objetos por su id, puedes también consultar una lista objetos que coincidan con ciertas condiciones usando `.where()` y `.filter()`:

```dart
final allRecipes = await recipes.where().findAll();

final favouires = await recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ Ver más en: [Consultas](queries)

## Modificando los datos

Finalmente es momento de modificar los datos en nuestra colección! Para crear, actualizar o eliminar objectos, usa las respectivas operaciones juntas en una transacción de escritura:

```dart
await isar.writeTxn(() async {
  final recipe = await recipes.get(123)

  recipe.isFavorite = false;
  await recipes.put(recipe); // perform update operations

  await recipes.delete(123); // or delete operations
});
```

➡️ Ver más en: [Transacciones](transactions)

### Insertar objectos

Para almacenar un objeto en Isar, insértalo en una colección. El método `put()` de Isar insertará o actualizará el objecto dependiendo si el mismo ya existe o no en la colección.

Si el campo id es `null` o `Isar.autoIncrement`, Isar usará un id auto incrementable.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await recipes.put(pancakes);
})
```

Isar asignará automáticamente el id al objeto si el campo id es no-final.

Insertar múltiples objetos de una sola vez es muy fácil:

```dart
await isar.writeTxn(() async {
  await recipes.putAll([pancakes, pizza]);
})
```

### Actualizar objectos

Crear y actualizar objetos funcionan ambos con `collection.put(object)`. Si el id es `null` (o no existe), el object se crea; de otra manera será actualizado.

Entonces si queremos quitar los pancakes de los favoritos, podemos hacer los siguiente:

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await recipes.put(recipe);
});
```

### Eliminar objetos

Quieres eliminar un objeto en Isar? Usa `collection.delete(id)`. El método delete retorna verdadero si el objeto con el id especificado fue encontrado y eliminado. Por ejemplo, si quieres eliminar el objeto con el id `123`, puedes hacer:

```dart
await isar.writeTxn(() async {
  final success = await recipes.delete(123);
  print('Recipe deleted: $success');
});
```

De manera similar a get y put, también existe una operación para eliminar múltiples objetos de una vez que retorna la cantidad de objetos eliminados:

```dart
await isar.writeTxn(() async {
  final count = await recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

Si no conoces los ids de los objetos que quieres eliminar, puedes utilizar una consulta:

```dart
await isar.writeTxn(() async {
  final count = await recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
