---
title: Recherche plein texte
---

# Recherche plein texte

La recherche plein texte est un moyen puissant de rechercher du texte dans la base de données. Vous devriez déjà être familiarisé avec le fonctionnement des [indices](../indexes), mais passons en revue les principes de base.

Un index fonctionne comme une table de recherche, permettant au moteur de recherche de trouver rapidement les enregistrements ayant une valeur donnée. Par exemple, si nous avons un champ "titre" dans notre objet, nous pouvons créer un index sur ce champ afin de trouver plus rapidement les objets ayant un titre donné.

## Pourquoi la recherche plein texte est-elle utile?

Nous pouvons facilement rechercher du texte en utilisant des filtres. Il existe plusieurs opérations de chaînes de caractères, par exemple `.startsWith()`, `.contains()` et `.matches()`. Le problème avec les filtres est que leur temps d'exécution est de `O(n)`, où `n` est le nombre d'enregistrements dans la collection. Les opérations sur chaînes de caractères comme `.matches()` sont particulièrement coûteuses.

:::tip
La recherche plein texte est beaucoup plus rapide que les filtres, mais les index ont certaines limites. Dans cette recette, nous allons explorer comment contourner ces limites.
:::

## Exemple de base

L'idée est toujours la même: au lieu d'indexer l'ensemble du texte, nous indexons les mots du texte afin de pouvoir les rechercher individuellement.

Créons l'index plein texte le plus basique:

```dart
class Message {
  Id? id;

  late String content;

  @Index()
  List<String> get contentWords => content.split(' ');
}
```

Nous pouvons maintenant rechercher des messages dont le contenu contient des mots spécifiques:

```dart
final posts = await isar.messages
  .where()
  .contentWordsAnyEqualTo('hello')
  .findAll();
```

Cette requête est super rapide, mais il y a quelques problèmes:

1. Nous ne pouvons rechercher que des mots entiers
2. Nous ne tenons pas compte de la ponctuation
3. Nous ne prenons pas en charge les autres caractères d'espacement

## Diviser le texte de la bonne manière

Essayons d'améliorer l'exemple précédent. Nous pourrions essayer de développer une regex compliquée pour corriger le découpage de mots, mais cela sera probablement lent et incorrect dans certains cas.

Le [Unicode Annex #29](https://unicode.org/reports/tr29/) définit comment diviser correctement un texte en mots pour presque toutes les langues. C'est assez compliqué, mais heureusement, Isar fait le gros du travail pour nous:

```dart
Isar.splitWords('hello world'); // -> ['hello', 'world']

Isar.splitWords('The quick (“brown”) fox can’t jump 32.3 feet, right?');
// -> ['The', 'quick', 'brown', 'fox', 'can’t', 'jump', '32.3', 'feet', 'right']
```

## Je veux plus de contrôle

C'est simple et facile! Nous pouvons également modifier notre index pour supporter la comparaison des préfixes et la correspondance insensible à la casse:

```dart
class Post {
  Id? id;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get titleWords => title.split(' ');
}
```

Par défaut, Isar stocke les mots sous forme de valeurs hachées, ce qui est rapide et peu encombrant. Mais les valeurs hachées ne peuvent pas être utilisées pour la comparaison des préfixes. En utilisant `IndexType.value`, nous pouvons changer l'index pour utiliser directement les mots à la place. Cela nous donne la clause `where` `.titleWordsAnyStartsWith()`:

```dart
final posts = await isar.posts
  .where()
  .titleWordsAnyStartsWith('hel')
  .or()
  .titleWordsAnyStartsWith('welco')
  .or()
  .titleWordsAnyStartsWith('howd')
  .findAll();
```

## Je veux aussi `.endsWith()`

Bien sûr! Nous allons utiliser une astuce pour réaliser la comparaison `.endsWith()`:

```dart
class Post {
    Id? id;

    late String title;

    @Index(type: IndexType.value, caseSensitive: false)
    List<String> get revTitleWords {
        return Isar.splitWords(title).map(
          (word) => word.reversed).toList()
        );
    }
}
```

N'oublions pas d'inverser la terminaison que nous voulons rechercher:

```dart
final posts = await isar.posts
  .where()
  .revTitleWordsAnyStartsWith('lcome'.reversed)
  .findAll();
```

## Algorithmes de racinisation (`stemming`)

Malheureusement, les index ne supportent pas la comparaison `.contains()` (ceci est vrai pour d'autres bases de données également). Mais il y a quelques alternatives qui valent la peine d'être explorées. Le choix dépend fortement de votre utilisation. Un exemple est l'indexation des racines de mots au lieu du mot entier.

Un algorithme de racinisation est un processus de normalisation linguistique dans lequel les différentes formes d'un mot sont réduites à une forme commune :

```
connexion
connexions
connectif          --->   connect
connecté
connecter
```

Les algorithmes les plus populaires sont [Porter stemming algorithm](https://tartarus.org/martin/PorterStemmer/) et [Snowball stemming algorithms](https://snowballstem.org/algorithms/).

Il existe également des formes plus avancées comme la [Lemmatisation](https://fr.wikipedia.org/wiki/Lemmatisation).

## Algorithmes phonétiques

Un [algorithme phonétique](https://fr.wikipedia.org/wiki/Algorithme_phon%C3%A9tique) est un algorithme permettant d'indexer les mots en fonction de leur prononciation. En d'autres termes, il nous permet de trouver des mots dont la sonorité est similaire à celle des mots que nous voulons recherchez.

:::warning
La plupart des algorithmes phonétiques ne supportent qu'une seule langue.
:::

### Soundex

[Soundex](https://fr.wikipedia.org/wiki/Soundex) est un algorithme phonétique d'indexation des noms par le son, tel qu'il est prononcé en anglais. Le but est que les homophones soient encodés dans la même représentation, afin qu'ils puissent être mis en relation malgré des différences mineures dans l'orthographe. Il s'agit d'un algorithme simple, et il existe de nombreuses versions améliorées.

En utilisant cet algorithme, `"Robert"` et `"Rupert"` renvoient tous deux la chaîne `"R163"`, tandis que `"Rubin"` donne `"R150"`. `"Ashcraft"` et `"Ashcroft"` donnent tous deux `"A261"`.

### Double Metaphone

L'algorithme de codage phonétique [Double Metaphone](https://fr.wikipedia.org/wiki/Metaphone) est la deuxième génération de cet algorithme. Il apporte plusieurs améliorations fondamentales à la conception de l'algorithme Metaphone original.

Double Metaphone prend en compte diverses irrégularités de l'anglais d'origine slave, germanique, celtique, grecque, française, italienne, espagnole, chinoise et autres.
