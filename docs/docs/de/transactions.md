---
title: Transaktionen
---

# Transaktionen

In Isar verbinden Transaktionen mehrere Datenbankoperationen in einen einzigen Arbeitsvorgang. Die meisten Interaktionen mit Isar nutzen implizit Transaktionen. Lese- & Schreibzugriff ist in Isar [ACID](https://de.wikipedia.org/wiki/ACID)-konform. Transaktionen werden automatisch zurückgesetzt, wenn ein Fehler auftritt.

## Explizite Transaktionen

In einer expliziten Transaktion kannst du einen konsistenten Schnappschuss der Datenbank erhalten. Versuche die Dauer einer Transaktion zu minimieren. Es ist verboten Netzwerkabfragen oder andere lang andauernde Operationen in einer Transaktion zu machen.

Transaktionen (besonders Schreib-Transaktionen) sind sehr teuer. Du solltest immer versuchen aufeinander folgende Operationen in eine einzelne Transaktion zu vereinen.

Transaktionen können entweder synchron oder asynchron sein. In synchronen Transaktionen kannst du nur synchrone Operationen verwenden. In asynchronen Transaktionen sind nur asynchrone Operationen möglich.

|           | Lesen        | Lesen & Schreiben |
| --------- | ------------ | ----------------- |
| Synchron  | `.txnSync()` | `.writeTxnSync()` |
| Asynchron | `.txn()`     | `.writeTxn()`     |

### Lese-Transaktionen

Explizite Lese-Transaktionen sind optional, aber sie erlauben es atomare Lesevorgänge durchzuführen und auf einem konsistenten Status der Datenbank innerhalb der Transaktion zu arbeiten. Intern nutzt Isar für alle Lese-Operationen immer Lese-Transaktionen.

:::tip
Asynchrone Lese-Transaktionen laufen parallel zu anderen Lese- und Schreib-Transaktionen. Ziemlich cool, oder?
:::

### Schreib-Transaktionen

Anders als Lese-Operationen müssen Schreib-Operationen in Isar in einer expliziten Transaktion ausgeführt werden.

Wenn eine Schreib-Transaktion erfolgreich beendet wird, wird sie automatisch festgesetzt und alle Änderungen werden auf den Datenträger geschrieben. Wenn ein Fehler auftritt, wird die Transaktion abgebrochen und alle Änderungen werden zurückgesetzt. Transaktionen sind „Alles oder Nichts”: Entweder sind alle Schreibvorgänge in der Transaktion erfolgreich oder keine von ihnen findet statt. Somit ist sichergestellt, dass die Daten konsistent sind.

:::warning
Wenn eine Datenbankoperation fehlschlägt, wird die Transaktion abgeborchen und darf nicht mehr verwendet werden, auch wenn der Fehler in Dart aufgefangen wird.
:::

```dart
@collection
class Contact {
  Id? id;

  String? name;
}

// GUT
await isar.writeTxn(() async {
  for (var contact in getContacts()) {
    await isar.contacts.put(contact);
  }
});

// SCHLECHT: Bewege die Schleife in die Transaktion
for (var contact in getContacts()) {
  await isar.writeTxn(() async {
    await isar.contacts.put(contact);
  });
}
```
