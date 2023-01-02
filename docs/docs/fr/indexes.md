---
title: Indices
---

# Indices

Les indices (`index`) sont la fonctionnalité la plus puissante d'Isar. De nombreuses bases de données embarquées proposent des index "normaux" (voire aucun), mais Isar dispose également d'index composés et à entrées multiples. Il est essentiel de comprendre le fonctionnement des index pour optimiser les performances des requêtes. Isar vous permet de choisir l'index que vous voulez utiliser et comment vous voulez l'utiliser. Nous allons commencer par une introduction rapide à ce que sont les index.

## Que sont les indices?

Lorsqu'une collection n'est pas indexée, l'ordre des lignes ne pourra probablement pas être discerné par la requête comme étant optimisé de quelconques manières, et votre requête devra donc rechercher les objets de façon linéaire. En d'autres termes, la requête devra parcourir chaque objet pour trouver ceux qui correspondent aux conditions. Comme vous pouvez l'imaginer, cela peut prendre du temps. La recherche dans chaque objet n'est pas très efficace.

Par exemple, cette collection `Product` est entièrement non ordonnée.

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

**Données:**

| id  | name      | price |
|-----|-----------|-------|
| 1   | Book      | 15    |
| 2   | Table     | 55    |
| 3   | Chair     | 25    |
| 4   | Pencil    | 3     |
| 5   | Lightbulb | 12    |
| 6   | Carpet    | 60    |
| 7   | Pillow    | 30    |
| 8   | Computer  | 650   |
| 9   | Soap      | 2     |

Une requête qui tente de trouver tous les produits dont le prix est supérieur à 30 € doit parcourir les neuf rangées. Ce n'est pas un problème pour neuf lignes, mais cela peut le devenir pour 100 000 lignes.

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

Pour améliorer les performances de cette requête, nous indexons la propriété `price`. Un index est comme une table de recherche triée:

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

**Index généré:**

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

Maintenant, la requête peut être exécutée beaucoup plus rapidement. L'exécuteur peut directement sauter aux trois dernières lignes d'index et trouver les objets correspondants par leur id.

### Triage

Autre point intéressant: les index peuvent effectuer des tris très rapides. Les requêtes triées sont coûteuses, car la base de données doit charger tous les résultats en mémoire avant de les trier. Même si vous spécifiez un décalage ou une limite, ils sont appliqués après le tri.

Imaginons que nous voulions trouver les quatre produits les moins chers. Nous pourrions utiliser la requête suivante:

```dart
final cheapest = await isar.products.filter()
  .sortByPrice()
  .limit(4)
  .findAll();
```

Dans cet exemple, la base de données devrait charger tous (!) les objets, les trier par prix et renvoyer les quatre produits dont le prix est le plus bas.

Comme vous pouvez probablement l'imaginer, cette opération peut être réalisée de manière beaucoup plus efficace avec l'index précédent. La base de données prend les quatre premières lignes de l'index et renvoie les objets correspondants puisqu'ils sont déjà dans le bon ordre.

Pour utiliser l'index pour le tri, nous devons écrire la requête comme suit:

```dart
final cheapestFast = await isar.products.where()
  .anyPrice()
  .limit(4)
  .findAll();
```

La clause `where` `.anyX()` indique à Isar d'utiliser un index uniquement pour le tri. Nous pouvons également utiliser une clause `where` comme `.priceGreaterThan()` et obtenir des résultats triés.

## Indices uniques

Un index unique garantit que l'index ne contient pas de valeurs en double. Il peut être composé d'une ou plusieurs propriétés. Si un index unique a une propriété, les valeurs de cette propriété seront uniques. Si l'index unique a plus d'une propriété, la combinaison des valeurs dans ces propriétés est unique.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

Toute tentative d'insertion ou de mise à jour de données dans l'index unique qui provoque un doublon entraînera une erreur:

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

// Essayons d'insérer un utilisateur avec le même nom d'utilisateur
await isar.users.put(user2); // -> error: unique constraint violated
print(await isar.user.where().findAll());
// > [{id: 1, username: 'user1', age: 25}]
```

## Remplacement d'indices

Il n'est parfois pas préférable d'envoyer une erreur si une contrainte unique n'est pas respectée. Au lieu de cela, nous pouvons vouloir remplacer l'objet existant par le nouvel objet. Pour cela, il suffit de mettre la propriété `replace` de l'index à `true`.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true, replace: true)
  late String username;
}
```

Maintenant, lorsque nous essayons d'insérer un utilisateur avec un nom déjà existant, Isar va remplacer l'utilisateur existant par le nouveau.

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

Les indices de remplacement génèrent également des méthodes `putBy()` qui nous permettent de mettre à jour les objets au lieu de les remplacer. L'identifiant existant est réutilisé, et les liens sont toujours présents.

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

// L'utilisateur n'existe pas, donc c'est la même chose que put()
await isar.users.putByUsername(user1); 
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1', age: 25}]

final user2 = User()
  ..id = 2;
  ..username = 'user1'
  ..age = 30;

