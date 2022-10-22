# Limitations

Comme vous le savez, Isar fonctionne sur les appareils mobiles et les ordinateurs de bureau fonctionnant sur la VM ainsi que sur le Web. Ces deux plateformes sont très différentes, et ont donc des limitations différentes.

## Limitations de la VM

- Seuls les 1024 premiers octets d'une chaîne peuvent être utilisés pour un préfixe de clause `where`.
- Les objets ne peuvent avoir une taille supérieure à 16 Mo

## Limitations Web

Comme Isar Web est basé sur `IndexedDB`, il y a plus de limitations, mais elles sont à peine perceptibles lors de l'utilisation d'Isar.

- Les méthodes synchrones ne sont pas supportées
- Les filtres `Isar.splitWords()` et `.matches()` ne sont pas encore implémentés
- Les changements de schémas ne sont pas autant vérifiés que dans la VM, il faut donc faire attention à respecter les règles
- Tous les types de nombres sont stockés en tant que double (le seul type de nombre js), donc `@Size32` n'a aucun effet
- Les index sont représentés différemment, donc les index de hachage n'utilisent pas moins d'espace (ils fonctionnent toujours de la même manière)
- `col.delete()` et `col.deleteAll()` fonctionnent correctement, mais la valeur de retour n'est pas correcte
- `col.clear()` ne réinitialise pas la valeur d'auto-incrémentation
- `NaN` n'est pas supporté comme valeur
