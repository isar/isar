---
title: Transactions
---

# Transactions

Dans Isar, les transactions combinent plusieurs opérations de base de données en une seule unité de travail. La plupart des interactions avec Isar utilisent implicitement des transactions. L'accès en lecture et en écriture dans Isar est conforme à la norme [ACID](http://en.wikipedia.org/wiki/ACID). Les transactions sont automatiquement annulées en cas d'erreur.

## Transactions explicites

Dans une transaction explicite, vous obtenez un instantané cohérent de la base de données. Essayez de minimiser la durée des transactions. Il est interdit d'effectuer des appels réseau ou d'autres opérations de longue durée dans une transaction.

Les transactions (en particulier les transactions d'écriture) ont un coût, et nous devrions toujours essayer de regrouper les opérations successives en une seule transaction.

Les transactions peuvent être soit synchrones ou asynchrones. Dans les transactions synchrones, nous ne pouvons utiliser que les opérations synchrones. Dans les transactions asynchrones, uniquement les opérations asynchrones.

|             | Lecture      | Lecture et écriture |
|-------------|--------------|---------------------|
| Synchrones  | `.txnSync()` | `.writeTxnSync()`   |
| Asynchrones | `.txn()`     | `.writeTxn()`       |


### Transactions de lecture

Les transactions de lecture explicites sont facultatives, mais elles nous permettent d'effectuer des lectures atomiques et de compter sur un état cohérent de la base de données à l'intérieur de la transaction. À l'interne, Isar utilise toujours des transactions de lecture implicites pour toutes les opérations de lecture.

:::tip
Les transactions de lecture asynchrones s'exécutent en parallèle avec d'autres transactions de lecture et d'écriture. Plutôt cool, non?
:::

### Transactions d'écriture

Contrairement aux opérations de lecture, les opérations d'écriture dans Isar doivent être enveloppées dans une transaction explicite.

Lorsqu'une transaction d'écriture se termine avec succès, elle est automatiquement validée et toutes les modifications sont écrites sur disque. Si une erreur se produit, la transaction est abandonnée et toutes les modifications sont annulées. Les transactions sont "tout ou rien": soit toutes les écritures d'une transaction réussissent, soit aucune d'entre elles ne prend effet pour garantir la cohérence des données.

:::warning
Lorsqu'une opération de base de données échoue, la transaction est interrompue et ne doit plus être utilisée. Même si vous attrapez l'erreur dans Dart.
:::

```dart
@collection
class Contact {
  Id? id;

  String? name;
}

// BON
await isar.writeTxn(() async {
  for (var contact in getContacts()) {
    await isar.contacts.put(contact);
  }
});

// MAUVAIS : déplacer la boucle à l'intérieur de la transaction
for (var contact in getContacts()) {
  await isar.writeTxn(() async {
    await isar.contacts.put(contact);
  });
}
```
