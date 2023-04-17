---
title: Uso de múltiples Isolates
---

# Uso de múltiples Isolates

En lugar de tareas, todo el código de Dart corre dentro de isolates. Cada isolate tiene su propia cabecera de memoria, asegurando que ningún estado de un isolate es accesible desde otro isolate.

Isar puede accederse desde múltiples isolates al mismo tiempo, e incluso los observadores funcionan entre isolates. En esta receta, veremos cómo utilizar Isar en un entorno con múltiples isolates.

## Cuándo usar múltiples isolates

Las transacciones Isar se ejecutan en paralelo incluso dentro de un mismo isolate. En algunos casos, es también beneficioso acceder a Isar desde múltiples isolates.

El motivo es que Isar tarda algo de tiempo codificando y decodificando datos desde y hacia objetos Dart. Puedes pensarlo como codificando y decodificando JSON (sólo que más eficiente). Estas operaciones corren dentro del isolate en el cual se acceden los datos y naturalmente bloquean otro código en el isolate. En otras palabras: Isar ejecuta parte del trabajo dentro de tu isolate Dart.

Si sólo necesitas leer y escribir algunos cientos de objetos de una vez, hacerlo dentro del mismo isolate que la UI no es un problema. Pero para transacciones muy grandes o si el isolate de la UI ya está bastante ocupado, deberías considerar usar un isolate separado.

## Ejemplo

Lo primero que debemos hacer es abrir Isar en el nuevo isolate. Dado que la instancia de Isar ya está abierta en el isolate principal, `Isar.open()` retornará la misma instancia.

:::warning
Asegúrate de proveer los mismos esquemas que en el isolate principal. De lo contrario, obtendrás un error.
:::

`compute()` inicia un nuevo isolate en Flutter y ejecuta la función dada en él.

```dart
void main() {
  // Open Isar in the UI isolate
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [MessageSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  // listen to changes in the database
  isar.messages.watchLazy(() {
    print('omg the messages changed!');
  });

  // start a new isolate and create 10000 messages
  compute(createDummyMessages, 10000).then(() {
    print('isolate finished');
  });

  // after some time:
  // > omg the messages changed!
  // > isolate finished
}

// function that will be executed in the new isolate
Future createDummyMessages(int count) async {
  // we don't need the path here because the instance is already open
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [PostSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Message $i');
  // we use a synchronous transactions in isolates
  isar.writeTxnSync(() {
    isar.messages.insertAllSync(messages);
  });
}
```

Existen algunos aspectos interesantes a notar en este ejemplo:

- `isar.messages.watchLazy()` se llama en el isolate de la UI y es notificado de los cambios desde otro isolate.
- Las instancias son referenciadas por nombre. El nombre por defecto es `default`, pero en este ejemplo, utilizamos `myInstance`.
- Utilizamos una transacción síncrona para crear los mensajes. Bloquear el nuevo isolate no es un problema, y las transacciones síncronas son algo más rápidas.
