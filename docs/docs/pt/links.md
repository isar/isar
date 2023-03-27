---
title: Links
---

# Links

Os links permitem que você expresse relacionamentos entre objetos, como o autor de um comentário (Usuário). Você pode modelar relacionamentos `1:1`, `1:n` e `n:n` com links Isar. Usar links é menos ergonômico do que usar objetos incorporados e você deve usar objetos incorporados sempre que possível.

Pense no link como uma tabela separada que contém a relação. É semelhante às relações SQL, mas possui um conjunto de recursos e API diferentes.

## IsarLink

`IsarLink<T>` pode conter nenhum ou um objeto relacionado e pode ser usado para expressar um relacionamento de um para um. `IsarLink` tem uma única propriedade chamada `value` que contém o objeto vinculado.
Os links são preguiçosos, então você precisa dizer ao `IsarLink` para carregar ou salvar o `valor` explicitamente. Você pode fazer isso chamando `linkProperty.load()` e `linkProperty.save()`.

:::tip
A propriedade id das coleções de origem e destino de um link não deve ser final.
:::

Para destinos não Web, os links são carregados automaticamente quando você os usa pela primeira vez. Vamos começar adicionando um IsarLink a uma coleção:

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

Definimos um vínculo entre teachers e students. Cada student pode ter exatamente um teacher neste exemplo.

Primeiro, criamos o teacher e o atribuímos a um student. Temos que fazer o `.put()` do teacher e salvar o link manualmente.

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

Agora podemos usar o link:

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

Vamos tentar a mesma coisa com código síncrono. Não precisamos salvar o link manualmente porque `.putSync()` salva automaticamente todos os links. Até cria o professor para nós.

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

Faria mais sentido se o aluno do exemplo anterior pudesse ter vários professores. Felizmente, Isar tem `IsarLinks<T>`, que pode conter vários objetos relacionados e expressar um relacionamento para muitos.

`IsarLinks<T>` estende `Set<T>` e expõe todos os métodos permitidos para sets.

`IsarLinks` se comporta muito como `IsarLink` e também é preguiçoso. Para carregar todos os objetos vinculados, chame `linkProperty.load()`. Para persistir as alterações, chame `linkProperty.save()`.

Internamente, `IsarLink` e `IsarLinks` são representados da mesma maneira. Podemos atualizar o `IsarLink<Teacher>` de antes para um `IsarLinks<Teacher>` para atribuir vários professores a um único aluno (sem perder dados).

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

Isso funciona porque não mudamos o nome do link (`professor`), então Isar se lembra de antes.

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

Eu ouço você perguntar: "E se quisermos expressar relacionamentos reversos?". Não se preocupe; agora vamos apresentar backlinks.

Backlinks são links na direção inversa. Cada link sempre tem um backlink implícito. Você pode disponibilizá-lo para seu aplicativo anotando um `IsarLink` ou `IsarLinks` com `@Backlink()`.

Backlinks não requerem memória ou recursos adicionais; você pode adicionar, remover e renomeá-los livremente sem perder dados.

Queremos saber quais students um teacher específico tem, então definimos um backlink:

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

Precisamos especificar o link para o qual o backlink aponta. É possível ter vários links diferentes entre dois objetos.

## Inicializar links

`IsarLink` e `IsarLinks` possuem um construtor sem argumentos, que deve ser usado para atribuir a propriedade link quando o objeto for criado. É uma boa prática tornar as propriedades do link `final`.

Quando você faz o `put()` do seu objeto pela primeira vez, o link é inicializado com a coleção de origem e destino, e você pode chamar métodos como `load()` e `save()`. Um link começa a rastrear as alterações imediatamente após sua criação, para que você possa adicionar e remover relações antes mesmo de o link ser inicializado.

:::danger
É ilegal mover um link para outro objeto.
:::
