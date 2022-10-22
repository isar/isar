---
title: Requêtes
---

# Requêtes

Les requêtes permettent de trouver des enregistrements qui correspondent à certaines conditions, par exemple:

- Trouver tous les contacts favoris.
- Trouver des prénoms distincts dans les contacts.
- Supprimez tous les contacts dont le nom de famille n'est pas défini.

Comme les requêtes sont exécutées sur la base de données et non dans Dart, elles sont très rapides. Si vous utilisez intelligemment les index, vous pouvez encore améliorer les performances des requêtes. Dans ce qui suit, vous apprendrez comment écrire des requêtes et comment les rendre le plus rapides possible.

Il existe deux méthodes différentes pour filtrer vos enregistrements: Les filtres et les indexes. Nous allons commencer par examiner le fonctionnement des filtres.

## Filtres

Les filtres sont faciles à utiliser et à comprendre. Selon le type de vos champs, il existe différentes opérations de filtrage disponibles, dont la plupart ont des noms explicites.

Les filtres fonctionnent en évaluant une expression pour chaque objet de la collection à filtrer. Si l'expression donne un résultat "vrai", Isar inclura l'objet dans les résultats. Les filtres n'affectent pas l'ordre des résultats.

Nous utiliserons le modèle suivant pour les exemples ci-dessous:

```dart
@collection
class Shoe {
  Id? id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### Conditions de requête

Selon le type de champ, il existe différentes conditions.

| Condition                | Description                                                                                                                                                           |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `.equalTo(value)`        | Recherche les valeurs qui sont égales à `value`.                                                                                                                      |
| `.between(lower, upper)` | Recherche les valeurs qui se situent entre `lower` et `upper`.                                                                                                        |
| `.greaterThan(bound)`    | Recherche les valeurs qui sont supérieures à `bound`.                                                                                                                 |
| `.lessThan(bound)`       | Recherche les valeurs qui sont inférieures à `bound`. Les valeurs `null` seront incluses par défaut car `null` est considéré comme plus petit que toute autre valeur. |
| `.isNull()`              | Recherche les valeurs qui sont `null`.                                                                                                                                |
| `.isNotNull()`           | Recherche les valeurs qui ne sont pas `null`.                                                                                                                         |
| `.length()`              | Les requêtes sur la longueur des listes, Strings et liens filtrent les objets en fonction du nombre d'éléments dans une liste ou un lien.                             |

Supposons que la base de données contienne quatre chaussures de tailles 39, 40, 46 et une de taille non définie (`null`). Si vous n'effectuez pas de tri, les valeurs seront retournées triées par id.

```dart

isar.shoes.filter()
  .sizeLessThan(40)
  .findAll() // -> [39, null]

isar.shoes.filter()
  .sizeLessThan(40, include: true)
  .findAll() // -> [39, null, 40]

isar.shoes.filter()
  .sizeBetween(39, 46, includeLower: false)
  .findAll() // -> [40, 46]

```

### Opérateurs logiques

Vous pouvez composer des prédicats à l'aide des opérateurs logiques suivants :

| Opérateur  | Description                                                                  |
|------------|------------------------------------------------------------------------------|
| `.and()`   | Évalue à `true` si les expressions de gauche et de droite évaluent à `true`. |
| `.or()`    | Évalue à `true` si l'une des deux expressions évalue à `true`.               |
| `.xor()`   | Évalue à `true` si exactement une expression évalue à `true`.                |
| `.not()`   | Négativise le résultat de l'expression suivante.                             |
| `.group()` | Regroupe les conditions et permet de spécifier l'ordre d'évaluation.         |

Si vous voulez trouver toutes les chaussures de taille 46, vous pouvez utiliser la requête suivante:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

Si vous voulez utiliser plus d'une condition, vous pouvez combiner plusieurs filtres à l'aide du **et**`.and()` logique, **ou**`.or()` logique et **xor**`.xor()` logique.

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // Facultatif. Les filtres sont implicitement combinés avec des et logiques.
  .isUnisexEqualTo(true)
  .findAll();
```

Cette requête est équivalente à: `size == 46 && isUnisex == true`.

Vous pouvez également regrouper des conditions en utilisant `.group()`:

```dart
final result = await isar.shoes.filter()
  .sizeBetween(43, 46)
  .and()
  .group((q) => q
    .modelNameContains('Nike')
    .or()
    .isUnisexEqualTo(false)
  )
  .findAll()
```

Cette requête est équivalente à: `size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)`.

Pour nier une condition ou un groupe, utilisez l’opérateur logique **not**`.not()`:

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

Cette requête est équivalente à: `size != 46 && isUnisex != true`.

### Conditions de String

En plus des conditions de recherche ci-dessus, les valeurs de type String offrent quelques conditions supplémentaires que vous pouvez utiliser. Les caractères génériques de type Regex, par exemple, permettent une plus grande flexibilité dans la recherche.

| Condition            | Description                                                           |
|----------------------|-----------------------------------------------------------------------|
| `.startsWith(value)` | Recherche les valeurs qui commencent par la valeur `value` fournie.   |
| `.contains(value)`   | Recherche les valeurs qui contiennent la valeur `value` fournie.      |
| `.endsWith(value)`   | Recherche les valeurs qui se terminent par la valeur `value` fournie. |
| `.matches(wildcard)` | Recherche les valeurs qui correspondent au motif `wildcard` fourni.   |

**Sensibilité à la casse**  
Toutes les opérations sur les Strings ont un paramètre optionnel `caseSensitive` dont la valeur par défaut est `true`.

