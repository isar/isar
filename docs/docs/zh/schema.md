---
title: Schema
---

# Schema

当你使用 Isar 来存储数据时，你需要对 Collection 进行操作。Collection 可理解为 Isar 数据库中的表，其包含的数据只能为同一类 Dart 对象。每个对象则代表了对应数据表中的一行数据。

对 Collection 的定义就被称为 “Schema”。 Isar Generator 会根据 Schema 自动生成大部分代码，然后你可以通过这些代码来对 Collection 进行相关操作。

## Collection 的构造

你可以通过给每一个类添加 `@collection` 或 `@Collection()` 的注解来定义一个 Collection。 一个 Collection 所包含的字段对应数据库中的每一列，其中包括一个主 key。

如下代码所示，`User` Collection 表示一张用户数据表，其列名分别为 id、firsName 以及 lastName：

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
为了保存一个字段，Isar 必须能够读取到它。你可以声明其为公开字段，或者为其提供 getter 或 setter 方法，来确保 Isar 能够读取到它。
:::

在定义 Collection 的时候，若干配置参数可供选择：

| 参数          | 描述                                                                                                                   |
| ------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `inheritance` | 确定 Isar 是否保存父类的字段或 mixin。默认情况为启用。                                                                 |
| `accessor`    | 允许你更改默认的 Collection 的访问名。例如，默认设置下自动生成的代码会用 `isar.contacts` 来访问 `Contact` Collection。 |
| `ignore`      | 允许忽视特定字段。 这同样也适用于超类。                                                                                |

### Isar Id

每一个 Collection 类都必须定义一个 `Id` 类型的 Id 属性，以便唯一指代一个对象。 实际上，`Id` 类型在这里只是 `int` 类型的别名，只不过是为了让 Isar Generator 能够识别该属性。

Isar 将会自动索引 Id 属性，这能够让你轻松高效地通过对象的 Id 来查询或修改它。

你可以选择要么自己设置 Id，要么让 Isar 自行分配一个自增的 Id。但是如果你设置的 `id` 字段为 `null` 或者不是 `final`，Isar 也会自动覆盖成自增的 Id。倘若你想要一个非空自增的 Id，那么你可以给它赋值为 `Isar.autoIncrement`，而不是 `null`。

:::tip
当对象被删除后，其自增的 Id 也不会被重新使用。唯一重置 Id 的方法是删除整个数据库。
:::

### 给 Collection 和其字段改名

默认情况下，Isar 会使用类的名称作为 Collection 的名称。相似地，Isar 也会用字段名称来作为数据表的列名。倘若你想要修改 Collection 或字段的名称，在对应位置添加 `@Name` 注解。可参考下方例子：

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

尤其是当你想要修改已经存入数据库中对象的字段名称时，你可以考虑使用 `@Name`（例如，现有数据字段命名带有下划线，而在 Dart 中定义时则为小写驼峰式，如此情况下可以通过修改名称来匹配）。否则的话， 因为名称不匹配，导致原有的数据未被保存，而不同名的字段则额外被添加到数据库里。

### 忽略字段

Isar 会保存 Collection 类中所有的公开属性。如下例子所示，给一个属性或 getter 添加 `@ignore` 注解，就可以防止其被 Isar 保存：

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

当 Collection 类从父类继承了一些你不想保存的字段时，通常直接在 `@Collection` 注解里设置 `ignore` 更为便利：

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

如果一个 Collection 包含 Isar 不支持的数据类型的字段时，你必须忽略掉对应字段。

:::warning
记住，在那些未被 Isar 保存的字段里存储信息不是正确的做法。
:::

## Isar 支持的数据类型

Isar 支持以下数据类型：

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

还有，嵌套的对象和枚举也是支持的。我们等会会讲到它们。

## byte，short，float

对于大多数应用场景，你不会需要整个 64 位范围的整数或双精度浮点数。Isar 支持以下额外的数据类型，它们可以用于较小范围的数字，这样也帮助你节省了存储空间和内存使用。

| 类型       | 字节大小 | 数字范围                                                |
| ---------- | -------- | ------------------------------------------------------- |
| **byte**   | 1        | 0 到 255                                                |
| **short**  | 4        | -2,147,483,647 到 2,147,483,647                         |
| **int**    | 8        | -9,223,372,036,854,775,807 到 9,223,372,036,854,775,807 |
| **float**  | 4        | -3.4e38 到 3.4e38                                       |
| **double** | 8        | -1.7e308 到 1.7e308                                     |

表中的数字类型只是原生 Dart 数据类型的别名。所以例如 `short` 实际上和 `int` 用法一样，只不过限定了它的数字范围。

参考下方例子：

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

所有的数字类型也可以用于数组 List。比如你可以用 `List<byte>` 来保存 byte。

## 可空类型

理解 Isar 中的可空性原理是最基本的：数字类型**并没有**对于 `null` 的专门表达。相反，Isar 用特定的值来表示空：

| 类型       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN`  |
| **double** |  `double.NaN` |

`bool`、`String` 和 `List` 则有对 `null` 的表达。

这样的处理方式能够带来性能上的提高，能够让你自由更改字段的可空性，而不需要额外的数据迁移或多余代码来处理空值。

:::warning
`byte` 类型不支持空值。
:::

## 日期（DateTime）

Isar 不会保存日期类型数据中的时区信息。相反，它会在存储之前将 `DateTime` 数据转成 UTC 格式。 Isar 返回的日期数据都为当地时间。

`DateTime` 以微秒精度被存储，而在浏览器中，由于 JavaScript 的局限性，最高只能以毫秒精度被存储。

## 枚举（Enum）

就像其他 Isar 所支持的数据类型一样，Isar 也允许存储和使用枚举类型。然而，你可以选择 Isar 如何来表示枚举。 Isar 支持以下四种不同策略：

| 策略类型    | 描述                                                         |
| ----------- | ------------------------------------------------------------ |
| `ordinal`   | 枚举的索引以 `byte` 类型被保存。性能很高但不支持可空的枚举。 |
| `ordinal32` | 枚举的索引以 `short` (4 字节整型) 被保存。                   |
| `name`      | 枚举的名称以 `String` 被保存。                               |
| `value`     | 用一个自定义属性来读取枚举值。                               |

:::warning
`ordinal` 和 `ordinal32` 依赖于枚举值的属性。如果你改变了枚举内值的顺序，现有数据库将会返回错误的结果。
:::

让我们通过例子来了解每种策略。

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // 等价于 EnumType.ordinal
  late TestEnum byteIndex; // 不能为空值

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // 不能为空值

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

当然，枚举类型也可以被用于数组 List。

## 嵌套对象

在 Collection 中使用嵌套对象通常很有用。对象可以嵌套到任何深度。但是请记住，对一个嵌套对象进行修改需要将整个对象树写入数据库。

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

嵌套对象可为空且可以扩展自其他对象，唯一的要求是需要添加 `@embedded` 注解，而且它们的构造器不能有参数。
