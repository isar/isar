---
title: 쿼리
---

# 쿼리

쿼리는 특정 조건들에 맞는 레코드들을 찾는 방법입니다. 예:

- 별표로 표시된 모든 연락처를 찾습니다.
- 연락처에서 고유한 이름들을 찾습니다.
- 성이 정의되지 않은 모든 연락처를 삭제합니다.

쿼리는 다트가 아닌 데이터베이스에서 실행되기 때문에 매우 빠릅니다. 인덱스를 똑똑하게 사용하면 쿼리 성능을 더욱 더 향상시킬 수 있습니다. 아래에서는 쿼리를 작성하는 방법과 쿼리를 가능한 한 빨리 작성하는 방법에 대해 알아봅니다.

레코드들을 필터링하는 방법에는 2가지가 있습니다. 필터를 이용하는 방법과 where 절을 이용하는 방법입니다. 먼저 필터 사용법에 대해 알아보겠습니다.

## 필터

필터는 사용하기 쉽고 이해하기 쉽습니다. 속성들의 타입에 따라 다양한 필터 작업이 가능합니다. 필터 작업들은 대부분 알기 쉬운 이름들을 사용합니다.

필터는 필터링할 컬렉션의 모든 객체에 대한 식을 계산해서 작동합니다. 표현식이 `true` 로 결정되면 Isar 는 결과에 객체를 포함합니다. 필터는 결과 순서에 영향을 주지 않습니다.

아래에 나오는 예제들에서는 다음 모델을 사용합니다.

```dart
@collection
class Shoe {
  Id? id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### 쿼리 조건들

필드의 타입에 따라서, 다른 조건들을 사용할 수 있습니다.

| 조건                     | 설명                                                                                                                   |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `.equalTo(value)`        | 특정 `value` 와 일치하는 값들.                                                                                         |
| `.between(lower, upper)` | `lower` 와 `upper` 사이에 있는 값들.                                                                                   |
| `.greaterThan(bound)`    | `bound` 보다 큰 값들.                                                                                                  |
| `.lessThan(bound)`       | `bound` 보다 작은 값들. 기본적으로 `null` 값이 사용된다. `null` 은 모든 값들 중에 제일 작은 값으로 간주 되기 때문이다. |
| `.isNull()`              | `null` 인 값들.                                                                                                        |
| `.isNotNull()`           | `null` 이 아닌 값들.                                                                                                   |
| `.length()`              | List, String, 링크에 있는 요소의 개수를 기반으로 한 길이 쿼리 필터                                                     |

데이터베이스에 크기가 39, 40, 46, `null` 인 신발 4켤레가 있다고 가정해보자.
정렬을 따로 하지 않으면, ID별로 정렬된 값이 반환됩니다.

```dart

isar.shoes.filter()
  .sizeLessThan(40)
  .findAll() // -> [39, null]

isar.shoes.filter()
  .sizeLessThan(40, include: true)
  .findAll() // -> [39, null, 40]

isar.shoes.filter()
  .sizeBetween(39, 46, includeLower: false)
  .findAll() // -> [40, 46]

```

### 논리 연산들

논리 연산자를 이용해서 구문을 합성할 수 있습니다.

| Operator   | Description                                            |
| ---------- | ------------------------------------------------------ |
| `.and()`   | 양 쪽의 식이 모두 `true` 인 경우 `true` 로 평가됩니다. |
| `.or()`    | 한 쪽의 식이라도 `true` 인 경우 `true` 로 평가됩니다.  |
| `.xor()`   | 정확히 한 쪽의 식이 `true` 라면 `true` 로 평가됩니다.  |
| `.not()`   | 다음 식이 부정되는 결과를 가져옵니다.                  |
| `.group()` | 조건을 그룹화하고 평가 순서를 지정할 수 있습니다.      |

만약 크기가 46인 모든 신발들을 원한다면, 다음 쿼리를 사용할 수 있습니다:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

하나 이상의 조건이 필요하다면, 논리적 **and** `.and()`, 논리적 **or** `.or()`, 논리적 **xor** `.xor()` 을 이용해서 여러 필터들을 조합하세요.

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // 선택적으로, 필터들을 논리 and 연산으로 조합합니다.
  .isUnisexEqualTo(true)
  .findAll();
```