**Motifs:**  
Une [expression de String génériques] (https://fr.wikipedia.org/wiki/Wildcard_character) est un String qui utilise des caractères normaux avec deux caractères génériques spéciaux:

- Le caractère générique `*` correspond à zéro ou plus de n'importe quel caractère.
- Le caractère générique `?` correspond à n'importe quel caractère.
  Par exemple, la chaîne générique `"d?g"` correspond à `"dog"`, `"dig"` et `"dug"`, mais pas à `"ding"`, `"dg"` ou `"a dog"`.

### Modificateurs de requête

Il est parfois nécessaire de construire une requête basée sur certaines conditions ou pour différentes valeurs. Isar dispose d'un outil très puissant pour construire des requêtes conditionnelles :

| Modificateur          | Description                                                                                                                                                                           |
|-----------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `.optional(cond, qb)` | Étend la requête uniquement si la `condition` est `true`. Cela peut être utilisé presque partout dans une requête, par exemple pour la trier ou la limiter de manière conditionnelle. |
| `.anyOf(list, qb)`    | Étend la requête pour chaque valeur de `values` et combine les conditions en utilisant l’opérateur **ou**.                                                                            |
| `.allOf(list, qb)`    | Étend la requête pour chaque valeur de `values` et combine les conditions en utilisant les **et** logiques.                                                                           |

Dans cet exemple, nous construisons une méthode qui trouve des chaussures avec un filtre optionnel:

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // Seulement appliquer le filtre si sizeFilter != null
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

Si vous voulez trouver toutes les chaussures qui ont une ou plusieurs tailles, vous pouvez soit écrire une requête classique, soit utiliser le modificateur `anyOf()`:

```dart
final shoes1 = await isar.shoes.filter()
  .sizeEqualTo(38)
  .or()
  .sizeEqualTo(40)
  .or()
  .sizeEqualTo(42)
  .findAll();

final shoes2 = await isar.shoes.filter()
  .anyOf(
    [38, 40, 42],
    (q, int size) => q.sizeEqualTo(size)
  ).findAll();

// shoes1 == shoes2
```

Les modificateurs de requête sont particulièrement utiles lorsque vous souhaitez construire des requêtes dynamiques.

### Listes

Même les listes peuvent être utilisées dans les requêtes:

```dart
class Tweet {
  Id? id;

  String? text;

  List<String> hashtags = [];
}
```

Vous pouvez effectuer des requêtes en fonction de la longueur de la liste:

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

Ces requêtes sont équivalentes au code Dart `tweets.where((t) => t.hashtags.isEmpty);` et `tweets.where((t) => t.hashtags.length > 5);`. Vous pouvez également effectuer des requêtes sur les éléments de liste:

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

Cette requête est équivalente au code Dart `tweets.where((t) => t.hashtags.contains('flutter'));`.

### Objets embarqués

Les objets embarqués sont l'une des fonctionnalités les plus utiles d'Isar. Ils peuvent être filtrés très efficacement en utilisant les mêmes conditions que celles disponibles pour les objets de niveau supérieur. Supposons que nous ayons le modèle suivant:

```dart
@collection
class Car {
  Id? id;

  Brand? brand;
}

@embedded
class Brand {
  String? name;

  String? country;
}
```

Nous voulons filtrer toutes les voitures qui ont une marque avec le nom `BMW` et le pays `"Allemagne"`. Nous pouvons le faire en utilisant la requête suivante:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

Essayez toujours de regrouper les requêtes imbriquées. La requête ci-dessus est plus efficace que la suivante, même si le résultat est le même:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### Links

Si pour modèle contient des [liens](links), vous pouvez filtrer sur les objets liés ou du nombre d'objets liés.

:::warning
Gardez en tête que les requêtes de liens peuvent être coûteuses car Isar doit rechercher les objets liés. Pensez à utiliser des objets embarqués à la place.
:::

```dart
@collection
class Teacher {
  Id? id;

  late String subject;
}

@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

Nous voulons trouver tous les élèves qui ont un professeur de mathématiques ou d'anglais:

```dart
final result = await isar.students.filter()
  .teachers((q) {
    return q.subjectEqualTo('Math')
      .or()
      .subjectEqualTo('English');
  }).findAll();
```

Les filtres de liens sont évalués à `true` si au moins un objet lié correspond aux conditions.

Cherchons tous les élèves qui n'ont pas de professeur:
  
```dart
final result = await isar.students.filter().teachersLengthEqualTo(0).findAll();
```

or sinon:

```dart
final result = await isar.students.filter().teachersIsEmpty().findAll();
```

## Clauses `Where`

Les clauses `where` sont un outil très puissant, mais il n'est pas toujours facile de les utiliser correctement.

Contrairement aux filtres, les clauses `where` utilisent les index que vous avez définis dans le schéma pour evaluer les conditions de la requête. La requête d'un index est beaucoup plus rapide que le filtrage individuel de chaque entrée.

➡️ En savoir plus: [Indexes](indexes)

:::tip
En règle générale, vous devriez toujours essayer de réduire les entrées autant que possible à l'aide de clauses `where`, et effectuer le reste du filtrage à l'aide de filtres.
:::

Vous pouvez uniquement combiner les clauses `where` en utilisant des **ou** logiques. En d'autres termes, vous pouvez additionner plusieurs clauses `where`, mais vous ne pouvez pas effectuer une requête sur l'intersection de plusieurs clauses `where`.

Ajoutons des index à la collection `Shoe`:

```dart
@collection
class Shoe with IsarObject {
  Id? id;

  @Index()
  Id? size;

  late String model;

  @Index(composite: [CompositeIndex('size')])
  late bool isUnisex;
}
```

Il y a deux index. L'index sur `size` nous permet d'utiliser des clauses `where` comme `.sizeEqualTo()`. L'index composite sur `isUnisex` permet d'utiliser des clauses `where` comme `isUnisexSizeEqualTo()`, mais aussi `isUnisexEqualTo()`, car on peut toujours utiliser n'importe quel préfixe d'un index.

Nous pouvons maintenant réécrire la requête précédente qui trouve des chaussures unisexes de taille 46 en utilisant l'index composé. Cette requête sera beaucoup plus rapide que la précédente:

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

Les clauses `where` ont deux autres superpouvoirs : Elles vous offrent un tri "gratuit" et une opération distincte super rapide.

### Combinaison de clauses `where` et de filtres

Vous vous souvenez des requêtes `shoes.filter()`? Il s'agit en fait d'un raccourci pour `shoes.where().filter()`. Vous pouvez (et devriez) combiner les clauses `where` et les filtres dans une même requête pour bénéficier des avantages des deux:

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

La clause `where` est d'abord appliquée pour réduire le nombre d'objets à filtrer. Ensuite, le filtre est appliqué aux objets restants.

## Triage

Vous pouvez définir comment les résultats doivent être triés lors de l'exécution de la requête en utilisant les méthodes `.sortBy()`, `.sortByDesc()`, `.thenBy()` et `.thenByDesc()`.

Pour trouver toutes les chaussures triées par nom de modèle en ordre croissant et par taille en ordre décroissant sans utiliser d'index:

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

Le tri de nombreux résultats peut s'avérer coûteux, d'autant plus que le tri intervient avant le `offset` et `limit`. Les méthodes de tri ci-dessus ne font jamais appel aux index. Heureusement, nous pouvons à nouveau utiliser le tri par clause `where` et rendre notre requête rapide comme l'éclair, même si nous devons trier un million d'objets.

### Tri par clause `where`

Si vous utilisez une clause `where` **simple** dans votre requête, les résultats sont déjà triés par l'index. Ce n'est pas rien!

Supposons que nous avons des chaussures de taille `[43, 39, 48, 40, 42, 45]` et que nous voulons trouver toutes les chaussures dont la taille est supérieure à `42` et les trier par taille:

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // Trie également les résultats par taille
  .findAll(); // -> [43, 45, 48]
```

Comme vous pouvez le voir, le résultat est trié par l'index `size`. Si vous voulez inverser l'ordre de tri de la clause `where`, vous pouvez donner à `sort` la valeur `Sort.desc` :

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

Parfois, vous ne voulez pas utiliser des clauses `where`, mais vous pouvez tout de même bénéficier du tri implicite. Vous pouvez utiliser la clause `where` `any`:

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

Si vous utilisez un index composé, les résultats sont triés par tous les champs de l'index.

:::tip
Si vous avez besoin que les résultats soient triés, pensez à utiliser un index dans ce but. Surtout si vous travaillez avec `offset()` et `limit()`.
:::

Parfois, il n'est pas possible ou utile d'utiliser un index pour le tri. Dans ce cas, vous devez utiliser des index pour réduire autant que possible le nombre d'entrées résultantes.

## Valuers uniques

Pour ne renvoyer que les entrées ayant des valeurs uniques, utilisez le prédicat `distinct`. Par exemple, pour savoir combien de modèles de chaussures différents vous avez dans votre base de données Isar:

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

Vous pouvez également chaîner plusieurs conditions distinctes pour trouver toutes les chaussures avec des combinaisons modèle-taille distinctes :

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

Seul le premier résultat de chaque combinaison distincte est retourné. Vous pouvez utiliser des clauses `where` et des opérations de tri pour le contrôler.

### Clause `where` distincte

Si vous avez un index non-unique, vous pouvez vouloir obtenir toutes ses valeurs distinctes. Vous pouvez utiliser l'opération `distinctBy` de la section précédente, mais elle est effectuée après le tri et les filtres, ce qui entraîne une certaine lourdeur.  
Si vous n'utilisez qu'une seule clause `where`, vous pouvez vous fier à l'index pour effectuer l'opération de distinction.

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
En théorie, vous pouvez même utiliser plusieurs clauses `where` pour le tri et la distinction. La seule restriction est que ces clauses `where` ne doivent pas se chevaucher et utiliser le même index. Pour un tri correct, elles doivent également être appliquées dans l'ordre de tri. Soyez très prudent si vous vous fiez à cela!
:::

## Décalage et limite

C'est souvent une bonne idée de limiter le nombre de résultats d'une requête pour les listes "lazy". Vous pouvez le faire en définissant un `limit()`:

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

En définissant un `offset()`, vous pouvez également paginer les résultats de votre requête.

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

L'instanciation des objets Dart étant souvent la partie la plus coûteuse de l'exécution d'une requête, il est judicieux de ne charger que les objets dont vous avez besoin.

## Ordre d'exécution

Isar exécute les requêtes toujours dans le même ordre :

1. Traverser l'index primaire ou secondaire pour trouver des objets (appliquer des clauses `where`)
2. Filtrer les objets
3. Trier les résultats
4. Appliquer l'opération distincte
5. Décalage et limite des résultats
6. Retour des résultats

## Opérations de requêtes

Dans les exemples précédents, nous avons utilisé `.findAll()` pour récupérer tous les objets correspondants. Cependant, d'autres opérations sont disponibles:

| Opération        | Description                                                                                                                                                   |
|------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `.findFirst()`   | Retourne seulement le premier objet correspondant ou `null` si aucun ne correspond.                                                                           |
| `.findAll()`     | Retourne tous les objets correspondants.                                                                                                                      |
| `.count()`       | Compte le nombre d'objets correspondant à la requête.                                                                                                         |
| `.deleteFirst()` | Supprime le premier objet correspondant de la collection.                                                                                                     |
| `.deleteAll()`   | Supprime tous les objets correspondants de la collection.                                                                                                     |
| `.build()`       | Compilez la requête pour la réutiliser plus tard. Cela permet d'économiser le coût de construction d'une requête si vous souhaitez l'exécuter plusieurs fois. |

## Requêtes de propriété

Si vous n'êtes intéressé que par les valeurs d'une seule propriété, vous pouvez utiliser une requête de propriété. Il suffit de construire une requête ordinaire et de sélectionner une propriété:

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

L'utilisation d'une seule propriété permet de gagner du temps lors de la désérialisation. Les requêtes de propriétés fonctionnent également pour les objets embarqués et les listes.

## Agrégation

Isar supporte l'agrégation des valeurs d'une requête de propriété. Les opérations d'agrégation disponibles sont les suivantes :

| Opération    | Description                                                                |
|--------------|----------------------------------------------------------------------------|
| `.min()`     | Trouve la valeur minimale ou `null` si aucune ne correspond.               |
| `.max()`     | Trouve la valeur maximale ou `null` si aucune ne correspond.               |
| `.sum()`     | Additionne toutes les valeurs.                                             |
| `.average()` | Calcule la moyenne de toutes les valeurs ou `NaN` si aucune ne correspond. |

L'utilisation des agrégations est beaucoup plus rapide que la recherche de tous les objets correspondants et l'exécution manuelle de l'agrégation.

## Requêtes dynamiques

:::danger
Cette section n'est probablement pas pertinente pour vous. Il est déconseillé d'utiliser des requêtes dynamiques, sauf si vous en avez absolument besoin (ce qui est rarement le cas).
:::

Tous les exemples ci-dessus ont utilisé le `QueryBuilder` et les méthodes d'extension statiques générées. Peut-être voulez-vous créer des requêtes dynamiques ou un langage de requête personnalisé (comme l'inspecteur Isar). Dans ce cas, vous pouvez utiliser la méthode `buildQuery()` :

