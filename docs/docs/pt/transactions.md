---
title: Transações
---

# Transações

No Isar, as transações combinam várias operações de banco de dados em uma única unidade de trabalho. A maioria das interações com Isar usa transações implicitamente. O acesso de leitura e gravação no Isar é compatível com [ACID](http://en.wikipedia.org/wiki/ACID). As transações são revertidas automaticamente se ocorrer um erro.

## Transações explicitas

Em uma transação explícita, você obtém um snapShot consistente do banco de dados. Tente minimizar a duração das transações. É proibido fazer chamadas de rede ou outras operações de longa duração em uma transação.

As transações (especialmente transações de gravação) têm um custo e você deve sempre tentar agrupar operações sucessivas em uma única transação.

As transações podem ser síncronas ou assíncronas. Em transações síncronas, você só pode usar operações síncronas. Em transações assíncronas, apenas operações assíncronas.

|              | Read         | Read & Write       |
|--------------|--------------|--------------------|
| Synchronous  | `.txnSync()` | `.writeTxnSync()`  |
| Asynchronous | `.txn()`     | `.writeTxn()`      |


### Transações de leitura

As transações de leitura explícita são opcionais, mas permitem que você faça leituras atômicas e dependa de um estado consistente do banco de dados dentro da transação. Internamente, o Isar sempre usa transações de leitura implícitas para todas as operações de leitura.

:::tip
As transações de leitura assíncrona são executadas em paralelo com outras transações de leitura e gravação. Bem fixe, certo?
:::

### Transações de escrita

Ao contrário das operações de leitura, as operações de gravação em Isar devem ser agrupadas em uma transação explícita.

Quando uma transação de gravação é concluída com êxito, ela é confirmada automaticamente e todas as alterações são gravadas no disco. Se ocorrer um erro, a transação será abortada e todas as alterações serão revertidas. As transações são “tudo ou nada”: ou todas as gravações em uma transação são bem-sucedidas ou nenhuma delas entra em vigor para garantir a consistência dos dados.

:::warning
Quando uma operação de banco de dados falha, a transação é abortada e não deve mais ser usada. Mesmo se você pegar o erro no Dart.
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