이 쿼리는 다음과 같습니다: `size == 46 && isUnisex == true`.

`group()` 으로 그룹 조건을 사용할 수도 있습니다:

```dart
final result = await isar.shoes.filter()
  .sizeBetween(43, 46)
  .and()
  .group((q) => q
    .modelNameContains('Nike')
    .or()
    .isUnisexEqualTo(false)
  )
  .findAll()
```

이 쿼리는 `size >= 43 && size <= 46 && (modelName.contains('Nike') || isUnisex == false)` 와 같습니다.

하나의 조건이나 그룹을 부정하려면, 논리적 **부정** 인 `.not()` 을 사용합니다:

```dart
final result = await isar.shoes.filter()
  .not().sizeEqualTo(46)
  .and()
  .not().isUnisexEqualTo(true)
  .findAll();
```

이 쿼리는 `size != 46 && isUnisex != true` 와 같습니다.

### 문자열 조건들

위에 있는 쿼리 조건들 말고도, String 값에서는 좀 더 많은 조건들이 제공됩니다. 정규식과 유사한 와일드카드를 사용하면 검색의 유연성을 높일 수 있습니다.

| 조건                 | 설명                                           |
| -------------------- | ---------------------------------------------- |
| `.startsWith(value)` | 주어진 `value` 로 시작하는 문자열 값들.        |
| `.contains(value)`   | 주어진 `value` 를 포함하는 문자열 값들.        |
| `.endsWith(value)`   | 주어진 `value` 로 끝나는 문자열 값들.          |
| `.matches(wildcard)` | 주어진 `wildcard` 패턴과 일치하는 문자열 값들. |

**대소문자 구분**  
모든 문자열 연산은 추가적인 `caseSensitive` 매개변수를 가지고 있습니다.
기본값은 `true`.

**와일드 카드:**  
[와일드카드 문자열 표현식](https://ko.wikipedia.org/wiki/%EC%99%80%EC%9D%BC%EB%93%9C%EC%B9%B4%EB%93%9C_%EB%AC%B8%EC%9E%90) 다음 2개의 특수한 와일드카드 문자를 포함한 문자열 입니다.

- 와일드카드 `*` 는 0개 이상의 어떠한 문자열과 대응됩니다.
- 와일드카드 `?` 은 어떠한 문자 하나와 대응됩니다.
  예를 들어, 와일드카드 문자열 `"d?g"` 는 `"dog"`, `"dig"`, `"dug"` 와 일치하지만, `"ding"`, `"dg"`, `"a dog"` 와는 일치하지 않습니다.

### 쿼리 수정자 (query modifiers)

경우에 따라서 일부 조건이나 다른 값들을 기준으로 쿼리를 작성해야 할 수도 있습니다. Isar 에는 조건부 쿼리를 작성하기 위한 매우 강력한 도구가 있습니다.

| 수정자                | 설명                                                                                                                            |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `.optional(cond, qb)` | `condition` 이 `true` 인 경우에만 쿼리를 확장합니다. 조건부로 정렬하거나 제한하기 위해서 쿼리의 모든 곳에서 사용할 수 있습니다. |
| `.anyOf(list, qb)`    | `value` 의 각 값에 대한 쿼리를 확장하고 논리적 **or** 을 사용해서 조건을 결합합니다.                                            |
| `.allOf(list, qb)`    | `value` 의 각 값에 대한 쿼리를 확장하고 논리적 **and** 를 사용해서 조건을 결합합니다.                                           |
|                       |

이 예시에서, 선택적 필터를 사용해서 신발을 찾는 메서드를 만듭니다.

```dart
Future<List<Shoe>> findShoes(Id? sizeFilter) {
  return isar.shoes.filter()
    .optional(
      sizeFilter != null, // sizeFilter != null 이 아닐 때만 적용됩니다.
      (q) => q.sizeEqualTo(sizeFilter!),
    ).findAll();
}
```

여러 신발 크기 중 하나를 가진 모든 신발을 찾으려면, 일반적인 쿼리를 작성하거나 `anyOf()` 수정자를 사용할 수 있습니다:

```dart
final shoes1 = await isar.shoes.filter()
  .sizeEqualTo(38)
  .or()
  .sizeEqualTo(40)
  .or()
  .sizeEqualTo(42)
  .findAll();

final shoes2 = await isar.shoes.filter()
  .anyOf(
    [38, 40, 42],
    (q, int size) => q.sizeEqualTo(size)
  ).findAll();

// shoes1 == shoes2
```

쿼리 수정자는 동적 쿼리를 작성할 때 특히 유용합니다.

### 리스트

심지어 리스트를 쿼리할 수도 있습니다:

```dart
class Tweet {
  Id? id;

  String? text;

  List<String> hashtags = [];
}
```

리스트의 길이에 대해서 쿼리할 수 있습니다.

```dart
final tweetsWithoutHashtags = await isar.tweets.filter()
  .hashtagsIsEmpty()
  .findAll();

final tweetsWithManyHashtags = await isar.tweets.filter()
  .hashtagsLengthGreaterThan(5)
  .findAll();
```

다트 코드로 `tweets.where((t) => t.hashtags.isEmpty);` 와 `tweets.where((t) => t.hashtags.length > 5);` 같습니다. 리스트 요소에 대해서 쿼리할 수 있습니다.

```dart
final flutterTweets = await isar.tweets.filter()
  .hashtagsElementEqualTo('flutter')
  .findAll();
```

다트 코드로 `tweets.where((t) => t.hashtags.contains('flutter'));` 와 같습니다.

### 임베드된 객체들

임베드된 객체는 Isar 의 가장 유용한 기능 중 하나 입니다. 최상위 객체와 동일한 조건을 사용하여 매우 효율적으로 쿼리할 수 있습니다. 다음과 같은 모델이 있다고 가정합시다:

```dart
@collection
class Car {
  Id? id;

  Brand? brand;
}

@embedded
class Brand {
  String? name;

  String? country;
}
```

`BMW` 라는 브랜드와 `"Germany"` 라는 나라를 갖는 모든 차들을 쿼리하고 싶습니다. 다음 쿼리를 사용해서 이 작업을 수행할 수 있습니다.

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q
    .nameEqualTo('BMW')
    .and()
    .countryEqualTo('Germany')
  ).findAll();
