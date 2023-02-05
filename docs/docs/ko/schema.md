---
title: 스키마
---

# 스키마

앱의 데이터를 저장하기 위해 Isar를 사용할 때마다, 컬렉션을 이용하게 됩니다. 컬렉션은 연관된 Isar 데이터베이스의 데이터베이스 테이블과 같고, 하나의 다트 객체 타입만을 포함할 수 있습니다. 각 컬렉션 객체는 해당 컬렉션의 데이터 행을 나타냅니다.

컬렉션의 정의를 "스키마" 라고 합니다. Isar Generator 가 힘든 일을 대신 해주고, 컬렉션을 사용하기 위해 필요한 대부분의 코드를 생성해줍니다.

## 컬렉션의 구조

클래스에 `@collection` 또는 `@Collection()` 어노테이션을 붙여서 Isar 컬렉션을 정의합니다. 필드들을 포함하는 하나의 Isar 컬렉션은 데이터베이스의 해당하는 테이블에 있는 각각의 열과 같으며, 여기에는 기본 키를 구성하는 하나의 필드도 포함됩니다.

아래 코드는 `User` 테이블을 정의하는 하나의 컬렉션 예시를 보여줍니다. 테이블에는 ID, 성, 이름에 해당하는 열이 포합됩니다.

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
필드를 저장하기 위해서 Isar 가 반드시 필드에 접근해야 합니다. 필드를 public 으로 만들거나 게터와 세터를 제공해서 Isar가 접근할 수 있도록 만들어야 됩니다.
:::

컬렉션을 커스터마이징할 수 있는 몇 가지 선택적인 매개변수들이 있습니다.

| Config        | Description                                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Isar 에 부모 클래스들과 믹스인에 있는 필드를 저장할 지를 조정합니다. 기본적으로 활성화되어 있습니다. |
| `accessor`    | 기본 컬렉션 접근자의 이름을 바꿀 수 있게 해줍니다. (예: `Contact` 컬렉션에 사용되는 `isar.contacts`) |
| `ignore`      | 특정 속성을 제외할 수 있습니다. 이것은 상위 클래스에도 동일하게 적용될 수 있습니다. |

### Isar 의 Id

각 컬렉션 클래스는 객체를 고유하게 식별하는 `Id` 타입으로 id 속성을 정의해야 합니다.
`Id` 는 Isar Generator 가 id 속성을 인식할 수 있도록 하는 int 의 별칭일 뿐입니다.

Isar 는 id 필드를 자동으로 인덱싱합니다. id 를 기반으로 객체를 효율적으로 가져오고 수정할 수 있습니다.

사용자가 직접 id를 설정하거나 Isar 에 자동 증분 id를 할당하도록 요청할 수 있습니다. 만약 `id` 필드가 `null` 이고 `final` 이 아니라면 Isar 는 자동 증분 id 를 할당합니다. null 이 아닌 자동 증분 id를 원하는 경우에는 `Isar.autoincrement` 를 사용할 수 있습니다.

::tip
자동 증분 아이디들은 해당 객체가 삭제되어도 다시 사용할 수 없습니다. 자동 증분 id를 초기화하는 유일할 방법은 데이터베이스를 지우는 것 뿐입니다.
:::

### 컬렉션과 필드의 이름 바꾸기

기본적으로 Isar는 클래스 이름을 컬렉션 이름으로 사용합니다. 마찬가지로 Isar는 필드 이름을 데이터베이스 열 이름으로 사용합니다. 컬렉션이나 필드에 다른 이름을 붙이고 싶다면 `@Name` 어노테이션을 추가합니다. 다음 코드는 컬렉션과 필드의 이름을 바꾸는 예입니다:

```dart
@collection
@Name("User")
class MyUserClass1 {

  @Name("id")
  Id myObjectId;

  @Name("firstName")
  String theFirstName;

  @Name("lastName")
  String familyNameOrWhatever;
}
```

특히, 이미 데이터베이스에 저장되어 있는 Dart 의 필드나 클래스의 이름을 변경하고 싶다면, `@Name` 어노테이션의 사용을 검토해야 합니다. 그렇지 않으면 데이터베이스가 해당 필드나 컬렉션을 삭제하거나 재작성하게 될 수 있습니다.

### 필드 무시하기

Isar 는 컬렉션 클래스의 모든 public 필드를 저장합니다. 속성이나 게터에 `@ignore` 어노테이션을 붙여서 저장하지 않을 수 있습니다. 다음 코드 조각을 보세요.

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;

  @ignore
  String? password;
}
```

컬렉션이 부모 컬렉션에서 필드를 상속하는 경우 일반적으로 `@Collection` 어노테이션의 ignore 속성을 사용하는 것이 더 쉽습니다.

```dart
@collection
class User {
  Image? profilePicture;
}

@Collection(ignore: {'profilePicture'})
class Member extends User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

만약 컬렉션에 Isar가 지원하지 않는 유형의 필드가 포함되어 있다면 해당 필드는 무시해야 합니다.

:::warning
저장되지 않은 Isar 객체에 정보를 저장하는 것은 좋지 않습니다.
:::

## 지원하는 타입 목록

Isar 는 아래의 데이터 타입들을 지원합니다:

