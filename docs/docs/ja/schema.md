---
title: スキーマとは
---

# スキーマとは

Isar を使用してアプリのデータを保存する場合、コレクションを扱うことになります。コレクションとは、関連付けられた IsarDB 内のテーブルのようなもので、単一型の Dart オブジェクトのみを格納することができます。それぞれのコレクションオブジェクトは、対応するコレクションの行を表します。

コレクション定義は "スキーマ"と呼ばれます。Isar Generator は貴方のために手間のかかる面倒な作業を行い、コレクションを使用するのに必要なコードの大部分を生成してくれます。

## コレクションの構造

Isar コレクションを定義するには、Class を `@collection` または `@Collection()` でアノテートします。 Isar コレクションは対応するテーブル内の各列となるフィールドを含みます。ここには、主キーを構成するフィールドも含めてください。

次のコードは、ID、名前、苗字の列を持つ `User` テーブルを定義するシンプルなコレクションの例です。

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
フィールドを永続化するためには、Isar がそのフィールドにアクセスできる必要があります。フィールドを public にしたり、Getter や Setter のメソッドを用意したりすることで、Isar がフィールドにアクセスできるようになります。
:::

コレクションをカスタマイズするために、いくつかの任意のパラメータがあります：

| Config        | Description                                                                                                                         |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `inheritance` | 親クラスや mixins のフィールドを Isar に保存するかどうかを管理します。デフォルトでは有効です。                                      |
| `accessor`    | デフォルトのコレクションアクセサの名前を変更できるようにします。 (たとえば、`Contact` コレクションには `isar.contacts` を指定など). |
| `ignore`      | 特定のプロパティを無視(除外)することができます。これらは、スーパークラスに対しても同様に適用されます。                              |

### Isar の Id

各コレクションクラスは、オブジェクトを一意に識別する `Id` 型の id プロパティを定義する必要があります。`Id` は `int` の別名(エイリアス)で、IsarGenerator が id プロパティを識別できるようにするためのものです。

Isar は自動的に id フィールドにインデックスを作成するので、id に基づいて効率的にオブジェクトを取得したり変更したりすることができます。

id は自分で設定することもできますし、Isar にオートインクリメントの id を割り当ててもらうこともできます。もし`id` フィールドが `null` かつ `final` でない場合、Isar はオートインクリメントの id を割り当てます。NULL でないオートインクリメントの id が欲しい場合は、 `null` の代わりに `Isar.autoIncrement` を使用することができます。

:::tip
オブジェクトが削除された場合、オートインクリメント ID は再利用されません。オートインクリメント ID をリセットする唯一の方法は、データベースを削除(Clear)することです。
:::

### コレクションとフィールドの名前変更

デフォルトでは、Isar はクラス名をコレクション名として使用します。同様に、Isar はフィールド名をデータベースの列名として使用します。コレクションやフィールドに別の名前を付けたい場合は、 `@Name` アノテーションを追加します。次の例は、コレクションとフィールドの名前をカスタマイズする例です:

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

特に、既にデータベースに保存されている Dart のフィールドやクラスの名前を変更したい場合は、 `@Name` アノテーションの使用を検討する必要があります。そうしないと、データベースがそのフィールドやコレクションを削除したり、再作成したりすることになりかねません。

### フィールドを無視する

Isar は、コレクションクラスのすべての public フィールドを永続化します。プロパティや Getter に `@ignore` というアノテーションを付けると、次のコードスニペットのように永続化から除外することができます:

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

コレクションが親コレクションからフィールドを継承しているような場合は、通常、 `@Collection` アノテーションの `ignore` プロパティを使用する方が簡単です:

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

もし、コレクションに Isar がサポートしていない型のフィールドが含まれている場合、そのフィールドは無視しなければなりません。

:::warning
永続化されていない Isar オブジェクトに情報を保存することは、良い習慣ではないことに留意してください。
:::

## 対応している型

Isar は以下のデータ型に対応しています:

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

