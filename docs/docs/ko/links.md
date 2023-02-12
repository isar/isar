---
title: 링크
---

# 링크

링크를 사용해서 댓글 작성자(사용자) 같은 객체 간의 관계를 나타낼 수 있습니다. Isar 링크를 사용해서 `1:1`, `1:n`, 과 `n:n` 관계를 모델링할 수 있습니다. 링크를 사용하는 것은 내장된 객체를 사용하는 것보다 인체 공학적이지 않으므로(less ergonomic), 가능하다면 임베드된 객체를 사용해야 합니다.

링크를 관계를 포함하는 별도의 테이블로 간주합니다. SQL 관계와 비슷하지만 사용가능한 기능과 API 가 다릅니다.

## IsarLink

`IsarLink<T>` 는 관련 객체를 포함하지 않거나 하나만 포함할 수 있으며 일대일 관계를 표현하는데 사용할 수 있습니다. `IsarLink` 에는 연결된 객체를 가지는 `value` 라는 단일 속성이 있습니다.

링크는 게으르므로 `IsarLink` 에 `value` 를 명시적으로 로드하거나 저장하도록 지시해야 합니다. `linkProperty.load()` 및 `linkProperty.save()` 를 호출하여 이 작업을 수행할 수 있습니다.

:::tip
링크의 원본 및 대상 컬렉션의 ID 타입은 final 이 아니어야 합니다.
:::

웹이 아닌 타겟에서는, 링크를 처음 사용할 때 링크가 자동 로드 됩니다. 먼저 IsarLink 를 컬렉션에 추가합니다:

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

우리는 선생님과 학생들 사이의 링크를 정의했습니다. 이 예에서 모든 학생은 정확히 한 명의 선생님만 가질 수 있습니다.

먼, 우리는 선생님을 만들어 학생에게 할당합니다. 우리는 선생님을 `.put()` 하고 링크를 수동으로 저장해야 합니다.

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

우리는 이제 링크를 이용할 수 있습니다:

```dart
final linda = await isar.students.where().nameEqualTo('Linda').findFirst();

final teacher = linda.teacher.value; // > Teacher(subject: 'Math')
```

동기 코드로 똑같이 해보겠습니다. `.putSync()` 는 모든 링크를 자동으로 저장하므로 수동으로 링크를 저장할 필요가 없습니다. 심지어 우리를 위해서 선생님을 만듭니다.

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

이전 예시의 학생이 여러 명의 선생님을 가질 수 있다면 더 그럴듯할 것입니다. 다행히 Isar는 `IsarLinks<T>` 를 가지고 있습니다. 여러 개의 관련 객체를 포함할 수 있으며 -N 관계(1:N, N:N)를 표현할 수 있습니다.

`IsarLinks<T>` 는 `Set<T>` 을 확장하고, set에서 사용하는 모든 메서드들을 사용할 수 있습니다.

`IsarLinks` 는 `IsarLink` 와 비슷한 행동을 하고 lazy 합니다. 연결된 모든 객체를 로드하려면 `linkProperty.load()`를 호출하세요. 변경 내용을 유지하려면, `linkProperty.save()` 를 호출하세요.

내부적으로 `IsarLink` 와 `IsarLinks` 는 동일한 방식으로 표현됩니다. 우리는 이전 예제의 `IsarLink<Teacher>` 를 `IsarLinks<Teacher>` 로 업그레이드 해서 한 학생에 여러 선생님들을 할당할 수 있습니다.

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teacher = IsarLinks<Teacher>();
}
```

우리가 링크(`teacher`)의 이름을 바꾸지 않았기 때문에 Isar 는 이전의 것들을 기억하고 있습니다.

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

## 백링크 (Backlinks)

이렇게 물을 수 있습니다. "만약 역관계를 표현하려면 어떻게 해야 하나요?". 걱정마세요; 백링크가 있습니다.

백링크는 역방향 링크입니다. 각 링크들은 항상 암시적인 백링크를 가지고 있습니다. `IsarLink`, `IsarLinks` 에 `@BackLink()` 어노테이션을 써서 만들 수 있습니다.

백링크는 추가적인 메모리나 자원을 필요로 하지 않습니다; 항상 데이터 손실 없이 자유롭게 추가하고 삭제하고 이름을 바꿀 수 있습니다.

우리는 특정한 선생님이 어떤 학생을 가지고 있는지를 알고 싶습니다, 그래서 백링크를 정의합니다:

```dart
@collection
class Teacher {
  Id id;

  late String subject;

  @Backlink(to: 'teacher')
  final student = IsarLinks<Student>();
}
```

우리는 백링크가 어느 링크를 가르키는지를 지정해야 합니다. 두 개의 객체 간에도 여러 링크가 있을 수 있습니다.

## 링크들을 초기화하기

`IsarLink` 와 `IsarLinks` 는 매개변수가 없는 생성자를 가지고, 객체가 만들어 질 때 링크 속성을 할당해야 합니다. 링크 속성을 `final` 로 만드는 것이 좋은 습관입니다.

객체를 처음으로 `put()` 할 때, 링크는 소스 컬렉션과 대상 컬렉션으로 초기화 됩니다. 그 이후, `load()` 와 `save()` 같은 메서드를 호출할 수 있습니다. 링크가 생성된 후 바로 변경 사항을 추적하기 시작하므로 링크가 초기화 되기 전에도 관계를 추가하거나 제거할 수 있습니다.

:::danger
링크를 또 다른 개체로 옮기는 것은 금지되어 있습니다.
:::