- `bool`
- `byte`
- `short`
- `int`
- `float`
- `double`
- `DateTime`
- `String`
- `List<bool>`
- `List<byte>`
- `List<short>`
- `List<int>`
- `List<float>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

추가적으로 임베드된 객체와 enum 도 지원합니다. 이것들은 아래에서 다룰 것입니다.

## byte, short, float

대부분의 경우 64비트 정수형이나 double 의 전체 범위는 필요하지 않습니다. Isar는 더 작은 수치를 저장할 때를 위해서 용량과 메모리를 절약할 수 있는 추가 유형을 지원합니다.

| Type       | Size in bytes | Range                                                   |
| ---------- | ------------- | ------------------------------------------------------- |
| **byte**   | 1             | 0 to 255                                                |
| **short**  | 4             | -2,147,483,647 to 2,147,483,647                         |
| **int**    | 8             | -9,223,372,036,854,775,807 to 9,223,372,036,854,775,807 |
| **float**  | 4             | -3.4e38 to 3.4e38                                       |
| **double** | 8             | -1.7e308 to 1.7e308                                     |

추가적인 숫자 타입들은 native 다트 타입들의 별칭일 뿐입니다. 예를 들어 `short` 를 사용해도 `int` 를 사용하는 것과 같이 동작합니다.

아래에 위의 모든 유형을 포함하는 컬렉션의 예를 보여줍니다.

```dart
@collection
class TestCollection {
  Id? id;

  late byte byteValue;

  short? shortValue;

  int? intValue;

  float? floatValue;

  double? doubleValue;
}
```

모든 숫자 유형은 리스트로 사용할 수도 있습니다. 바이트들을 저장하려면 `List<byte>` 를 사용해야 합니다.

## 널이 허용되는 타입들

Isar 에서 nullability(DB 테이블의 열 항목이 NULL 값을 가질 수 있는지 없는지)가 어떻게 작동하는지 이해하는 것은 필수입니다. 숫자 타입들은 `null` 이라는 값을 별도로 가지지 **않습니다**. 대신, 특수한 값이 사용됩니다.

| Type       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN`  |
| **double** |  `double.NaN` |

`bool`, `String`, `List` 는 별도의 `null` 표현을 사용합니다.

이런 동작을 통해서 성능이 향상되고, `null` 값을 처리하기 위한 마이그레이션이나 특별한 코드 없이도 필드의 nullability 를 자유롭게 변경할 수 있게 됩니다.

:::warning
`byte` 타입은 널 값을 지원하지 않습니다.
:::

## DateTime

Isar 는 날짜의 표준 시간대 정보를 저장하지 않습니다. 대신 `DateTime`을 UTC로 변환해서 저장합니다. Isar 는 모든 날짜를 현지 시간으로 반환합니다.

`DateTime`은 마이크로초 단위로 저장됩니다. 브라우저에서는 자바스크립트의 제한 때문에 밀리초 단위의 정밀도만 지원됩니다.

## Enum

Isar는 다른 Isar 타입들 처럼 열거형을 저장하고 사용할 수 있습니다. 하지만 Isar가 디스크의 열거형을 어떻게 나타낼지 선택해야 합니다. Isar 는 4가지의 전략을 지원합니다.

| EnumType    | Description                                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------- |
| `ordinal` | 열거형의 인덱스는 `byte` 로 저장됩니다. 이것은 매우 효율적이지만 널이 가능한 열거형에서는 허용하지 않습니다 |
| `ordinal32` | 열거형의 인덱스는 `short`(4바이트 정수)로 저장됩니다. |
| `name` | 열거형 이름은 `String` 으로 저장됩니다. |
| `value` | 사용자 지정 속성을 사용하여 열거형을 검색합니다 |

:::warning
`ordinal`과 `ordinal32` 는 열거값의 순서에 따라 달라집니다. 순서를 변경하는 경우, 기존 데이터베이스는 잘못된 값을 반환합니다.
:::

각각의 전략을 사용하는 예시를 확인하세요.

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // EnumType.ordinal 과 같습니다.
  late TestEnum byteIndex; // 널이 될 수 없습니다.

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // 널이 될 수 없습니다.

  @Enumerated(EnumType.ordinal32)
  TestEnum? shortIndex;

  @Enumerated(EnumType.name)
  TestEnum? name;

  @Enumerated(EnumType.value, 'myValue')
  TestEnum? myValue;
}

enum TestEnum {
  first(10),
  second(100),
  third(1000);

  const TestEnum(this.myValue);

  final short myValue;
}
```

물론 열거형을 리스트에서 사용해도 됩니다.

## 임베드된 객체

컬렉션 모델에 중첩된 객체가 있는 것이 도움이 되는 경우가 많습니다. 객체를 중첩할 수 있는 깊이에는 제한이 없습니다. 그러나 깊이 중첩된 객체를 업데이트하려면 전체 객체 트리를 데이터베이스에 기록해야 합니다.

```dart
@collection
class Email {
  Id? id;

  String? title;

  Recepient? recipient;
}

@embedded
class Recepient {
  String? name;

  String? address;
}
```

임베드된 객체는 null로 사용할 수 없으며 다른 객체를 확장할 수 있습니다. 유일한 요구 사항은 `@embedded` 어노테이션을 추가하고 필수 매개 변수가 없는 기본 생성자를 갖는 것입니다.