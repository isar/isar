---
title: Links
---

# Links

Links ermöglichen es dir Verhältnisse zwischen Objekten, wie z.B. dem Autor (Benutzer) eines Kommentars, auszudrücken. Du kannst `1:1`, `1:n`, `n:m` Verhältnisse mit Isar-Links modellieren. Links zu nutzen ist unpraktischer als eingebettete Objekte zu benutzen, und du solltest eingebettete Objekte, wann immer möglich, verwenden.

Stell dir den Link wie eine separate Tabelle vor, die die Beziehung enthält. Links ähneln SQL-Beziehungen, haben aber einen anderen Funktionsumfang und eine andere API.

## IsarLink

`IsarLink<T>` kann keines oder ein zugehöriges Objekt enthalten und kann genutzt werden um eine zu-einem-Relation darzustellen. `IsarLink` hat eine einzige Eigenschaft genannt `value`, die das verlinkte Objekt enthält.

Links sind lazy, also musst du dem `IsarLink` explizit sagen den `value` zu Laden oder zu Speichern. Das kannst du erreichen, indem du `linkProperty.load()` und `linkProperty.save()` aufrufst.

:::tip
Die ID-Eigenschaft der Quell- und Ziel-Collections sollte nicht-final sein.
:::

Für nicht-Web-Ziele werden Links automatisch geladen, wenn du sie zum ersten Mal verwendest. Fangen wir damit an einen IsarLink zu einer Collection hinzuzufügen:

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

Wir haben einen Link zwischen Lehrern und Schülern definiert. Jeder Schüler kann in diesem Beispiel genau einen Lehrer haben.

Zuerst legen wir einen Lehrer an und fügen ihn dann einem Schüler hinzu. Wir müssen den Lehrer mit der `.put()`-Methode einfügen und den Link manuell speichern.

```dart
final mathTeacher = Teacher()..subject = 'Math';

final linda = Student()
  ..name = 'Linda'
  ..teacher.value = mathTeacher;

await isar.writeTxn(() async {
  await isar.students.put(linda);
  await isar.teachers.put(mathTeacher);
  await linda.teachers.save();
});
```

Wir können den Link jetzt nutzen:

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

Versuchen wir das gleiche mit synchronem Code. Wir brauchen den Link nicht manuell zu speichern, weil `.putSync()` automatisch alle Links speichert. Es erzeugt sogar den Lehrer für uns.

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

Es würde mehr Sinn ergeben, wenn der Schüler aus dem vorherigen Beispiel mehrere Lehrer haben kann. Glücklicherweise hat Isar `IsarLinks<T>`, was mehrere zugehörige Objekte beinhalten kann und eine zu-vielen-Relation ausdrückt.

`IsarLinks<T>` wird von `Set<T>` erweitert und stellt alle Methoden die auf Sets angewandt werden können zur Verfügung.

`IsarLinks` verhält sich ähnlich wie `IsarLink` und ist auch lazy. Um alle verlinkten Objekte zu laden, musst du die Methode `linkProperty.load()` aufrufen. Um die Änderungen persistent zu machen, musst du `linkProperty.save()` aufrufen.

Intern werden `IsarLink` und `IsarLinks` auf die gleiche Weise dargestellt. Wir können den `IsarLink<Teacher>` von vorher zu einem `IsarLinks<Teacher>` ausbauen, um mehrere Lehrer einem einzelnen Schüler zuzuweisen (ohne Daten zu verlieren).

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teacher = IsarLinks<Teacher>();
}
```

Das funktioniert, weil wir den Namen des Links (`teacher`) nicht verändert haben, weshalb sich Isar von vorher daran erinnert.

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

## Rückverlinkungen

Ich höre dich schon, "Was, wenn wir umgekehrte Relationen ausdrücken möchten?", fragen. Mach dir keine Sorgen; wir führen jetzt Rückverlinkungen ein.

Rückverlinkungen sind Links in umgekerhrter Richtung. Jeder Link hat implizit immer eine Rückverlinkung. Du kannst sie in deiner App verfügbar machen, indem du `IsarLink` oder `IsarLinks` mit `@Backlink()` annotierst.

Rückverlinkungen benötigen keinen zusätzlichen Speicher oder Ressourcen; du kannst sie frei hinzufügen, löschen und umbenennen, ohne Daten zu verlieren.

Wir wollen wissen, welche Schüler ein spezifischer Lehrer hat, also definieren wir eine Rückverlinkung:

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

Wir müssen angeben, auf welchen Link die Rückverlinkung zeigt. Es ist möglich, mehrere verschiedene Links zwischen zwei Objekten zu haben.

## Links initialisieren

`IsarLink` und `IsarLinks` haben Konstruktoren ohne Argumente und sollten verwendet werden um die Link-Eigenschaft anzugeben, wenn das Objekt erstellt wird. Es hat sich bewährt Link-Eigenschaften `final` zu setzen.

Wenn du dein Objekt zum ersten Mal mit der `put()`-Methode speicherst, wird der Link mit Quell- und Ziel-Collection initialisiert und du kannst Methoden wie `load()` und `save()` benutzen. Ein Link fängt sofort an Änderungen zu verfolgen, nachdem er erzeugt wurde, sodass du Relationen sogar anlegen oder entfernen kannst, bevor der Link initialisiert wurde.

:::danger
Es ist verboten einen Link zu einem anderen Objekt zu übertragen.
:::
