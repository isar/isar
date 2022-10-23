---
title: 模式（Schema）
---

# 模式（Schema）

当你使用Isar来存储你的应用程序数据时，你需要和集合打交道。一个集合（collection）就像数据库中的一个数据表，并且它只能包含一种类型的Dart对象。每个集合对象（collection object）代表相应集合中的一行数据。

一个集合的定义被称为“模式”。生成你使用集合所需的大部分代码这一类繁琐的工作将由Isar Generator为你完成。

## 剖析集合

你可以使用`@collection`或`@Collection()`注解一个类来定义Isar集合。一个Isar集合包括数据库中对应表的每一列的字段，其中也包含主键字段。

下面的代码是一个简单的集合的例子，它定义了一个包含了ID、名字和姓氏等列的`用户'表：

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
要想持久化一个字段，Isar必须有对它的访问权。你可以将访问权限设置为public或提供getter和setter方法来确保Isar能够访问一个字段。
:::

以下是一些可以用来定制集合的参数：

| 配置项          | 描述                                              |
|--------------|-------------------------------------------------|
| `inheritance` | 控制父类和混合类（mixins）的字段是否会被存储在Isar中。默认情况下是启用的。      |
| `accessor`   | 允许你重命名默认的集合访问器（例如`isar.contacts`用于`Contact`集合）。 |
| `ignore`     | 允许忽略某些字段。该配置对父类也生效。                             |

### Isar Id

每个集合类都必须定义一个类型为`Id`的id字段，用来唯一地识别一个对象。`Id`类型只是`int`类型的一个别名，方便Isar Generator来识别id字段。

Isar会自动为id字段建立索引，这使得你可以高效地通过id读取和修改对象。

你可以自己设置id值，或者让Isar分配一个自增id。如果`id`字段等于`null`并且不是`final`，Isar将分配一个自增id。如果你想要一个不可为null的自增id，你可以使用`Isar.autoIncrement`代替`null`。

:::tip
当一个对象被删除时，自增ID不会被复用。重置自增ID的唯一方法是清除整个数据库。
:::

### 集合和字段重命名

默认情况下，Isar使用类名作为集合的名称。同样地，Isar使用字段名作为数据库中的列名。如果你想让集合或字段有一个不同的名字，则需要添加`@Name`注解。下面的例子演示了集合和字段的自定义名称：

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

特别是如果你的数据库中已经存在这些需要重命名的字段，你应该考虑使用`@Name`注解。否则数据库将删除并重新创建该字段或集合。

### 忽略字段

Isar持久化了一个集合类的所有公共字段。通过在一个字段或getter上添加`@ignore`注解，你可以把它排除在持久化字段之外，正如以下代码片段所示：

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

在集合从父集合继承字段的情况下，通常我们会使用`@Collection`注解的`ignore`参数：

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

如果集合内字段的类型是Isar不支持的，你必须忽略这个字段。

:::warning
请记住，在没有持久化的Isar对象中存储信息是不好的实践。
:::

## 支持的类型

Isar支持以下数据类型：

- `bool`
- `int`
- `double`
- `DateTime`
- `String`
- `List<bool>`
- `List<int>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

此外，Isar还支持嵌套对象（embedded objects）和枚举（enum）。我们将在下文介绍这些内容：

## byte, short, float

在多数场景下，你不需要64位整数或浮点数的全部数值范围。对此Isar支持额外的类型，允许你在存储较小的数字时节省空间和内存。

| 类型         | 以bytes计量的大小 | 范围                                                      |
|------------|-------------|---------------------------------------------------------|
| **byte**   | 1           | 0 to 255                                                |
| **short**  | 4           | -2,147,483,647 to 2,147,483,647                         |
| **int**    | 8           | -9,223,372,036,854,775,807 to 9,223,372,036,854,775,807 |
| **float**  | 4           | -3.4e38 to 3.4e38                                       |
| **double** | 8           | -1.7e308 to 1.7e308                                     |

这些额外的数字类型只是原生Dart类型的别名，所以就使用`short`来说，与使用`int`的效果相同。

以下是一个包含上述所有类型的例子集合：

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

所有的数字类型也可以在列表（list）中使用。例如你想要存储字节类型（bytes），那么你应该使用`List<byte>`。

## 可以为空（null）的类型

理解可空性（nullability）在Isar中的工作原理是至关重要的。数字类型**没有**专门的"空值"表示。相反，会使用一个特定的值代替：

| Type       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` | 
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN` |
| **double** |  `double.NaN` |

`bool`、`String`和`List`有单独的`null`表示.

这种行为可以提高性能，同时它允许你自由地改变字段的可空性，而不需要通过迁移或用特殊代码来处理空值。

:::warning
`byte`类型不支持空值。
:::

## 日期和时间

Isar不存储日期的时区信息。相反，它在存储之前会将`DateTime`表示的时间转换为UTC时间。Isar将以本地（local）时间返回所有日期数据。

`DateTime`的存储精度是微秒（microsecond）。由于JavaScript的限制，在浏览器中只支持毫秒级的精度。

## 枚举

Isar允许像其它Isar类型一样存储和使用枚举（enum）。然而，你必须选择Isar应该如何在磁盘里存储枚举数据。Isar支持四种不同的策略：

| 枚举类型（EnumType) | 描述                                                    |
|----------------|-------------------------------------------------------|
| `ordinal`      | 枚举的索引被存储为`byte`（字节）类型。这种方式非常高效，但不允许出现可空（nullable）的枚举。 |
| `ordinal32`    | 枚举的索引被存储为`short`（4字节整数）。                              |
| `name`         | 枚举名称以`String`（字符串）形式存储。                               |
| `value`        | 一个自定义字段被用来获取枚举值。                                      |

:::warning
`ordinal`和`ordinal32`依赖枚举值的顺序。如果你改变顺序，现有的数据库将返回不正确的值。
:::

让我们看看每种策略的例子。

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // same as EnumType.ordinal
  late TestEnum byteIndex; // cannot be nullable

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // cannot be nullable

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

当然，枚举也可以在列表中使用。

## 嵌套对象

能够在你的集合模型中使用嵌套对象（embedded objects）往往是有用的。对于对象嵌套深度，没有任何限制。然而，请记住，更新一个深度嵌套的对象将需要把整个对象树写入数据库。

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

嵌套对象可以是空值（nullable），并且可以继承其它对象。唯一的要求是，要给它们添加`@embedded`注解，并且它们需要有一个默认的构造函数，该构造函数的参数都需要是可选的（非required）。
