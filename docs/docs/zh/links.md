---
title: 关联
---

# 关联（Link）

关联允许你表达对象之间的关系，比如评论的作者（即用户）。你可以使用 Isar 的关联来实现 `1:1`、`1:n` 和 `n:n` 的关系。使用关联比使用嵌套对象更不符人类工程学，因此你应该尽可能使用嵌套对象来代替关联。

你可以将关联理解为包含关系的一张数据表。它和 SQL 的关系很接近，但有一些不同的功能设定和 API。

## IsarLink

`IsarLink<T>` 可以包含最多一个被关联对象，它经常被用于表达对一的关系。 `IsarLink` 有一个叫做 `value` 的属性，它负责存放被关联对象。

关联是懒加载的，因此你需要显式告诉 `IsarLink` 加载并保存 `value` 的值。你可以分别调用 `linkProperty.load()` 和 `linkProperty.save()` 方法。

:::tip
关联和被关联 Collection 的 Id 不应该为 final。
:::

对于 Web 端，当你第一次使用一个 Collection 时，它所含的关联会被自动加载。让我们先从添加一个 IsarLink 开始学习：

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

我们在教师和学生之间定义了一个关联。在例子中，每一个学生对应每一个教师。

首先，我们创建一位数学教师，然后将 TA 分配给一个叫 Linda 的学生。我们需要使用 `.put()` 方法并手动保存关联。

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

现在我们可以使用关联：

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

让我们用同步方法复现一次。我们不需要手动保存关联，因为 `.putSync()` 方法自动会存储所有关联，它甚至帮我们写入了被关联教师的数据。

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

在上述例子中，一个学生对应多个教师才更符合实际情况。幸运的是，Isar 也有 `IsarLinks<T>` 来实现对多的关系。

`IsarLinks<T>` 自 `Set<T>` 扩展而来，因此也可使用其相关的方法。

`IsarLinks` 和 `IsarLink` 一样也是懒加载。你可以通过调用 `linkProperty.load()` 来加载所有相关联对象，调用`linkProperty.save()` 来保存。

`IsarLink` 和 `IsarLinks` 的内部实现逻辑是一样的。我们可以将上述例子中的 `IsarLink<Teacher>` 改为 `IsarLinks<Teacher>`，将多个教师数据分配给单个学生（数据不会丢失）。

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

可以这么做的原因是我们没有修改关联的名称（`teacher`），所以 Isar 直接使用了之前的数据。

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

## 反向关联

我知道你可能会问要表达反向关系该怎么做。无需担心，现在我们来介绍反向关联。

反向关联字面意义上很好理解，就是相反方向的关联。每个关联总是对应一个隐式的反向关联。为了使用它们，你可以给 `IsarLink` 或 `IsarLinks` 添加 `@Backlink()` 的注解。

反向关联不需要额外的内存或计算资源；所以你可以自由地添加、删除或者给它们改名，而无需担心数据丢失。

如果我们想要知道某一位教师所教的是哪些学生，就可以这么定义反向关联：

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

我们需要给反向关联指定指向的关联。两个对象之间可以拥有多个不同关联。

## 初始化关联

`IsarLink` 和 `IsarLinks` 都有一个无参构造器，用于在对象被创建时分配关联属性。将关联属性声明为 `final` 是正确的做法。

当你第一次使用 `put()` 方法来创建对象时，关联就会被初始化，然后你可以调用 `load()` 和 `save()` 方法。关联在被创建之后就会立即开始记录它所关联属性的数据变化，所以你甚至可以在创建它之前就可以添加或删除对象之间的关系。

:::danger
将关联移到另一个对象是不符合规范的。
:::
