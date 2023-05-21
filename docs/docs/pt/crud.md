---
title: Criar, Ler, Atualizar, Apagar
---

# Criar, Ler, Atualizar, Apagar

Quando você tiver suas coleções definidas, aprenda a manipulá-las!

## Abrindo Isar

Antes que você possa fazer qualquer coisa, precisamos de uma instância Isar. Cada instância requer um diretório com permissão de gravação onde o arquivo de banco de dados pode ser armazenado. Se você não especificar um diretório, o Isar encontrará um diretório padrão adequado para a plataforma atual.

Forneça todos os esquemas que deseja usar com a instância Isar. Se você abrir várias instâncias, ainda precisará fornecer os mesmos esquemas para cada instância.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [RecipeSchema],
  directory: dir.path,
);
```

Você pode usar a configuração padrão ou fornecer alguns dos seguintes parâmetros:

| Config |  Description |
| -------| -------------|
| `name` | Abra várias instâncias com nomes distintos. Por padrão, `"default"` em uso. |
| `directory` | O local de armazenamento para esta instância. Por padrão, `NSDocumentDirectory` é usado para iOS e `getDataDirectory` para Android. Para web não é necessário. |
| `relaxedDurability` | Diminua a garantia de durabilidade para aumentar o desempenho de gravação. Em caso de falha do sistema (não falha do aplicativo), é possível perder a última transação confirmada. A corrupção não é possível|
| `compactOnLaunch` | Condições para verificar se o banco de dados deve ser compactado quando a instância for aberta. |
| `inspector` |Inspetor habilitado para compilações de depuração. Para builds de perfil e versão, esta opção é ignorada. |

Se uma instância já estiver aberta, chamar `Isar.open()` produzirá a instância existente independentemente dos parâmetros especificados. Isso é útil para usar Isar em um isolado.

:::tip
Considere usar o pacote [path_provider](https://pub.dev/packages/path_provider) para obter um caminho válido em todas as plataformas.
:::

O local de armazenamento do arquivo de banco de dados é `directory/name.isar`

## Leitura do banco de dados

Use instâncias `IsarCollection` para localizar, consultar e criar novos objetos de um determinado tipo em Isar.

Para os exemplos abaixo, assumimos que temos uma coleção `Recipe` definida da seguinte forma:

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### Obter coleção

Todas as suas coleções residem na instância Isar. Você pode obter a coleção de receitas com:

```dart
final recipes = isar.recipes;
```

Essa foi fácil! Se você não quiser usar acessadores de coleção, você também pode usar o método `collection()`:

```dart
final recipes = isar.collection<Recipe>();
```

### Obter um objeto (por id)

Ainda não temos dados na coleção, mas vamos fingir que temos para que possamos obter um objeto imaginário pelo id `123`

```dart
final recipe = await isar.recipes.get(123);
```

`get()` retorna um `Future` com o objeto ou `null` se não existir. Todas as operações Isar são assíncronas por padrão e a maioria delas tem uma contrapartida síncrona:

```dart
final recipe = isar.recipes.getSync(123);
```

:::warning
Você deve usar como padrão a versão assíncrona dos métodos em seu isolamento de interface do usuário. Como o Isar é muito rápido, geralmente é aceitável usar a versão síncrona.
:::

Se você quiser obter vários objetos de uma vez, use `getAll()` ou `getAllSync()`:

```dart
final recipe = await isar.recipes.getAll([1, 2]);
```

### Objetos de consulta

Em vez de obter objetos por id, você também pode consultar uma lista de objetos que correspondem a certas condições usando `.where()` e `.filter()`:

```dart
final allRecipes = await isar.recipes.where().findAll();

final favouires = await isar.recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ Saber mais: [Consultas](queries)

## Modificando o banco de dados

Finalmente chegou a hora de modificar nossa coleção! Para criar, atualizar ou excluir objetos, use as respectivas operações envolvidas em uma transação de gravação:

```dart
await isar.writeTxn(() async {
  final recipe = await isar.recipes.get(123)

  recipe.isFavorite = false;
  await isar.recipes.put(recipe); // realizar operações de atualização

  await isar.recipes.delete(123); // ou operações de apagar
});
```

➡️ Saber mais: [Transações](transactions)

### Inserir objeto

Para persistir um objeto em Isar, insira-o em uma coleção. O método `put()` de Isar irá inserir ou atualizar o objeto dependendo da sua existência na coleção.

Se o campo id for `null` ou `Isar.autoIncrement`, Isar usará um id de incremento automático.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await isar.recipes.put(pancakes);
})
```

Isar atribuirá automaticamente o id ao objeto se o campo `id` não for final.

Inserir vários objetos de uma só vez é extremamente fácil:

```dart
await isar.writeTxn(() async {
  await isar.recipes.putAll([pancakes, pizza]);
})
```

### Atualizar objeto

Tanto a criação quanto a atualização funcionam com `collection.put(object)`. Se o id for `null` (ou não existir), o objeto será inserido; caso contrário, ele é atualizado.

Então, se quisermos desfavoritar nossas panquecas, podemos fazer o seguinte:

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await isar.recipes.put(recipe);
});
```

### Apagar objeto

Quer se livrar de um objeto em Isar? Use `collection.delete(id)`. O método delete retorna se um objeto com o id especificado foi encontrado e excluído. Se você quiser excluir o objeto com id `123`, por exemplo, você pode fazer:

```dart
await isar.writeTxn(() async {
  final success = await isar.recipes.delete(123);
  print('Receita apagada: $success');
});
```

Da mesma forma para obter e colocar, também há uma operação de exclusão em massa que retorna o número de objetos excluídos:

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.deleteAll([1, 2, 3]);
  print('Apagamos $count receitas');
});
```

Se você não souber os ids dos objetos que deseja excluir, poderá usar uma consulta:

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('Apagamos $count receitas');
});
```
