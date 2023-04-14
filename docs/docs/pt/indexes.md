---
title: Índices
---

# Índices

Os índices são o recurso mais poderoso do Isar. Muitos bancos de dados incorporados oferecem índices "normais" (se houver), mas o Isar também possui índices compostos e de várias entradas. Compreender como os índices funcionam é essencial para otimizar o desempenho da consulta. Isar permite que você escolha qual índice você deseja usar e como deseja usá-lo. Começaremos com uma rápida introdução sobre o que são índices.

## O que são índices?

Quando uma coleção não é indexada, a ordem das linhas provavelmente não será discernível pela consulta como otimizada de forma alguma e, portanto, sua consulta terá que pesquisar os objetos linearmente. Em outras palavras, a consulta terá que pesquisar em todos os objetos para encontrar aqueles que correspondam às condições. Como você pode imaginar, isso pode levar algum tempo. Olhar através de cada objeto não é muito eficiente.

Por exemplo, esta coleção `Product` é totalmente desordenada.

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

**Dados:**

| id  | name      | price |
| --- | --------- | ----- |
| 1   | Book      | 15    |
| 2   | Table     | 55    |
| 3   | Chair     | 25    |
| 4   | Pencil    | 3     |
| 5   | Lightbulb | 12    |
| 6   | Carpet    | 60    |
| 7   | Pillow    | 30    |
| 8   | Computer  | 650   |
| 9   | Soap      | 2     |

Uma consulta que tenta encontrar todos os produtos que custam mais de € 30 deve pesquisar todas as nove linhas. Isso não é um problema para nove linhas, mas pode se tornar um problema para 100 mil linhas.

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

Para melhorar o desempenho desta consulta, indexamos a propriedade `price`. Um índice é como uma tabela de pesquisa classificada:

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

**Índice gerado:**

| price                | id                 |
| -------------------- | ------------------ |
| 2                    | 9                  |
| 3                    | 4                  |
| 12                   | 5                  |
| 15                   | 1                  |
| 25                   | 3                  |
| 30                   | 7                  |
| <mark>**55**</mark>  | <mark>**2**</mark> |
| <mark>**60**</mark>  | <mark>**6**</mark> |
| <mark>**650**</mark> | <mark>**8**</mark> |

Agora, a consulta pode ser executada muito mais rápido. O executor pode pular diretamente para as últimas três linhas do índice e encontrar os objetos correspondentes por seu id.

### Ordenação

Outra coisa legal: os índices podem fazer uma classificação super rápida. As consultas classificadas são caras porque o banco de dados precisa carregar todos os resultados na memória antes de classificá-los. Mesmo se você especificar um deslocamento ou limite, eles serão aplicados após a classificação.

Vamos imaginar que queremos encontrar os quatro produtos mais baratos. Poderíamos usar a seguinte consulta:

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

Neste exemplo, o banco de dados teria que carregar todos os objetos (!), classificá-los por preço e retornar os quatro produtos com o menor preço.

Como você provavelmente pode imaginar, isso pode ser feito de forma muito mais eficiente com o índice anterior. O banco de dados pega as primeiras quatro linhas do índice e retorna os objetos correspondentes, pois eles já estão na ordem correta.

Para usar o índice para classificação, escreveríamos a consulta assim:

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

A cláusula where `.anyX()` diz ao Isar para usar um índice apenas para ordenar. Você também pode usar uma cláusula where como `.priceGreaterThan()` e obter resultados ordenados.

## Índices únicos

Um índice único garante que o índice não contenha valores duplicados. Pode consistir em uma ou várias propriedades. Se um índice único tiver uma propriedade, os valores dessa propriedade serão exclusivos. Se o índice exclusivo tiver mais de uma propriedade, a combinação de valores nessas propriedades será única.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

Qualquer tentativa de inserir ou atualizar dados no índice exclusivo que cause uma duplicata resultará em um erro:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> ok

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

// tente inserir usuário com o mesmo username
await isar.users.put(user2); // -> error: unique constraint violated
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## Substituir índices

Às vezes, não é preferível lançar um erro se uma restrição exclusiva for violada. Em vez disso, você pode substituir o objeto existente pelo novo. Isso pode ser feito definindo a propriedade `replace` do índice como `true`.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

Agora, quando tentamos inserir um usuário com um nome de usuário existente, Isar substituirá o usuário existente pelo novo.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1);
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
print(await isar.user.where().findAll());
// > [{id: 2, username: 'user1' age: 30}]
```

Os índices de substituição também geram métodos `putBy()` que permitem atualizar objetos em vez de substituí-los. O id existente é reutilizado e os links ainda são preenchidos.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

//usuário não existe, então é o mesmo que o put()
await isar.users.putByUsername(user1); 
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

Como você pode ver, o id do primeiro usuário inserido é reutilizado.

## Índices Case-insensitive

Todos os índices nas propriedades `String` e `List<String>` diferenciam maiúsculas de minúsculas por padrão. Se você deseja criar um índice que não diferencia maiúsculas de minúsculas, pode usar a opção `caseSensitive`:

```dart
@collection
class Person {
  Id? id;