```

항상 중첩된 쿼리들을 그룹화하세요. 위의 쿼리가 다음 쿼리보다 효율적입니다. 결과는 같겠지만요:

```dart
final germanCars = await isar.cars.filter()
  .brand((q) => q.nameEqualTo('BMW'))
  .and()
  .brand((q) => q.countryEqualTo('Germany'))
  .findAll();
```

### 링크(Link)

모델이 [링크와 백링크](links) 를 포함하고 있다면 연결된 객체 또는 연결된 객체 수를 기준으로 쿼리를 필터링 할 수 있습니다.

:::warning
Isar 는 링크된 객체를 조회해야 하므로 링크 쿼리의 비용은 비쌀 수 있습니다. 대신 임베드된 객체를 사용하는 것을 고려해 보십시오.
:::

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

  final teachers = IsarLinks<Teacher>();
}
```

수학이나 영어 선생님이 있는 모든 학생을 찾습니다:

```dart
final result = await isar.students.filter()
  .teachers((q) {
    return q.subjectEqualTo('Math')
      .or()
      .subjectEqualTo('English');
  }).findAll();
```

링크 필터는 하나 이상의 연결된 객체가 조건과 일치하면 `true` 로 평가합니다.

선생님이 없는 모든 학생을 찾아봅시다:

```dart
final result = await isar.students.filter().teachersLengthEqualTo(0).findAll();
```

또는 이렇게 할 수 있습니다:

```dart
final result = await isar.students.filter().teachersIsEmpty().findAll();
```

## Where 절

Where 절은 매우 강력한 도구이지만, 제대로 이해하는 것은 약간 어렵습니다.

filter 와 달리 where 절은 쿼리 조건을 검사하기 위해서 스키마에서 정의된 index 들을 사용합니다. 인덱스를 쿼리하는 것이 레코드 각각을 필터링하는 것보다 훨씬 빠릅니다.

➡️ 더 알아보기: [인덱스](indexes)

:::팁
기본적으로 where 절을 사용해서 레코드를 최대한 줄이고 나머지에 대해 필터링을 수행해야 합니다.
:::

논리적 **or** 을 사용하여 where 절만 결합할 수 있습니다. 즉, 여러 where 절들의 합집합을 구할 수는 있지만, 여러 where 절들의 교집합을 쿼리할 수 는 없습니다.