| Paramètre       | Description                                                                                                          |
|-----------------|----------------------------------------------------------------------------------------------------------------------|
| `whereClauses`  | Les clauses `where` de la requête.                                                                                   |
| `whereDistinct` | Si les clauses `where` doivent retourner des valeurs distinctes (utile uniquement pour les clauses `where` uniques). |
| `whereSort`     | L'ordre de passage des clauses `where` (utile uniquement pour les clauses where `uniques`).                          |
| `filter`        | Le filtre à appliquer aux résultats.                                                                                 |
| `sortBy`        | Une liste de propriétés à trier.                                                                                     |
| `distinctBy`    | Une liste de propriétés à distinguer par.                                                                            |
| `offset`        | Le décalage des résultats.                                                                                           |
| `limit`         | Le nombre maximum de résultats à retourner.                                                                          |
| `property`      | Si elle n'est pas nulle, seules les valeurs de cette propriété sont renvoyées.                                       |

Créons une requête dynamique:

```dart
final shoes = await isar.shoes.buildQuery(
  whereClauses: [
    WhereClause(
      indexName: 'size',
      lower: [42],
      includeLower: true,
      upper: [46],
      includeUpper: true,
    )
  ],
  filter: FilterGroup.and([
    FilterCondition(
      type: ConditionType.contains,
      property: 'model',
      value: 'nike',
      caseSensitive: false,
    ),
    FilterGroup.not(
      FilterCondition(
        type: ConditionType.contains,
        property: 'model',
        value: 'adidas',
        caseSensitive: false,
      ),
    ),
  ]),
  sortBy: [
    SortProperty(
      property: 'model',
      sort: Sort.desc,
    )
  ],
  offset: 10,
  limit: 10,
).findAll();
```

La requête suivante est équivalente:

```dart
final shoes = await isar.shoes.where()
  .sizeBetween(42, 46)
  .filter()
  .modelContains('nike', caseSensitive: false)
  .not()
  .modelContains('adidas', caseSensitive: false)
  .sortByModelDesc()
  .offset(10).limit(10)
  .findAll();
```
