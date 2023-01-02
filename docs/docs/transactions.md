---
title: Transactions
---

# Transactions

In Isar, transactions combine multiple database operations in a single unit of work. Most interactions with Isar implicitly use transactions. Read & write access in Isar is [ACID](http://en.wikipedia.org/wiki/ACID) compliant. Transactions are automatically rolled back if an error occurs.

## Explicit transactions

In an explicit transaction, you get a consistent snapshot of the database. Try to minimize the duration of transactions. It is forbidden to do network calls or other long-running operations in a transaction.

Transactions (especially write transactions) do have a cost, and you should always try to group successive operations into a single transaction.

Transactions can either be synchronous or asynchronous. In synchronous transactions, you may only use synchronous operations. In asynchronous transactions, only async operations.

|              | Read         | Read & Write      |
| ------------ | ------------ | ----------------- |
| Synchronous  | `.txnSync()` | `.writeTxnSync()` |
| Asynchronous | `.txn()`     | `.writeTxn()`     |

### Read transactions

Explicit read transactions are optional, but they allow you to do atomic reads and rely on a consistent state of the database inside the transaction. Internally Isar always uses implicit read transactions for all read operations.

:::tip
Async read transactions run in parallel to other read and write transactions. Pretty cool, right?
:::

### Write transactions

Unlike read operations, write operations in Isar must be wrapped in an explicit transaction.

When a write transaction finishes successfully, it is automatically committed, and all changes are written to disk. If an error occurs, the transaction is aborted, and all the changes are rolled back. Transactions are “all or nothing”: either all the writes within a transaction succeed, or none of them take effect to guarantee data consistency.

:::warning
When a database operation fails, the transaction is aborted and must no longer be used. Even if you catch the error in Dart.
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
