---
title: Création, lecture, modification, suppression
---

# Création, lecture, modification, suppression

Maintenant que vous avez défini vos collections, apprenez à les manipuler!

## Opening Isar

Avant de pouvoir faire quoi que ce soit, nous avons besoin d'une instance Isar. Chaque instance nécessite un répertoire avec droits d'écriture où le fichier de la base de données peut être stocké. Si vous ne spécifiez pas de répertoire, Isar trouvera un répertoire par défaut selon la plate-forme actuelle.

Fournissez tous les schémas que vous souhaitez utiliser avec l'instance Isar. Si vous ouvrez plusieurs instances, vous devez toujours fournir les mêmes schémas à chaque instance.

```dart
final isar = await Isar.open([ContactSchema]);
```

Vous pouvez utiliser la configuration par défaut ou fournir certains des paramètres suivants:

| Config |  Description |
| -------| -------------|
| `name` | Ouvrez plusieurs instances avec des noms distincts. Par défaut, `"default"` est utilisé. |
| `directory` | L'emplacement de stockage de cette instance. Vous pouvez passer un chemin relatif ou absolu. Par défaut, `NSDocumentDirectory` est utilisé pour iOS et `getDataDirectory` pour Android. Non requis pour Web. |
| `relaxedDurability` | Assouplit la garantie de durabilité pour augmenter les performances d'écriture. En cas de crash du système (pas de crash de l'application), il est possible de perdre la dernière transaction validée. La corruption n'est pas possible. |
| `compactOnLaunch` | Conditions pour vérifier si la base de données doit être compactée lors de l'ouverture de l'instance. |
| `inspector` | Active l'inspecteur en mode debug. Cette option est ignorée en mode profile et release. |

Si une instance est déjà ouverte, l'appel à `Isar.open()` donnera l'instance existante sans tenir compte des paramètres spécifiés. Utile pour utiliser Isar dans un isolat.

:::tip
Envisagez d'utiliser le package [path_provider](https://pub.dev/packages/path_provider) pour obtenir un chemin valide sur toutes les plateformes.
:::

L'emplacement de stockage du fichier de la base de données est `répertoire/nom.isar`.

## Lecture de la base de données

Utilisez les instances de `IsarCollection` pour trouver, interroger et créer de nouveaux objets d'un type donné dans Isar.

Pour les exemples ci-dessous, nous supposons que nous avons une collection `Recipe` définie comme suit:

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### Obtenir une collection

Toutes vos collections vivent dans l'instance Isar. Vous pouvez obtenir la collection avec:

```dart
final recipes = isar.recipes;
```
N'oubliez pas d'importer les méthodes d'extension afin d'accéder à la collection depuis l'instance isar.

C'était facile! Si vous ne voulez pas utiliser les accesseurs de collection, vous pouvez aussi utiliser la méthode `collection()`:

```dart
final recipes = isar.collection<Recipe>();
```

### Obtenir un objet (par id)

Nous n'avons pas encore de données dans la collection, mais faisons comme si c'était le cas afin de récupérer un objet imaginaire avec l'identifiant `123`.

```dart
final recipe = await recipes.get(123);
```

`get()` renvoie une `Future` avec soit l'objet, soit `null` s'il n'existe pas. Toutes les opérations d'Isar sont asynchrones par défaut, et la plupart d'entre elles ont un équivalent synchrone:

```dart
final recipe = recipes.getSync(123);
```

:::warning
Vous devriez utiliser la version asynchrone des méthodes par défaut dans votre isolate d'interface utilisateur. Comme Isar est très rapide, il est souvent acceptable d'utiliser la version synchrone.
:::

Si vous voulez récupérer plusieurs objets à la fois, utilisez `getAll()` ou `getAllSync()`:

```dart
final recipe = await recipes.getAll([1, 2]);
```

### Recherche d'objets

Au lieu de récupérer les objets par leur identifiant, vous pouvez également obtenir une liste d'objets répondant à certaines conditions en utilisant `.where()` et `.filter()`:

```dart
final allRecipes = await recipes.where().findAll();

final favouires = await recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ En savoir plus: [Queries](queries)

## Modifier la base de données

Il est enfin temps de modifier notre collection! Pour créer, mettre à jour ou supprimer des objets, utilisez les opérations respectives dans une transaction d'écriture:

```dart
await isar.writeTxn(() async {
  final recipe = await recipes.get(123)

  recipe.isFavorite = false;
  await recipes.put(recipe); // effectuer des opérations de mise à jour

  await recipes.delete(123); // ou des opérations de suppression
});
```

➡️ En savoir plus: [Transactions](transactions)

### Insertion d'objets

Pour faire persister un objet dans Isar, insérez-le dans une collection. La méthode `put()` d'Isar va soit insérer, soit mettre à jour l'objet selon s'il existe déjà dans la collection.

Si le champ id est `null` ou `Isar.autoIncrement`, Isar utilisera un id auto-incrémenté.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await recipes.put(pancakes);
})
```

Isar attribuera automatiquement l'id à l'objet si le champ `id` est non final.

Il est tout aussi facile d'insérer plusieurs objets à la fois:

```dart
await isar.writeTxn(() async {
  await recipes.putAll([pancakes, pizza]);
})
```

### Mise à jour d'objets

La création et la mise à jour fonctionnent toutes deux avec `collection.put(object)`. Si l'id est `null` (ou n'existe pas), l'objet est inséré; sinon, il est mis à jour.

Donc si nous voulons défavoriser nos crêpes, nous pouvons faire ce qui suit:

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await recipes.put(pancakes);
});
```

### Suppression d'objets

Vous voulez vous débarrasser d'un objet dans Isar ? Utilisez `collection.delete(id)`. La méthode `delete` retourne si un objet avec l'identifiant spécifié a été trouvé et supprimé. Si vous désirez supprimer l'objet avec l'identifiant `123`, par exemple, vous pouvez le faire:

```dart
await isar.writeTxn(() async {
  final success = await recipes.delete(123);
  print('Recipe deleted: $success');
});
```

Comme pour les opérations `get` et `put`, il existe également une opération de suppression en vrac qui renvoie le nombre d'objets supprimés:

```dart
await isar.writeTxn(() async {
  final count = await recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

Si vous ne connaissez pas les identifiants des objets que vous voulez supprimer, vous pouvez utiliser une requête:

```dart
await isar.writeTxn(() async {
  final count = await recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
