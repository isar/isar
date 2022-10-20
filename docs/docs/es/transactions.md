---
title: Transacciones
---

# Transacciones

En Isar, las transacciones combinan múltiples operaciones en una sola unidad de trabajo. La mayoría de las interacciones con Isar utilizan transacciones de forma implícita. El acceso de lectura y escritura en Isar cumple está conforme con [ACID](https://es.wikipedia.org/wiki/ACID). Las transacciones se retroceden automáticamente en caso de error.

## Transacciones explícitas

En una transacción explícita, obtienes una instantánea consistente de la base de datos. Intenta minimizar la duración de las transacciones. En una transacción stá prohibido hacer llamadas de red u otras operaciones de largo procesamiento.

Las transacciones (especialmente las de escritura) tienen un costo, y siempre deberías agrupar operaciones sucesivas en una sola transacción.

Las transacciones puede ser tanto síncronas como asíncronas. En las transacciones síncronas, sólo puedes utilizar operaciones síncronas. En las transacciones asíncronas, sólo operaciones asíncronas.

|            | Lectura      | Lectura y Escritura |
| ---------- | ------------ | ------------------- |
| Síncronas  | `.txnSync()` | `.writeTxnSync()`   |
| Asíncronas | `.txn()`     | `.writeTxn()`       |

### Transacciones de lectura

Las transacciones explícitas de lectura son opcionales, pero te permiten hacer lecturas atómicas y confiar en que el estado de la base de datos dentro de la transacción será consistente. Internamente Isar utiliza transacciones de lectura implícitas para todas las operaciones de lectura.

:::tip
Las transacciones de lectura asíncronas se ejecutan en paralelo con otras transacciones de lectura y escritura. Genial verdad?
:::

### Transacciones de escritura

A diferencia de las operaciones de lectura, las operaciones de escritura en Isar deben ser agrupadas en una transacción explícita.

Cuando una transacción de escritura finaliza exitosamente, automáticamente es aplicada, y todos los cambios se escriben al disco. En case de error, se aborta y los cambios retroceden. Las transacciones son "todo o nada": o todas las escrituras de la transacción suceden, o ninguna de ellas tiene efecto, para garantizar la consitencia de los datos.

:::warning
Cuando una operación de la base de datos falla, la transacción se aborta y ya no debe ser utilizada. Incluso si capturaste el error en Dart.
:::

```dart
@collection
class Contact {
  Id? id;

  String? name;
}

// GOOD
await isar.writeTxn(() async {
  for (var contact in getContacts()) {
    await isar.contacts.put(contact);
  }
});

// BAD: move loop inside transaction
for (var contact in getContacts()) {
  await isar.writeTxn(() async {
    await isar.contacts.put(contact);
  });
}
```
