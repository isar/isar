---
title: Enlaces
---

# Enlaces

Los enlaces permiten establecer relaciones entre objetos, como ser el autor de un comentario (User). Con los enlaces de Isar, se pueden modelar relaciones `1:1`, `1:n`, y `n:n`. Usar enlaces es menos ergonómico que usar objetos embebidos y se deberían usar los últimos siempre que sea posible.

Piensa en el enlace como una tabla separada que contiene la relación. Es similar a las relaciones de SQL pero tiene una API y características diferentes.

## IsarLink

`IsarLink<T>` puede contener uno o nigún objeto relacionado, y puede ser usado para expresar una relación a uno. `IsarLink` tiene una sola propiedad llamada `value` que contiene el objeto enlazado.

Los enlaces son perezosos, entonces tienes que decirle explícitamente al `IsarLink` que cargue o guarde el valor `value`. Puedes hacer esto llamando a `linkProperty.load()` y `linkProperty.save()` respectivamente.

:::tip
La propiedad id de las colecciones de origen y destino de un enlace deberían ser no final.
:::

En las plataformas no web, los enlaces se cargan automáticamente cuando los usas por primera vez. Comencemos agregando un IsarLink a la colección:

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

  final teacher = IsarLink<Teacher>();
}
```

Definimos un enlace entre maestros y estudiante. En este ejemplo, cada estudiante puede tener exactamente un maestro.

Primero, creamos el maestro y lo asignamos a un estudiante. Tendremos que insertar el maestro y guardar el enlace manualmente.

```dart
final mathTeacher = Teacher()..subject = 'Math';

final linda = Student()
  ..name = 'Linda'
  ..teacher.value = mathTeacher;

await isar.writeTxn(() async {
  await isar.students.put(linda);
  await isar.teachers.put(mathTeacher);
  await linda.teacher.save();
});
```

Ahora podemos usar el enlace:

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

Probemos hacer los mismo usando código síncrono. No necesitamos guardar el enlace porque `.putSync()` guarda todos los enlaces automáticamente. Incluso crea el maestro por nosotros.

```dart
final englishTeacher = Teacher()..subject = 'English';

final david = Student()
  ..name = 'David'
  ..teacher.value = englishTeacher;

isar.writeTxnSync(() {
  isar.students.putSync(david);
});
```

## IsarLinks

Tendría más sentido si un estudiante del ejemplo anterior pudiera tener más de un maestro. Afortunadamente, Isar tiene `IsarLinks<T>`, que pueden tener múltiples objetos relacionados y expresar relaciones `to-many`.

`IsarLinks<T>` extiende `Set<T>` y expone todos los métodos que están permitidos para los sets.

El comportamiento de `IsarLinks` es similar a `IsarLink` y también es perezoso. Para cargar todos los objetos enlazados se debe llamar a `linkProperty.load()`. Para guardar los cambios, llama a `linkProperty.save()`.

Internamente ambos `IsarLink` y `IsarLinks` se representan de la misma forma. Podemos actualizar el `IsarLink<Teacher>` anterior a un `IsarLinks<Teacher>` para asignar múltiples maestros a un estudiante (sin perder datos).

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

Esto funciona porque no cambiamos el nombre del enlace (`teacher`), entonces Isar lo recuerda de antes.

```dart
final biologyTeacher = Teacher()..subject = 'Biology';

final linda = isar.students.where()
  .filter()
  .nameEqualTo('Linda')
  .findFirst();

print(linda.teachers); // {Teacher('Math')}

linda.teachers.add(biologyTeacher);

await isar.writeTxn(() async {
  await linda.teachers.save();
});

print(linda.teachers); // {Teacher('Math'), Teacher('Biology')}
```

## Backlinks

Te escuché decir, "Y si necesito expresar relaciones a la inversa?". No te precupes! Te presento a los `backlinks`.

Los backlinks son enlaces en la dirección inversa. Cada enlace tiene un backlink implícito. Puedes hacer que esté disponible para tu aplicación anotando un `IsarLink` o `IsarLinks` con `@Backlink()`.

Los backlinks no requieren memoria o recursos adicionales; puedes agregarlos libremente, puedes borrarlos o renombrarlos sin perder datos.

Queremos saber qué estudiantes tiene un maestro, entonces definimos un backlink:

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

Necesitamos especificar el enlace al cual apunta el backlink. Es posible tener múltiples enlaces diferentes entre dos objetos.

## Inicializar enlaces

Los `IsarLink` y `IsarLinks` tienen un constructor de cero argumentos,que debería ser usado para asignar la propiedad enlace que se crea el objeto. Es buena práctica hacer que las propiedades de los enlaces sean `final`.

Cuando insertas (`put()`) tus objectos por primera vez, el enlace se inicializa con las collecciones origen y destino, y puedes llamar métodos como `load()` y `save()`. Un enlace comienza a serguir los cambios inmediatamente después de su creación, entonces puede agregar o quitar relaciones incluso antes que el enlace sea inicializado.

:::danger
Es ilegal mover un enlace a otro objeto.
:::
