---
title: FAQ
---

# Foire aux questions

Une compilation de questions fréquemment posées sur les bases de données Isar et Flutter.

### Pourquoi ai-je besoin d'une base de données?

> Je stocke mes données dans une base de données backend, pourquoi ai-je besoin d'Isar?

Aujourd'hui encore, il est très courant de ne pas avoir de connexion internet si vous êtes dans le métro, dans l'avion, ou si vous rendez visite à votre grand-mère, qui n'a pas de WiFi et un très mauvais signal cellulaire. Vous ne devez pas laisser une mauvaise connexion paralyser votre application!

### Isar vs Hive

La réponse est simple: Isar a été [lancé comme un remplacement de Hive](https://github.com/hivedb/hive/issues/246) et est maintenant à un stade où on recommande de toujours utiliser Isar plutôt que Hive.

### Clauses `where`?!

> Pourquoi est-ce que **_je_** dois choisir quel index utiliser?

Il y a plusieurs raisons. De nombreuses bases de données utilisent des heuristiques pour choisir le meilleur index pour une requête donnée. La base de données doit collecter des données d'utilisation supplémentaires (-> temps de traitement plus grand) et peut toujours choisir le mauvais index. Cela rend également la création d'une requête plus lente.

Personne ne connaît mieux vos données que vous, le développeur. Vous pouvez donc choisir l'index optimal et décider, par exemple, si vous voulez utiliser un index pour la requête ou le tri.

### Dois-je utiliser des index / clauses `where`?

Non! Isar est très probablement assez rapide si vous ne comptez que sur les filtres.

### Isar est-il suffisamment rapide ?

Isar est l'une des bases de données les plus rapides pour les appareils mobiles, et devrait donc être suffisamment rapide pour la plupart des cas d'utilisation. Si vous rencontrez des problèmes de performances, il y a de fortes chances que vous fassiez quelque chose de mal.

### Isar augmente-t-il la taille de mon application?

Un peu, oui. Isar augmentera la taille de téléchargement de votre application d'environ 1 à 1,5 Mo. Isar Web n'ajoute que quelques Ko.

### La documentation est incorrecte / il y a une erreur de frappe.

Oh non, désolé. Veuillez [ouvrir un ticket](https://github.com/isar/isar/issues/new/choose) ou, mieux encore, un PR pour le résoudre 💪.
