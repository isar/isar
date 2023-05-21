---
title: Liens
---

# Liens

Les liens nous permettent d'exprimer des relations entre objets, comme l'auteur d'un commentaire (`User`). Nous pouvons modéliser des relations `1:1`, `1:n`, et `n:n` avec les liens Isar. L'utilisation de liens est moins ergonomique que l'utilisation d'objets embarqués. Il est donc préférable d'utiliser des objets embarqués lorsque possible.

Considérez le lien comme une table séparée qui contient la relation. Elle est similaire aux relations SQL, mais possède un ensemble de fonctionnalités et une API différente.

## IsarLink

`IsarLink<T>` peut contenir un ou plusieurs objets liés et peut être utilisé pour exprimer une relation de type "un-à-un". `IsarLink` a une seule propriété appelée `value` qui contient l'objet lié.

Les liens ne sont pas chargés par default. Vous devez donc dire à `IsarLink` de charger ou de sauvegarder la `value` explicitement. Vous pouvez le faire en appelant `linkProperty.load()` et `linkProperty.save()`.

:::tip
La propriété `id` des collections source et cible d'un lien doit être non finale.
:::

Pour les plateformes autres que web, les liens sont chargés automatiquement lorsque vous les utilisez pour la première fois. Commençons par ajouter un `IsarLink` à une collection:

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

  final teacher = IsarLink<Teacher>();
}
```

Nous avons défini un lien entre les enseignants et les élèves. Dans cet exemple, chaque élève peut avoir exactement un professeur.

D'abord, nous créons le professeur et l'assignons à un étudiant. Nous devons `.put()` le professeur et sauvegarder le lien manuellement.

```dart
final mathTeacher = Teacher()..subject = 'Math';

final linda = Student()
  ..name = 'Linda'
  ..teacher.value = mathTeacher;

await isar.writeTxn(() async {
  await isar.students.put(linda);
  await isar.teachers.put(mathTeacher);
  await linda.teacher.save();
});
```

Nous pouvons maintenant utiliser le lien :

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

Essayons la même chose avec du code synchrone. Nous n'avons pas besoin de sauvegarder le lien manuellement, car `.putSync()` sauvegarde automatiquement tous les liens. Il crée même le professeur pour nous.

```dart
final englishTeacher = Teacher()..subject = 'English';

final david = Student()
  ..name = 'David'
  ..teacher.value = englishTeacher;

isar.writeTxnSync(() {
  isar.students.putSync(david);
});
```

## IsarLinks

Il serait plus logique que l'étudiant de l'exemple précédent puisse avoir plusieurs professeurs. Heureusement, Isar a `IsarLinks<T>`, qui permet de contenir plusieurs objets liés et d'exprimer une relation de type "à plusieurs".

`IsarLinks<T>` implémente `Set<T>` et expose toutes les méthodes qui sont autorisées pour les ensembles.

`IsarLinks` se comporte comme `IsarLink` et n'est également pas changé par défaut. Pour charger tous les objets liés, nous devons utiliser `linkProperty.load()`. Pour persister les changements, `linkProperty.save()`.

La représentation interne de `IsarLink` et `IsarLinks` est la même. Nous pouvons faire évoluer le `IsarLink<Teacher>` d'avant en un `IsarLinks<Teacher>` pour assigner plusieurs professeurs à un seul étudiant (sans perdre de données).

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

Cela fonctionne étant donné que nous n'avons pas changé le nom du lien (`teacher`), donc Isar s'en souvient d'avant.

```dart
final biologyTeacher = Teacher()..subject = 'Biology';

final linda = isar.students.where()
  .filter()
  .nameEqualTo('Linda')
  .findFirst();

print(linda.teachers); // {Teacher('Math')}

linda.teachers.add(biologyTeacher);

await isar.writeTxn(() async {
  await linda.teachers.save();
});

print(linda.teachers); // {Teacher('Math'), Teacher('Biology')}
```

## Backlinks

Je vous entends demander: "Et si nous voulions exprimer des relations inverses?". Ne vous inquiétez pas, nous allons maintenant introduire les `Backlinks`.

Les backlinks sont des liens en sens inverse. Chaque lien a toujours un backlink implicite. Nous pouvons le rendre disponible à notre application en annotant un `IsarLink` ou un `IsarLinks` avec `@Backlink()`.

Les backlinks ne nécessitent pas de mémoire ou de ressources supplémentaires; nous pouvons librement les ajouter, les supprimer et les renommer sans perdre de données.

Pour savoir quels sont les étudiants d'un enseignant spécifique, nous définissons donc un lien retour:

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

Il faut préciser le lien vers lequel pointe le backlink. Il est possible d'avoir plusieurs liens différents entre deux objets.

## Initialisation des liens

`IsarLink` et `IsarLinks` ont un constructeur sans argument, qui devrait être utilisé pour assigner la propriété de lien quand l'objet est créé. C'est une bonne pratique de rendre les propriétés de lien `final`.

Lorsque nous sauvegardons (`put()`) notre objet pour la première fois, le lien est initialisé avec la collection source et cible, et nous pouvons appeler des méthodes comme `load()` et `save()`. Un lien commence à suivre les changements immédiatement après sa création, donc nous pouvons ajouter et supprimer des relations avant même que le lien soit initialisé.

:::danger
Il est illégal de déplacer un lien vers un autre objet.
:::
