---
title: Collegamenti
---

# Collegamenti

I collegamenti consentono di esprimere relazioni tra oggetti, come l'autore di un commento (Utente). Puoi modellare le relazioni `1:1`, `1:n` e `n:n` con i collegamenti Isar. L'uso dei collegamenti è meno ergonomico rispetto all'utilizzo di oggetti incorporati e dovresti utilizzare oggetti incorporati quando possibile.

Pensa al collegamento come a una tabella separata che contiene la relazione. È simile alle relazioni SQL ma ha un set di funzionalità e un'API diversi.

## IsarLink

`IsarLink<T>` può contenere nessuno o un oggetto correlato e può essere utilizzato per esprimere una relazione a uno. `IsarLink` ha una singola proprietà chiamata `value` che contiene l'oggetto collegato.

I collegamenti sono pigri, quindi è necessario dire a `IsarLink` di caricare o salvare il `valore` in modo esplicito. Puoi farlo chiamando `linkProperty.load()` e `linkProperty.save()`.

:::tip
La proprietà id delle raccolte di origine e di destinazione di un collegamento deve essere non definitiva.
:::

Per i target non web, i link vengono caricati automaticamente quando li usi per la prima volta. Iniziamo aggiungendo un IsarLink a una collezione:

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

Abbiamo definito un legame tra insegnanti e studenti. Ogni studente può avere esattamente un insegnante in questo esempio.

Innanzitutto, creiamo l'insegnante e lo assegniamo a uno studente. Dobbiamo effettuare un `.put()` per l'insegnante e salvare il collegamento manualmente.

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

Ora possiamo usare il link:

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

Proviamo la stessa cosa con il codice sincrono. Non è necessario salvare il collegamento manualmente perché `.putSync()` salva automaticamente tutti i collegamenti. Crea anche l'insegnante per noi.

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

Avrebbe più senso se lo studente dell'esempio precedente potesse avere più insegnanti. Fortunatamente, Isar ha `IsarLinks<T>`, che può contenere più oggetti correlati ed esprimere una relazione a molti.

`IsarLinks<T>` estende `Set<T>` ed espone tutti i metodi consentiti per gli insiemi.

`IsarLinks` si comporta in modo molto simile a `IsarLink` ed è anche pigro. Per caricare tutti gli oggetti collegati chiama `linkProperty.load()`. Per rendere persistenti le modifiche, chiama `linkProperty.save()`.

Internamente sia "IsarLink" che "IsarLinks" sono rappresentati allo stesso modo. Possiamo aggiornare `IsarLink<Teacher>` da prima a un `IsarLinks<Teacher>` per assegnare più insegnanti a un singolo studente (senza perdere dati).

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

Funziona perché non abbiamo cambiato il nome del collegamento (`teacher`), quindi Isar lo ricorda da prima.

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

## Backlink

Vi sento chiedere: "E se volessimo esprimere relazioni inverse?". Non preoccuparti; ora introdurremo i backlink.

I backlink sono collegamenti nella direzione inversa. Ogni link ha sempre un backlink implicito. Puoi renderlo disponibile per la tua app annotando un `IsarLink` o `IsarLinks` con `@Backlink()`.

I backlink non richiedono memoria o risorse aggiuntive; puoi aggiungerli, rimuoverli e rinominarli liberamente senza perdere dati.

Vogliamo sapere quali studenti ha un insegnante specifico, quindi definiamo un backlink:
```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

Dobbiamo specificare il collegamento a cui punta il backlink. È possibile avere più collegamenti diversi tra due oggetti.

## Inizializza i collegamenti

`IsarLink` e `IsarLinks` hanno un costruttore arg zero, che dovrebbe essere usato per assegnare la proprietà link quando l'oggetto viene creato. È buona norma rendere le proprietà del collegamento "finali".

Quando `metti()` il tuo oggetto per la prima volta, il collegamento viene inizializzato con la raccolta di origine e destinazione e puoi chiamare metodi come `load()` e `save()`. Un collegamento inizia a tenere traccia delle modifiche subito dopo la sua creazione, quindi puoi aggiungere e rimuovere relazioni anche prima che il collegamento venga inizializzato.

:::danger
È vietato spostare un collegamento a un altro oggetto.
:::