  @Index(caseSensitive: false)
  late String name;

  @Index(caseSensitive: false)
  late List<String> tags;
}
```

## Tipo de índice

Existem diferentes tipos de índices. Na maioria das vezes, você desejará usar um índice `IndexType.value`, mas os índices de hash são mais eficientes.

### Índice de valor

Índices de valor são o tipo padrão e o único permitido para todas as propriedades que não contêm Strings ou Lists. Os valores de propriedade são usados para construir o índice. No caso de listas, os elementos da lista são usados. É o mais flexível, mas também consome espaço dos três tipos de índice.

:::tip
Use `IndexType.value` para primitivos, Strings onde você precisa de cláusulas `startsWith()` where e Lists se você quiser procurar por elementos individuais.
:::

### Índice Hash

Strings e Lists podem ser hash para reduzir significativamente o armazenamento exigido pelo índice. A desvantagem dos índices de hash é que eles não podem ser usados para varreduras de prefixo (cláusulas `startsWith` where).

:::tip
Use `IndexType.hash` para Strings e Lists se você não precisar das cláusulas `startsWith` e `elementEqualTo` where.
:::

### Índice HashElements

Lists de strings podem ser hash como um todo (usando `IndexType.hash`), ou os elementos da list podem ser hash separadamente (usando `IndexType.hashElements`), criando efetivamente um índice de várias entradas com elementos hash.

:::tip
Use `IndexType.hashElements` para `List<String>` onde você precisa das cláusulas where `elementEqualTo`.
:::

## Índices compostos

Um índice composto é um índice em várias propriedades. Isar permite criar índices compostos de até três propriedades.

Índices compostos também são conhecidos como índices de várias colunas.

Provavelmente é melhor começar com um exemplo. Criamos uma coleção de pessoas e definimos um índice composto nas propriedades age e name:

```dart
@collection
class Person {
  Id? id;

  late String name;

  @Index(composite: [CompositeIndex('name')])
  late int age;

  late String hometown;
}
```

**Dados:**

| id  | name   | age | hometown  |
| --- | ------ | --- | --------- |
| 1   | Daniel | 20  | Berlin    |
| 2   | Anne   | 20  | Paris     |
| 3   | Carl   | 24  | San Diego |
| 4   | Simon  | 24  | Munich    |
| 5   | David  | 20  | New York  |
| 6   | Carl   | 24  | London    |
| 7   | Audrey | 30  | Prague    |
| 8   | Anne   | 24  | Paris     |

**Índice gerado:**

| age | name   | id  |
| --- | ------ | --- |
| 20  | Anne   | 2   |
| 20  | Daniel | 1   |
| 20  | David  | 5   |
| 24  | Anne   | 8   |
| 24  | Carl   | 3   |
| 24  | Carl   | 6   |
| 24  | Simon  | 4   |
| 30  | Audrey | 7   |

O índice composto gerado contém todas as pessoas classificadas por idade e nome.

Índices compostos são ótimos se você deseja criar consultas eficientes classificadas por várias propriedades. Eles também permitem cláusulas where avançadas com várias propriedades:

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

A última propriedade de um índice composto também suporta condições como `startsWith()` ou `lessThan()`:

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## Índices de várias entradas

Se você indexar uma lista usando `IndexType.value`, o Isar criará automaticamente um índice de várias entradas e cada item da lista será indexado em relação ao objeto. Funciona para todos os tipos de listas.

As aplicações práticas para índices de várias entradas incluem a indexação de uma lista de tags ou a criação de um índice de texto completo.

```dart
@collection
class Product {
  Id? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` divide uma string em palavras de acordo com a especificação do [Unicode Annex #29](https://unicode.org/reports/tr29/), então funciona para quase todos os idiomas corretamente.

**Dados:**

| id  | description                  | descriptionWords             |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

As entradas com palavras duplicadas aparecem apenas uma vez no índice.

**Índice gerado:**

| descriptionWords | id        |
| ---------------- | --------- |
| comfortable      | [1, 2]    |
| blue             | 1         |
| necktie          | 4         |
| plain            | 3         |
| pullover         | 2         |
| red              | [2, 3, 4] |
| super            | 4         |
| t-shirt          | [1, 3]    |

Este índice agora pode ser usado para prefixo (ou igualdade) onde cláusulas das palavras individuais da descrição.

:::tip
Em vez de armazenar as palavras diretamente, considere também usar o resultado de um [algoritmo fonético](https://en.wikipedia.org/wiki/Phonetic_algorithm) como [Soundex](https://en.wikipedia.org/wiki/ Soundex).
:::
