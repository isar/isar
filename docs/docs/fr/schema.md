---
title: Schéma
---

# Schéma

Lorsque vous utilisez Isar pour stocker les données de votre application, vous devez utiliser des collections. Une collection est comme une table de base de données, et ne peut contenir qu'un seul type d'objet Dart. Chaque objet de collection représente une entrée de données dans la collection correspondante.

La définition d'une collection s'appelle "schéma". Le générateur Isar fera le gros du travail pour nous et générera la plupart du code dont nous avons besoin pour utiliser la collection.

## Anatomie d'une collection

Nous définissons chaque collection Isar en annotant une classe avec `@collection` ou `@Collection()`. Une collection Isar comprend des champs pour chaque colonne de la table correspondante dans la base de données, y compris un champ qui comprend la clé primaire.

Le code suivant est un exemple d'une collection simple qui définit une table `User` avec des colonnes pour l'ID, le prénom et le nom :

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
Pour faire persister un champ, Isar doit y avoir accès. Vous pouvez vous assurer que Isar y a accès en le rendant public ou en fournissant des méthodes `getter` et `setter`.
:::

Il existe quelques paramètres facultatifs permettant de personnaliser la collection:

| Config        | Description                                                                                                         |
| ------------- | ------------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Contrôle si les champs des classes parentes et des mixins seront stockés dans Isar. Activé par défaut.              |
| `accessor`    | Permet de renommer l'accesseur de collection par défaut (par exemple `isar.contacts` pour la collection `Contact`). |
| `ignore`      | Permet d'ignorer certaines propriétés de la classe. Celles-ci sont également respectées pour les classes parentes.  |

### Id Isar

Chaque classe de collection doit définir une propriété id de type `Id`, qui identifie de façon unique un objet. `Id` est un alias pour `int` qui permet au générateur Isar de reconnaître la propriété id.

Isar indexe automatiquement les champs id, ce qui nous permet d'obtenir et de modifier les objets en fonction de leur id de manière efficace.

Vous pouvez soit définir les ids vous-même, soit demander à Isar d'attribuer un id auto-incrémenté. Si le champ `id` est `null` et non `final`, Isar assignera un id auto-incrémenté. Si vous voulez un identifiant auto-incrémenté non nul, vous pouvez utiliser `Isar.autoIncrement` au lieu de `null`.

:::tip
Les identifiants d'auto-incrémentation ne sont pas réutilisés lorsqu'un objet est supprimé. La seule façon de réinitialiser les identifiants d'auto-incrémentation est d'effacer la collection ou la base de données.
:::

### Renommer les collections et champs

Par défaut, Isar utilise le nom de la classe comme nom de collection. De même, Isar utilise les noms de champs comme noms de colonnes dans la base de données. Si vous voulez qu'une collection ou un champ ait un nom différent, ajoutez l'annotation `@Name()`. L'exemple suivant montre des noms personnalisés pour les collections et les champs :

```dart
@collection
@Name("User")
class MyUserClass1 {

  @Name("id")
  Id myObjectId;

  @Name("firstName")
  String theFirstName;

  @Name("lastName")
  String familyNameOrWhatever;
}
```

Vous devriez envisager d'utiliser l'annotation `@Name()` si vous voulez renommer des champs ou des classes Dart qui sont déjà stockés dans la base de données. Sinon, la base de données supprimera et recréera le champ ou la collection.

### Ignorer des champs

Isar persiste tous les champs publics d'une classe de collection. En annotant une propriété ou un `getter` avec `@ignore`, vous pouvez l'exclure de la persistance, comme le montre l'extrait de code suivant:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;

  @ignore
  String? password;
}
```

Dans les cas où une collection hérite de champs d'une collection parente, il est généralement plus facile d'utiliser la propriété `ignore` de l'annotation `@Collection`:

```dart
@collection
class User {
  Image? profilePicture;
}

@Collection(ignore: {'profilePicture'})
class Member extends User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

Si une collection contient un champ dont le type n'est pas supporté par Isar, vous devez ignorer ce champ.

:::warning
Gardez en tête qu'il n'est pas recommandé de stocker des informations dans des objets Isar qui ne sont pas persistants.
:::

## Types supportés

Isar supporte les types de données suivants :