신발 컬렉션에 인덱스를 추가합니다:

```dart
@collection
class Shoe with IsarObject {
  Id? id;

  @Index()
  Id? size;

  late String model;

  @Index(composite: [CompositeIndex('size')])
  late bool isUnisex;
}
```

두 개의 인덱스가 있습니다. `size` 의 인덱스를 사용하면 `.sizeEqualTo()` 와 같은 절을 사용할 수 있습니다. `isUnisex` 의 합성 인덱스는 `isUnisexSizeEqualTo()` 와 같은 where 절을 가능하게 합니다. 하지만 인덱스의 접두사를 항상 사용할 수 있기 때문에 `isUnisexEqualTo()` 도 허용됩니다.

우리는 복합 인덱스를 사용해서 46사이즈의 남녀공용 신발을 찾는 이전의 쿼리를 다시 작성할 수 있습니다. 이 쿼리는 이전 쿼리보다 훨씬 빨라집니다:

```dart
final result = isar.shoes.where()
  .isUnisexSizeEqualTo(true, 46)
  .findAll();
```

where 절은 2개의 초능력을 더 가지고 있습니다: "무료" 정렬과 초고속 구별(distinct) 작업을 제공합니다.

### where 절과 filter 결합하기

`shoes.filter()` 쿼리가 기억나죠? 그건 사실 `shoes.where().filter()` 의 줄임 표현입니다. 양 쪽의 장점들을 사용하기 위해서 하나의 쿼리 안에서 where 절과 filter 를 결합할 수 있습니다.

```dart
final result = isar.shoes.where()
  .isUnisexEqualTo(true)
  .filter()
  .modelContains('Nike')
  .findAll();
```

필터링할 개체 수를 줄이기 위해서 where 절이 먼저 적용됩니다. 남은 객체들에 필터가 적용됩니다.
The where clause is applied first to reduce the number of objects to be filtered. Then the filter is applied to the remaining objects.

## 정렬

`.sortBy()`, `.sortByDesc()`, `.thenBy()` 및 `.thenByDesc()` 메서드를 사용해서 쿼리를 실행할 때 결과를 정렬하는 방법을 정의합니다.

인덱스를 사용하지 않고 모델 이름 기준으로 오름차순, 크기 기준으로 내림차순 정렬된 모든 신발을 찾으려면 이렇게 합니다.

```dart
final sortedShoes = isar.shoes.filter()
  .sortByModel()
  .thenBySizeDesc()
  .findAll();
```

특히 정렬은 오프셋과 제한 이전에 실행되기 때문에, 많은 결과를 정렬하는 것은 비용이 많이 듭니다. 위의 정렬 방법은 인덱스를 사용하지 않습니다. 다행히, 우리는 where 절 정렬을 다시 사용할 수 있고 백만 개의 객체를 정렬하는 경우에도 번개처럼 빠르게 수행할 수 있습니다.

### where 절 정렬

쿼리에 **단일** where 절을 사용하는 경우 결과가 이미 인덱스 기준으로 정렬되어 있습니다. 정말 큰일입니다!

신발의 크기가 `[43, 39, 48, 40, 42, 45]` 이고 `42` 보다 큰 모든 신발을 찾고 크기별로 정렬한다고 가정해 보겠습니다.

```dart
final bigShoes = isar.shoes.where()
  .sizeGreaterThan(42) // 크기 기준으로 정렬까지 됩니다.
  .findAll(); // -> [43, 45, 48]
```

결과는 기본적으로 `size` 인덱스 기준으로 정렬됩니다. where 절의 정렬 순서를 반대로 하려면 `sort` 를 `Sort.desc` 로 설정하면 됩니다:

```dart
final bigShoesDesc = await isar.shoes.where(sort: Sort.desc)
  .sizeGreaterThan(42)
  .findAll(); // -> [48, 45, 43]
```

가끔 where 절을 이용하지 않지만 암시적인 정렬을 원하는 경우가 있습니다. `any` where 절을 사용하면 됩니다.

```dart
final shoes = await isar.shoes.where()
  .anySize()
  .findAll(); // -> [39, 40, 42, 43, 45, 48]
```

복합 인덱스를 사용하는 경우, 인덱스의 모든 필드 별로 결과가 정렬됩니다.

