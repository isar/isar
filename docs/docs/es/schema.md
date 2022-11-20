---
title: Esquema
---

# Esquema

Cuando usas Isar para almacenar los datos de tu aplicación, estás tratando con colecciones. Una colección es como una tabla en la base de datos Isar asociada y sólo puede contener un tipo de objeto Dart. Cada objeto de la colección representa una línea de datos en la tabla correspondiente.

La definición de una colección es llamada "esquema" ("schema" en inglés). El generador Isar hará el trabajo pesado por ti y generará la mayoría del código que necesitas para usar tu colección.

## Anatomía de una colección

Cada colección Isar se define anotando una clase con `@collection` o `@Collection()`. Una colección Isar incluye campos para cada columna en la tabla correspondiente en la base de datos, incluyendo uno que corresponde a la clave primaria.

El código siguiente es un ejemplo de una colección simple que define una table `User` con columnas para ID, nombre, y apellido:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
Para almacenar un campo, Isar debe tener acceso al mismo. Puedes asegurarte que Isar tiene acceso a un campo haciéndolo público o proporcionando métodos getter y setter.
:::

Existen algunos parámetros opcionales para personalizar la colección:

| Configuración | Descripción                                                                                                                 |
| ------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Controla si los campos de la clase padre y mixins serán almacenados en Isar. Habilitado por defecto.                        |
| `accessor`    | Permite renombrar el punto de acceso por defecto de la colección (por ejemplo `isar.contacts` para la colección `Contact`). |
| `ignore`      | Permite ignorar ciertas propiedades. Éstas también son respetadas para las super clases.                                    |

### Isar Id

Cada clase que defina una colección Isar, debe definir una propiedad id y debe ser de tipo `Id` identificando inequívocamente un objecto. `Id` es simplemente un alias para `int` que le permite al generador Isar reconocer la propiedad id.

Isar indexa automáticamente los campos id, que permite obtener y modificar objectos de manera eficiente basándose en su id.

Puedes establecer tus propios ids o pedir a Isar que asigne un id auto-incrementable. Si el campo `id` es `null` y no `final`, Isar asignará un id auto-incrementable. Si quieres un id auto-incrementable y no-null, puedes usar `Isar.autoIncrement` en lugar de `null`.

:::tip
Los ids auto incrementables no se reusan cuando un objeto es eliminado. La única manera de reiniciar los ids auto incrementables es borrando la base de datos.
:::

### Renombrando colecciones y campos

Por defecto, Isar usa el nombre de la clase como nombre de la colección. De manera similar, Isar usa los nombres de los campos como nombres de las columnas en la base de datos. Si quieres que una colección o campo tenga un nombre diferente, agrega la anotación `@Name`. El ejemplo siguiente demuestra el uso de nombres personalizados para colecciones y campos:

```dart
@collection
@Name("User")
class MyUserClass1 {

  @Name("id")
  Id myObjectId;

  @Name("firstName")
  String theFirstName;

  @Name("lastName")
  String familyNameOrWhatever;
}
```

Específicamente si quieres renombrar objectos Dart o clases que ya están almacenados en la base de datos, deberías considerar usar la anotación `@Name`. De otra manera, la base de datos eliminiará y creará nuevamente el campo o la colección.

### Ignorando campos

Isar almacena todos los campos públicos de una clase que defina una colección. Anotando una propiedad o getter con `@ignore`, puedes excluir dicha propiedad del almacenamiento, como se muestra en el siguiente extracto de código:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;

  @ignore
  String? password;
}
```

En los casos donde una colección hereda los campos de una colección padre, es generalmente más fácil usar la propiedad `ignore` de la anotación `@Collection`:

```dart
@collection
class User {
  Image? profilePicture;
}

@Collection(ignore: {'profilePicture'})
class Member extends User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

Si una colección contiene un campo con un tipo de dato no soportado por Isar, éste campo debe ser ignorado.

:::warning
Ten en cuenta que no es una buena práctica guardar información en objectos Isar que no serán almacenados.
:::

## Tipos de datos soportados

Isar soporta los siguientes tipos de datos:

- `bool`
- `byte`
- `short`
- `int`
- `float`
- `double`
- `DateTime`
- `String`
- `List<bool>`
- `List<byte>`
- `List<short>`
- `List<int>`
- `List<float>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

Adicionalmente, Isar soporta objetos embebidos y enums. Explicaremos éstos más adelante.

## byte, short, float

Para muchos casos de uso, no es necesario el rango completo de 64-bits de un entero o punto flotante (int o double). Isar contiene soporte para tipos adicionales que te permiten ahorrar espacio y memoria cuando se almacenan número más pequeños.

| Tipo       | Tamaño en bytes | Rango                                                  |
| ---------- | --------------- | ------------------------------------------------------ |
| **byte**   | 1               | 0 a 255                                                |
| **short**  | 4               | -2,147,483,647 a 2,147,483,647                         |
| **int**    | 8               | -9,223,372,036,854,775,807 a 9,223,372,036,854,775,807 |
| **float**  | 4               | -3.4e38 a 3.4e38                                       |
| **double** | 8               | -1.7e308 a 1.7e308                                     |

Los tipos numéricos adicionales con sólo aliases de los tipos de datos nativos de Dart, por lo que usar `short`, por ejemplo, funciona de la misma manera que usando `int`.

El siguiente es un ejemplo de una colección que contiene todos los tipos de datos vistos anteriormente:

```dart
@collection
class TestCollection {
  Id? id;

  late byte byteValue;

  short? shortValue;

  int? intValue;

  float? floatValue;

  double? doubleValue;
}
```

Todos los tipos numéricos también pueden ser usados en listas. Para almacenar bytes, deberías usar `List<byte>`.

## Tipos nulables

Entender cómo funciona la nulabilidad en Isar en esencial: los tipos numéricos **NO** tienen una representación `null` dedicada. Por el contrario, un valor específico es usado:

| Tipo       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN`  |
| **double** |  `double.NaN` |

`bool`, `String`, y `List` tienen una representación `null` por separado.

Este comportamiento habilita mejoras en el rendimiento, y te permite cambiar libremente la nulabilidad de tus campos sin requerir una migración o código especial para lidiar con valores `null`.

:::warning
El tipo `byte` no soporta valores null.
:::

## DateTime

Isar no almacena información de zonas horarias en tus campos DateTime. En su lugar, convierte `DateTime`s a UTC antes de almacenarlos. Isar devuelve todas las fechas en hora local.

Los `DateTime`s se almacenan con presición de microsegundos. En navegadores web, sólo se soporta presición de milisegundos debido a una limitación de Javascript.

## Enum

Isar permite almacenar y usar enums como cualquier otro tipo de dato Isar. Sin embargo, tendrás que decidir cómo Isar debería representar el enum en el disco. Isar soporta cuatro estrategias diferentes:

| EnumType    | Descripción                                                                                      |
| ----------- | ------------------------------------------------------------------------------------------------ |
| `ordinal`   | El índice del emun se almacena como `byte`. Esto es muy eficiente pero no permite enums nulables |
| `ordinal32` | El índice del enum se almacena como `short` (entero de 4 bytes).                                 |
| `name`      | El nombre del enum se almacena como `String`.                                                    |
| `value`     | Para recuperar el valor del enum se utiliza una propiedad personalizada.                         |

:::warning
`ordinal` y `ordinal32` dependen del orden de los valores en el enum. Si cambias el orden, bases de datos existentes retornarán valores incorrectos.
:::

Veamos un ejemplo para cada estrategia.

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // same as EnumType.ordinal
  late TestEnum byteIndex; // cannot be nullable

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // cannot be nullable

  @Enumerated(EnumType.ordinal32)
  TestEnum? shortIndex;

  @Enumerated(EnumType.name)
  TestEnum? name;

  @Enumerated(EnumType.value, 'myValue')
  TestEnum? myValue;
}

enum TestEnum {
  first(10),
  second(100),
  third(1000);

  const TestEnum(this.myValue);

  final short myValue;
}
```

Por supuesto, los Enums pueden usarse también en listas.

## Objetos Embebidos

Con frecuencia es útil tener objetos anidados en tus colecciones. No hay límite en cuanto a la profundidad que un objeto anidado puede tener. Sin embargo, es necesario tener en cuenta que actualizar un objeto anidado requerirá escribir el árbol completo del objeto en la base de datos.

```dart
@collection
class Email {
  Id? id;

  String? title;

  Recepient? recipient;
}

@embedded
class Recepient {
  String? name;

  String? address;
}
```

Los objectos embebidos pueden ser nulables y extender otros objectos. El único requerimiento es que sean anotados con `@embedded` y que tengan un constructor predeterminado sin parámetros requeridos.