await isar.users.put(user2);
await isar.user.where().findAll(); // -> [{id: 1, username: 'user1' age: 30}]
```

Comme nous pouvons le constater, l'identifiant du premier utilisateur inséré est réutilisé.

## Index insensibles à la casse

Tous les index sur les propriétés `String` et `List<String>` sont sensibles à la casse par défaut. Si nous voulons créer un index insensible à la casse, nous pouvons utiliser l'option `caseSensitive`:

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

## Type d'indice

Il existe différents types d'index. La plupart du temps, nous voudrons utiliser un index `IndexType.value`, mais les index de hachage sont plus efficaces.

### Index `value`

Les index de valeurs sont le type par défaut et le seul autorisé pour toutes les propriétés qui ne contiennent pas de chaînes de caractères ou de listes. Les valeurs des propriétés sont utilisées pour construire l'index. Dans le cas des listes, ce sont les éléments de la liste qui sont utilisés. Il s'agit du type d'index le plus flexible mais aussi le plus gourmand en espace parmi les trois types d'index.

:::tip
Utilisez `IndexType.value` pour les types primitifs, les chaînes de caractères lorsque vous avez besoin de clauses `startsWith()` et les listes si vous voulez rechercher des éléments individuels.
:::

### Index `hash`

Les chaînes de caractères et les listes peuvent être hachées pour réduire de manière significative le stockage requis par l'index. L'inconvénient des index de hachage est qu'ils ne peuvent pas être utilisés pour les scans de préfixe (clauses `where` `startsWith`).

:::tip
Utilisez `IndexType.hash` pour les chaînes de caractères et les listes si vous n'avez pas besoin des clauses `where` `startsWith` et `elementEqualTo`.
:::

### Index `hashElements`

Les listes de chaînes peuvent être hachées dans leur ensemble (à l'aide de `IndexType.hash`), ou les éléments de la liste peuvent être hachés séparément (à l'aide de `IndexType.hashElements`), créant ainsi un index à entrées multiples avec des éléments hachés.

:::tip
Utilisez `IndexType.hashElements` pour les `List<String>` où vous avez besoin de clauses `where` `elementEqualTo`.
:::

## Indices composés

Un index composite est un index sur plusieurs propriétés. Isar nous permet de créer des index composites sur un maximum de trois propriétés.

Les index composés sont également connus sous le nom d'index à colonnes multiples.

Il est probablement préférable de commencer par un exemple. Nous créons une collection de personnes et définissons un index composé sur les propriétés âge et nom:

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

**Données:**

| id  | name   | age | hometown  |
|-----|--------|-----|-----------|
| 1   | Daniel | 20  | Berlin    |
| 2   | Anne   | 20  | Paris     |
| 3   | Carl   | 24  | San Diego |
| 4   | Simon  | 24  | Munich    |
| 5   | David  | 20  | New York  |
| 6   | Carl   | 24  | London    |
| 7   | Audrey | 30  | Prague    |
| 8   | Anne   | 24  | Paris     |

**Index généré:**

| age | name   | id  |
|-----|--------|-----|
| 20  | Anne   | 2   |
| 20  | Daniel | 1   |
| 20  | David  | 5   |
| 24  | Anne   | 8   |
| 24  | Carl   | 3   |
| 24  | Carl   | 6   |
| 24  | Simon  | 4   |
| 30  | Audrey | 7   |

L'indice composé généré contient toutes les personnes triées par leur âge et leur nom.

Les index composés sont parfaits si nous souhaitons créer des requêtes efficaces triées par plusieurs propriétés. Ils permettent également d'utiliser des clauses `where` avancées avec plusieurs propriétés :

```dart
final result = await isar.where()
  .ageNameEqualTo(24, 'Carl')
  .hometownProperty()
  .findAll() // -> ['San Diego', 'London']
```

La dernière propriété d'un index composé supporte également des conditions telles que `startsWith()` ou `lessThan()` :

```dart
final result = await isar.where()
  .ageEqualToNameStartsWith(20, 'Da')
  .findAll() // -> [Daniel, David]
```

## Indices à entrées multiples

Si nous indexons une liste en utilisant `IndexType.value`, Isar va automatiquement créer un index à entrées multiples, et chaque élément de la liste est indexé vers l'objet. Cela fonctionne pour tous les types de listes.

Les applications pratiques des index à entrées multiples comprennent l'indexation d'une liste de balises ou la création d'un index en texte intégral.

```dart
@collection
class Product {
  Id? id;

  late String description;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get descriptionWords => Isar.splitWords(description);
}
```

`Isar.splitWords()` divise une chaîne de caractères en mots selon la spécification [Unicode Annex #29](https://unicode.org/reports/tr29/), ce qui fait qu'il fonctionne correctement pour presque toutes les langues.

**Data:**

| id  | description                  | descriptionWords             |
| --- | ---------------------------- | ---------------------------- |
| 1   | comfortable blue t-shirt     | [comfortable, blue, t-shirt] |
| 2   | comfortable, red pullover!!! | [comfortable, red, pullover] |
| 3   | plain red t-shirt            | [plain, red, t-shirt]        |
| 4   | red necktie (super red)      | [red, necktie, super, red]   |

Les entrées comportant des mots en double n'apparaissent qu'une seule fois dans l'index.

**Index généré:**

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

Cet index peut maintenant être utilisé pour les clauses de préfixe (ou d'égalité) des mots individuels de la description.

:::tip
Au lieu de stocker les mots directement, vous pouvez également envisager d'utiliser le résultat d'un [algorithme phonétique](https://fr.wikipedia.org/wiki/Algorithme_phon%C3%A9tique) comme [Soundex](https://fr.wikipedia.org/wiki/Soundex).
:::