:::tip 
결과를 정렬해야 하는 경우 인덱스를 사용하는 게 좋습니다. 특히 `offset()` 과 `limit()` 를 사용하여 작업하는 경우에는 더욱 그렇습니다.
::: 

인덱스를 사용해서 정렬할 수 없거나 유용하지 않은 경우가 있습니다. 이러한 경우 인덱스를 사용하여 결과 항목 수를 최대한 줄여야 합니다.

## 고유한 값들 (Unique values)

고유한 값들로만 이루어진 항목들을 반환하려면 distinct 술어를 사용하세요. 예를 들어, Isar 데이터베이스에 있는 신발 모델의 수를 확인하려면 다음과 같이 하세요.

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .findAll();
```

여러 개의 개별 조건들을 체인으로 연결해서 모델 크기 조합이 다른 모든 신발을 찾을 수 있습니다.

```dart
final shoes = await isar.shoes.filter()
  .distinctByModel()
  .distinctBySize()
  .findAll();
```

각 고유한 조합의 첫 번째 결과만 반환됩니다. where 절 및 정렬 작업을 사용하여 이를 제어할 수 있습니다.

### Where 절 구분 (Where clause distinct)

고유하지 않은 인덱스가 있는 경우, 구분된 값들을 모두 가져올 수 있습니다. 이전 섹션의 `distinctBy` 연산을 사용할 수 있지만, 정렬 및 필터 이후에 실행되므로 오버헤드가 있습니다. 단일 where 절만 사용하는 경우 인덱스를 사용하여 구분 작업을 수행할 수 있습니다.

```dart
final shoes = await isar.shoes.where(distinct: true)
  .anySize()
  .findAll();
```

:::tip
이론적으로는 정렬 및 구분을 위해서 여러 개의 where 절을 사용하 수 있습니다. 유일한 제약은 where 절이 중복되지 않고 동일한 인덱스를 사용하는 것입니다. 올바른 정렬을 위해서는 정렬 순서로 적용해야 합니다. 이것에 의존하는 것은 매우 조심하세요!
In theory, you could even use multiple where clauses for sorting and distinct. The only restriction is that those where clauses are not overlapping and use the same index. For correct sorting, they also need to be applied in sort order. Be very careful if you rely on this!
:::

## 오프셋과 제한(Offset & Limit)

lazy 리스트 뷰를 위해서 쿼리 결과를 제한하는 것이 좋습니다. 다음과 같이 `limit()` 를 설정해서 할 수 있습니다.

```dart
final firstTenShoes = await isar.shoes.where()
  .limit(10)
  .findAll();
```

`offset()` 을 이용해서 쿼리를 페이징할 수 있습니다.
By setting an `offset()` you can also paginate the results of your query.

```dart
final firstTenShoes = await isar.shoes.where()
  .offset(20)
  .limit(10)
  .findAll();
```

Dart 객체를 인스턴스화하는 것은 보통 쿼리 실행에서 비용이 가장 많이 드는 부분이기 때문에, 필요한 객체만 불러오는 것이 좋습니다.

## 실행 순서

Isar 는 항상 다음 순서로 쿼리들을 실행합니다.

1. 주 또는 보조 인덱스를 순회하면서 객체를 찾습니다. (where 절 적용)
2. Filter
3. 정렬
4. 구분 연산
5. 오프셋 & 제한
6. 결과 반환

## 쿼리 연산들

이전 예제들에서 일치하는 모든 객체들을 검색하기 위해서 `.findAll()` 을 사용했습니다. 그러나 더 많은 연산을 사용할 수 있습니다.

| 연산             | 설명                                                                                                                 |
| ---------------- | -------------------------------------------------------------------------------------------------------------------- |
| `.findFirst()`   | 일치하는 첫 객체 또는 일치하는 것이 없는 경우 `null` 을 반환합니다.                                                  |
| `.findAll()`     | 일치하는 모든 객체들을 검색합니다.                                                                                   |
| `.count()`       | 쿼리와 일치하는 객체의 수를 셉니다.                                                                                  |
| `.deleteFirst()` | 컬렉션에서 일치하는 첫 객체를 제거합니다.                                                                            |
| `.deleteAll()`   | 컬렉션에서 일치하는 모든 객체를 제거합니다.                                                                          |
| `.build()`       | 쿼리를 나중에 사용하기 위해 컴파일 합니다. 이렇게 하면 쿼리를 여러 번 실행하는 경우 쿼리를 만드는 비용이 절약됩니다. |

## 속성 쿼리 (Property queries)

단일 속성 값에만 관심이 있는 경우 속성 쿼리를 사용하세요. 일반 쿼리를 만들고 속성을 선택하세요:

```dart
List<String> models = await isar.shoes.where()
  .modelProperty()
  .findAll();

