---
title: Utilisation multi-isolats
---

# Utilisation multi-isolats

Au lieu de threads, tout code Dart s'exécute dans des isolats. Chaque isolat possède son propre espace mémoire, ce qui garantit qu'aucun des états d'un isolat n'est accessible depuis un autre isolat.

Il est possible d'accéder à Isar à partir de plusieurs isolats en même temps. Même les observateurs fonctionnent à travers les isolats. Dans cette recette, nous allons voir comment utiliser Isar dans un environnement multi-isolats.

## Quand utiliser plusieurs isolats

Les transactions Isar sont exécutées en parallèle, même si elles sont exécutées dans le même isolat. Dans certains cas, il est toujours utile d'accéder à Isar à partir de plusieurs isolats.

La raison en est qu'Isar passe un certain temps à encoder et décoder des données depuis et vers des objets Dart. Nous pouvons imaginer que c'est comme coder et décoder en JSON (en plus efficace). Ces opérations s'exécutent à l'intérieur de l'isolat à partir duquel on accède aux données et bloquent naturellement les autres codes de l'isolat. En d'autres termes: Isar effectue une partie du travail dans votre isolat Dart.

Si nous n'avons besoin de lire ou d'écrire que quelques centaines d'objets à la fois, le faire dans l'isolat de l'interface utilisateur ne pose pas de problème. Mais pour les transactions importantes ou si le thread de l'interface utilisateur est déjà occupé, nous devrions envisager d'utiliser un isolat séparé.

## Exemple

La première chose que nous devons faire est d'ouvrir Isar dans le nouvel isolat. Puisque l'instance de Isar est déjà ouverte dans l'isolat principal, `Isar.open()` retournera la même instance.

:::warning
Assurez-vous de fournir les mêmes schémas que dans l'isolat principal. Sinon, vous obtiendrez une erreur.
:::

`compute()` démarre un nouvel isolat dans Flutter et y exécute la fonction donnée.

```dart
void main() {
  // Ouvre Isar dans l'isolat de l'interface utilisateur
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [MessageSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  // Écoute les changements dans la base de données
  isar.messages.watchLazy(() {
    print('omg the messages changed!');
  });

  // Démarre un nouvel isolat et crée 10000 messages
  compute(createDummyMessages, 10000).then(() {
    print('isolate finished');
  });

  // Après quelque temps:
  // > omg the messages changed!
  // > isolate finished
}

// Fonction qui sera exécutée dans le nouvel isolat
Future createDummyMessages(int count) async {
  // Nous n'avons pas besoin du chemin du dossier ici étant donné que l'instance est déjà ouverte.
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [PostSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Message $i');
  // Nous utilisons une transaction synchrone en isolat
  isar.writeTxnSync(() {
    isar.messages.insertAllSync(messages);
  });
}
```

Il y a quelques éléments intéressants à noter dans l'exemple ci-dessus:

- `isar.messages.watchLazy()` est appelé dans l'isolat UI et est notifié des changements provenant d'un autre isolat.
- Les instances sont référencées par leur nom. Le nom par défaut est `default`, mais dans cet exemple, nous l'avons défini comme `myInstance`.
- Nous avons utilisé une transaction synchrone pour créer les mesasges. Bloquer notre nouvel isolat n'est pas un problème, et les transactions synchrones sont un peu plus rapides.
