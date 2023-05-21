---
title: リンク
---

# リンク

リンクは、例えばコメントの作成者(User)のようなオブジェクト間の関係を表現することができ、 `1:1`、`1:n`、`n:n`の関係を IsarLinkで表現することができます。リンクの使用は、埋め込みオブジェクトの使用よりも人間工学的に劣るので、可能な限り埋め込みオブジェクトを使用するようにしましょう。

リンクはリレーションを含む別のテーブルだと考えてください。これはSQLのリレーションと似ていますが、異なった機能セットとAPIを持っています。

## IsarLink

`IsarLink<T>` は関連するオブジェクトを含まないか、1つだけ含むことができ、一対一の関係を表現するために使用することができます。`IsarLink` はリンク先のオブジェクトを保持する `value` というプロパティをひとつだけ持っています。

リンクは遅延(lazy)する為、 `IsarLink` に対して、明示的に `value` を読み込みまたは保存するように指示する必要があります。これは、 `linkProperty.load()` と `linkProperty.save()` を呼び出すことで実現できます。

:::tip
Linkの元(Source)コレクションと対象(Target)コレクションの id プロパティは非final値にすべきです。
:::

Web 以外の対象ついては、リンクは初めて使用する際に自動的に読み込まれます。まずは、IsarLinkをコレクションに追加してみましょう。

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

教師と生徒を介するリンクを定義しました。この例では、全ての生徒が1人だけの教師を持つことができます。

まず、教師を作成し、生徒に割り当てます。教師を `.put()` して、手動でリンクを保存する必要があります。

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

これでリンクが使えるようになりました：

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

同じことを同期コードで試してみましょう。`.putSync()`が自動的にすべてのリンクを保存するので、手動でリンクを保存する必要はありません。さらには、教師も自動作成してくれます。

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

前の例の生徒が複数の教師を持つことができれば、理にかなっていますよね。幸いなことに、Isarには `IsarLinks<T>` があり、複数の関連オブジェクトを含むことができ、対多関係を表現することができます。

`IsarLinks<T>` は `Set<T>` を継承しており、Setに対して許可されている全てのメソッドを実装しています。

`IsarLinks` は `IsarLink` と同じように動作し、遅延(lazy)します。リンクされたオブジェクトを全て読み込むには、 `linkProperty.load()` を呼び出します。変更を持続させるには、 `linkProperty.save()` を呼び出します。

内部的には、`IsarLink` と `IsarLinks` は同じように表現されています。先ほどの `IsarLink<Teacher>` を `IsarLinks<Teacher>` にアップグレードすれば、（データを失うことなく）一人の生徒に複数の教師を割り当てることができます。

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

リンクの名前（`teacher`）を変更していないので、Isarがそれを記憶しています。
その為、データを失わずに機能します。

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

逆方向の関係を表現したい場合はどうすればいいのでしょうか？安心してください。これからバックリンクを紹介します。

バックリンクとは、逆方向のリンクのことです。各リンクは、常に暗黙のバックリンクを持っています。`IsarLink` や `IsarLinks` に `@Backlink()` というアノテーションをつけることで、アプリでバックリンクを利用できるようになります。

バックリンクは追加のメモリやリソースを必要としません。データを失うことなく、自由に追加、削除、名前の変更を行うことができます。

特定の教師がどのような生徒を持っているかを知りたいので、バックリンクを定義します。

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

また、バックリンクが指し示すリンクを明示する必要があります。２つのオブジェクトの間に複数の異なるリンクを設定することが可能です。

## リンクの初期化

`IsarLink` と `IsarLinks` にはゼロ引数のコンストラクタがあり、オブジェクトの生成時にリンクのプロパティを代入するために使用されます。リンクのプロパティを `final` にするのは良い習慣です。

オブジェクトを初めて `put()` したとき、リンクは元(Source)コレクションと対象(Target)コレクションで初期化され、 `load()` や `save()` といったメソッドを呼び出すことができるようになります。リンクは作成後すぐに変更の追跡を開始するので、リンクが初期化される前でもリレーションを追加したり削除したりすることができます。

:::danger
リンクを他のオブジェクトに移動することは不正(illegal)です。
:::