List<int> sizes = await isar.shoes.where()
  .sizeProperty()
  .findAll();
```

단일 속성만 이용하면 역직렬화에 걸리는 시간을 절약할 수 있습니다. 속성 쿼리는 임베드된 객체와 리스트에도 사용할 수 있습니다.

## 집계 (Aggregation)

Isar 에서는 속성 쿼리의 값을 집계할 수 있습니다. 다음 집계 연산이 가능합니다.

| 연산         | 설명                                                                        |
| ------------ | --------------------------------------------------------------------------- |
| `.min()`     | 최소값 또는 일치하는 것이 없는 경우 `null` 을 반환합니다.                   |
| `.max()`     | 최대값 또는 일치하는 것이 없는 경우 `null` 을 반환합니다.                   |
| `.sum()`     | 모든 값들을 더합니다.                                                       |
| `.average()` | 모든 값들의 평균을 계산합니다. 일치하는 값이 없는 경우 `NaN` 을 반환합니다. |

집계를 사용하는 것이 일치하는 모든 객체를 찾은 다음 집계를 수동으로 하는 것보다 훨씬 빠릅니다.

## 동적 쿼리

:::danger
이 섹션은 대부분 사용자와는 관련이 없습니다. 반드시 필요한 경우(거의 그럴 일은 없습니다.)가 아니면 동적 쿼리를 사용하지 않는 것이 좋습니다.
:::

위의 모든 예시에서 QueryBuilder와 생성된 정적 확장 메서드들을 사용했습니다. 동적 쿼리 또는 사용자 지정 쿼리 언어 (Isar Inspector 같은) 를 만들 수 있습니다. 이 경우 `buildQuery()` 메서드를 사용할 수 있습니다.

| 매개변수        | 설명                                                                           |
| --------------- | ------------------------------------------------------------------------------ |
| `whereClauses`  | 이 쿼리의 where 절들 입니다.                                                   |
| `whereDistinct` | where 절이 구분된 값을 반환해야 하는 지 여부입니다. (단일 where 절에만 유효함) |
| `whereSort`     | where 절의 순회 순서 입니다. (단일 where 절에만 유효함)                        |
| `filter`        | 결과에 적용할 필터입니다.                                                      |
| `sortBy`        | 정렬의 기준으로 사용할 속성의 리스트입니다.                                    |
| `distinctBy`    | 구분할 속성 리스트 입니다.                                                     |
| `offset`        | 결과의 오프셋 입니다.                                                          |
| `limit`         | 반환할 결과의 최대 개수입니다.                                                 |
| `property`      | null이 아닌 경우 이 속성의 값만 반환됩니다.                                    |

동적 쿼리를 만들어 봅시다:

```dart
final shoes = await isar.shoes.buildQuery(
  whereClauses: [
    WhereClause(
      indexName: 'size',
      lower: [42],
      includeLower: true,
      upper: [46],
      includeUpper: true,
    )
  ],
  filter: FilterGroup.and([
    FilterCondition(
      type: ConditionType.contains,
      property: 'model',
      value: 'nike',
      caseSensitive: false,
    ),
    FilterGroup.not(
      FilterCondition(
        type: ConditionType.contains,
        property: 'model',
        value: 'adidas',
        caseSensitive: false,
      ),
    ),
  ]),
  sortBy: [
    SortProperty(
      property: 'model',
      sort: Sort.desc,
    )
  ],
  offset: 10,
  limit: 10,
).findAll();
```

다음 쿼리와 동일합니다:

```dart
final shoes = await isar.shoes.where()
  .sizeBetween(42, 46)
  .filter()
  .modelContains('nike', caseSensitive: false)
  .not()
  .modelContains('adidas', caseSensitive: false)
  .sortByModelDesc()
  .offset(10).limit(10)
  .findAll();
```