- `bool`
- `byte`
- `short`
- `int`
- `float`
- `double`
- `DateTime`
- `String`
- `List<bool>`
- `List<byte>`
- `List<short>`
- `List<int>`
- `List<float>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

De plus, les objets embarqués (`embedded`) et les enums sont supportés. Nous les aborderons ci-dessous.

## byte, short, float

Pour de nombreux cas d'utilisation, vous n'avez pas besoin de l'étendue complète d'un nombre entier ou double de 64 bits. Isar supporte des types supplémentaires qui vous permettent d'économiser de l'espace et de la mémoire lorsque vous stockez des nombres plus petits.

| Type       | Size in bytes | Range                                                  |
| ---------- | ------------- | ------------------------------------------------------ |
| **byte**   | 1             | 0 à 255                                                |
| **short**  | 4             | -2,147,483,647 à 2,147,483,647                         |
| **int**    | 8             | -9,223,372,036,854,775,807 à 9,223,372,036,854,775,807 |
| **float**  | 4             | -3.4e38 à 3.4e38                                       |
| **double** | 8             | -1.7e308 à 1.7e308                                     |

Les types supplémentaires sont simplement des alias pour les types natifs de Dart, donc utiliser `short`, par exemple, fonctionne de la même manière que `int`.

Voici un exemple de collection contenant les types décrit ci-dessus:

```dart
@collection
class TestCollection {
  Id? id;

  late byte byteValue;

  short? shortValue;

  int? intValue;

  float? floatValue;

  double? doubleValue;
}
```

Tous les types de nombres peuvent également être utilisés dans des listes. Pour stocker des octets (`bytes`), vous devriez utiliser `List<byte>`.

## Types nullables

Il est essentiel de comprendre comment la nullité fonctionne dans Isar: Les types de nombres n'ont **PAS** de représentation `null` dédiée. À la place, une valeur spécifique est utilisée:

| Type       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    | `int.MIN`     |
| **float**  | `double.NaN`  |
| **double** | `double.NaN`  |

`bool`, `String`, et `List` ont une représentation `null` séparée.

Ce comportement permet d'améliorer les performances, et il vous permet de modifier librement la nullité de vos champs sans nécessiter de migration ou de code spécial pour gérer les valeurs "nulles".

:::warning
Le type `byte` ne supporte pas les valeurs nulles.
:::

## DateTime

Isar ne stocke pas les informations de fuseau horaire de vos dates. À la place, il les convertit en UTC avant de les stocker. Isar retourne toutes les dates en heure locale.

Les `DateTime` sont stockés avec une précision de l'ordre de la microseconde. Dans les navigateurs, seule la précision de la milliseconde est supportée en raison des limitations de JavaScript.

## Enum

Isar permet de stocker et d'utiliser les enums comme tous les autres types Isar. Vous devez cependant choisir comment Isar doit représenter l'enum sur disque. Isar supporte quatre stratégies différentes :

| EnumType    | Description                                                                                      |
| ----------- | ------------------------------------------------------------------------------------------------ |
| `ordinal`   | L'index de l'enum est stocké comme `byte`. Très efficace mais ne permet pas les enums nullables. |
| `ordinal32` | L'index de l'enum est stocké comme `short` (entier de 4 octets).                                 |
| `name`      | Le nom de l'enum est stocké comme `String`.                                                      |
| `value`     | Une propriété personnalisée est utilisée pour récupérer la valeur de l'enum.                     |

:::warning
`ordinal` et `ordinal32` dépendent de l'ordre des valeurs de l'enum. Si vous changez l'ordre, les bases de données existantes renverront des valeurs incorrectes.
:::

Voici un exemple pour chaque stratégie:

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // Même chose que EnumType.ordinal
  late TestEnum byteIndex; // Ne peut pas être nulle

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // Ne peut pas être nulle

  @Enumerated(EnumType.ordinal32)
  TestEnum? shortIndex;

  @Enumerated(EnumType.name)
  TestEnum? name;

  @Enumerated(EnumType.value, 'myValue')
  TestEnum? myValue;
}

enum TestEnum {
  first(10),
  second(100),
  third(1000);

  const TestEnum(this.myValue);

  final short myValue;
}
```

Bien entendu, les enums peuvent également être utilisés dans des listes.

## Objets embarqués

Il est souvent utile d'avoir des objets imbriqués dans votre modèle de collection. Il n'y a pas de limite à la profondeur à laquelle vous pouvez imbriquer des objets. Gardez cependant à l'esprit que la mise à jour d'un objet profondément imbriqué nécessitera l'écriture de l'arbre d'objets complet dans la base de données.

```dart
@collection
class Email {
  Id? id;

  String? title;

  Recepient? recipient;
}

@embedded
class Recepient {
  String? name;

  String? address;
}
```

Les objets embarqués peuvent être nullables et hériter d'autres objets. La seule condition est qu'ils soient annotés avec `@embedded` et qu'ils aient un constructeur par défaut sans paramètres requis.
