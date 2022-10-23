---
title: 链接（Links)
---

# 链接（Links）

链接允许你表达对象之间的关系，比如一个评论的作者（用户）。你可以用Isar链接建立`1:1`、`1:n`和`n:n`的关系。使用链接比使用嵌套对象更不符合人体工程学，你应该尽可能地使用嵌套对象。

你可以把链接看成是一个包含关系的单独的表。它类似于SQL关系表，但有不同的特性和API。

## IsarLink

`IsarLink<T>`可以不包含或只包含一个相关对象，它可以用来表达一对一的关系。`IsarLink`有一个名为`value`的唯一参数，它指向被链接对象。

链接是惰性的，所以你需要告诉`IsarLink`明确加载或保存`value`。你可以通过调用`linkProperty.load()`和`linkProperty.save()`来做到这一点。

:::tip
一个链接的源集合和目标集合的id字段应该不能是final的。
:::

对于非网页端平台，当你第一次使用时，链接会自动加载。让我们先把IsarLink添加到一个集合中：

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

我们定义了教师和学生之间的联系。在这个例子中，每个学生正好可以有一个老师。

首先，我们创建教师并将其分配给一个学生。我们必须先通过`.put()`添加老师并手动保存链接：

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

我们现在可以使用该链接：

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

让我们试试用同步代码做同样的事情。我们不需要手动保存链接，因为`.putSync()`自动保存所有链接。它甚至为我们创建了老师。

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

更具现实意义的是前面的例子中的学生可以有多个老师。幸运的是，Isar有`IsarLinks<T>`，它可以包含多个相关的对象，并表达一个对多的关系。

`IsarLinks<T>`继承了`Set<T>`并暴露了所有允许用于Set的方法。

`IsarLinks`的行为与`IsarLink`很相似，也是惰性的。要加载所有链接对象，请调用`linkProperty.load()`。要保存变化，请调用`linkProperty.save()`。

在内部实现时，`IsarLink`和`IsarLinks`都是以相同的方式表示的。我们可以将之前的`IsarLink<Teacher>`升级为`IsarLinks<Teacher>`，以便为一个学生分配多个教师（不会丢失数据）。

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teacher = IsarLinks<Teacher>();
}
```

这样做是因为我们没有改变链接的名称（`teacher`），所以Isar记得之前的链接。

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

我听到你问，"如果我们想表达反向关系怎么办？"。别担心，我们现在将介绍反向链接。

反向链接是反方向的链接。每个链接总是有一个隐含的反向链接。你可以在你的应用程序中通过`@Backlink()`注解来配合`IsarLink`或`IsarLinks`。

反向链接不需要额外的内存或资源；你可以自由添加、删除和重命名它们而不丢失数据。

我们想知道一个特定的老师有哪些学生，所以我们定义一个反向链接：

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

我们需要指定反向链接所指向的链接。两个对象之间有可能有多个不同的链接。

## 初始化链接

`IsarLink`和`IsarLinks`的构造函数没有参数，应该在创建对象时用来指定链接字段。使链接属性成为`final`是一个好的做法。

当你第一次`put()`你的对象时，链接被初始化为源和目标集合，你可以调用`load()`和`save()`等方法。链接在创建后立即开始跟踪变化，所以你甚至可以在链接初始化前添加和删除关系。

:::danger
将一个链接移动到另一个对象是非法的。
:::
