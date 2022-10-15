---
title: Transazioni
---

# Transazioni

In Isar, le transazioni combinano più operazioni di database in un'unica unità di lavoro. La maggior parte delle interazioni con Isar utilizza implicitamente le transazioni. L'accesso in lettura e scrittura in Isar è conforme a [ACID](http://en.wikipedia.org/wiki/ACID). Le transazioni vengono automaticamente annullate se si verifica un errore.

## Transazioni esplicite

In una transazione esplicita, ottieni uno snapshot coerente del database. Cerca di ridurre al minimo la durata delle transazioni. È vietato effettuare chiamate di rete o altre operazioni di lunga durata in una transazione.

Le transazioni (in particolare le transazioni di scrittura) hanno un costo e dovresti sempre provare a raggruppare le operazioni successive in un'unica transazione.

Le transazioni possono essere sincrone o asincrone. Nelle transazioni sincrone è possibile utilizzare solo operazioni sincrone. Nelle transazioni asincrone, solo operazioni asincrone.

|              | Read         | Read & Write       |
|--------------|--------------|--------------------|
| Synchronous  | `.txnSync()` | `.writeTxnSync()`  |
| Asynchronous | `.txn()`     | `.writeTxn()`      |


### Transazioni di lettura

Le transazioni di lettura esplicita sono facoltative, ma consentono di eseguire letture atomiche e fare affidamento su uno stato coerente del database all'interno della transazione. Internamente Isar utilizza sempre transazioni di lettura implicita per tutte le operazioni di lettura.

:::tip
Le transazioni di lettura asincrone vengono eseguite in parallelo ad altre transazioni di lettura e scrittura. Abbastanza bello, vero?
:::

### Transazioni di scrittura

A differenza delle operazioni di lettura, le operazioni di scrittura in Isar devono essere racchiuse in una transazione esplicita.

Quando una transazione di scrittura viene completata correttamente, viene automaticamente salvata e tutte le modifiche vengono scritte su disco. Se si verifica un errore, la transazione viene interrotta e tutte le modifiche vengono annullate. Le transazioni sono "tutto o niente": o tutte le scritture all'interno di una transazione hanno esito positivo o nessuna di esse ha effetto per garantire la coerenza dei dati.

:::warning
Quando un'operazione di database ha esito negativo, la transazione viene interrotta e non deve più essere utilizzata. Anche se catturi l'errore in Dart.
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