加えて、埋め込み型オブジェクトと列挙型(Enum)もサポートされています。それらについては後述します。

## byte, short, float

多くの場合、64 ビット整数型や double の全範囲は必要ありませんよね。Isar は、より小さな数値を保存する際の為に、容量とメモリを節約することができる追加の型をサポートしています。

| Type       | Size in bytes | Range                                                   |
| ---------- | ------------- | ------------------------------------------------------- |
| **byte**   | 1             | 0 to 255                                                |
| **short**  | 4             | -2,147,483,647 to 2,147,483,647                         |
| **int**    | 8             | -9,223,372,036,854,775,807 to 9,223,372,036,854,775,807 |
| **float**  | 4             | -3.4e38 to 3.4e38                                       |
| **double** | 8             | -1.7e308 to 1.7e308                                     |

追加の数値型は Dart のネイティブ型の別名(エイリアス)に過ぎません。例えば `short` を使用すると、 `int` を使用するのと同じように動作します。

以下に、上記のすべての型を含むコレクションの例を示します：

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

すべての数値型は List でも使用することができます。バイトを格納する場合は、`List<byte>` を使用してください。

## Null 許容型

Isar で nullability(訳注：DB 関連用語では、列などの項目が NULL 値を受け入れる能力)がどのように機能するかを理解するのは非常に重要です：

数値型は、専用の `null` 表現を持ちません。その代わりに、特定の値が使用されます:

| Type       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN`  |
| **double** |  `double.NaN` |

`bool`, `String`, `List` は、それぞれ別の `null` 表現を持ちます。

この動作によってパフォーマンスが向上し、 `null` 値を処理するためのマイグレーションや特別なコードを必要とせずに、フィールドの nullability を自由に変更することができるようになります。

:::warning
`byte` 型は null 値をサポートしていません。
:::

## DateTime

Isar は、日付のタイムゾーン情報を保存しません。その代わり、`DateTime`を UTC に変換してから保存します。Isar はすべての日付をローカルタイムで返します。

`DateTime`はマイクロ秒の精度で保存されます。ただしブラウザ上においては、JavaScript の制限により、ミリ秒の精度しかサポートされていません。

## 列挙型(Enum)

Isar では他の型と同様に、列挙型を保存し使用することができます。しかし、Isar がディスク上でどのように enum を表すかを選択する必要があります。Isar は 4 つの異なる方法をサポートしています。:

| EnumType    | Description                                                                                                           |
| ----------- | --------------------------------------------------------------------------------------------------------------------- |
| `ordinal`   | 列挙型のインデックスは `byte` として格納されます。これは非常に効率的ですが、null 値を許容する enum は使用できません。 |
| `ordinal32` | 列挙型のインデックスは `short` (4 バイトの整数) として格納されます。                                                  |
| `name`      | 列挙名称は `String` として格納されます。                                                                              |
| `value`     | 列挙値の取得には、カスタムプロパティを使用します。                                                                    |

:::warning
`ordinal` と `ordinal32` は、列挙された値の順番に依存します。この順序を変更すると、既存のデータベースは不正な値を返す可能性があります。
:::

それでは、それぞれの方法の例を確認してみましょう。

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // EnumType.ordinalと同様
  late TestEnum byteIndex; // null 許容には出来ない

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // null 許容には出来ない

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

もちろん、Enum は List 内でも使用可能です。

## 組み込みオブジェクト

コレクションモデルでオブジェクトをネストさせると便利なことがよくあります。オブジェクトをネストさせる深さは無制限です。しかし、深くネストされたオブジェクトを更新するには、オブジェクトツリー全体をデータベースに書き込む必要があることを覚えておいてください。

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

埋め込みオブジェクトは null を許容する事も出来ますし、他のオブジェクトを拡張(extend)することも出来ます。唯一の要件は `@embedded` のアノテーションを付け、required パラメータの無いデフォルトのコンストラクタを持つことです。
