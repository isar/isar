---
title: CRUD 조작
---

# CRUD 조작

컬렉션이 정의되었다면, 이제 조작하는 방법을 배워봅시다!

## Isar 열기

무엇을 하든 우선 Isar 인스턴스가 필요합니다. 각 인스턴스에는 데이터베이스 파일을 저장할 수 있도록 쓰기 권한이 있는 디렉토리가 필요합니다. 디렉토리를 지정하지 않는 경우 Isar는 현재 플랫폼에 적합한 기본 디렉토리를 찾습니다.

Isar 인스턴스에서 사용하고 싶은 모든 스키마를 지정합니다. 여러 인스턴스를 열고 있는 경우에도 각각의 인스턴스에 동일한 스키마를 부여해야 합니다.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [RecipeSchema],
  directory: dir.path,
);
```

기본 구성을 사용하거나 다음 매개 변수 중 일부를 제공할 수 있습니다:

| Config              | Description                                                                                                                                                                                                                                |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `name`              | 여러 인스턴스를 다른 이름으로 엽니다. 기본적으로 `"default"`가 사용됩니다.                                                                                                                                                                 |
| `directory`         | 이 인스턴스의 저장 장소 입니다. 상대 경로 또는 절대 경로를 전달할 수 있습니다. 기본값으로, iOS 에서는 `NSDocumentDirectory`, Android 에서는 `getDataDirectory` 가 사용됩니다. 웹에서는 필요하지 않습니다.                                  |
| `maxSizeMib`        | 데이터베이스 파일의 최대 크기(MiB)입니다. Isar는 무한하지 않은 가상 메모리를 사용하므로 여기 값을 명심하세요. 여러 인스턴스를 열면 사용 가능한 가상 메모리가 공유되므로 각 인스턴스의 `maxSizeMib` 가 더 작아집니다. 기본값은 2048 입니다. |
| `relaxedDurability` | 내구성 보장을 완화하여 쓰기 성능을 향상 시킵니다. 시스템 충돌(앱 충돌이 아닌) 의 경우 마지막으로 커밋된 트랜잭션이 손실될 수 있습니다. 완전히 파손(Corruption)될 가능성은 없습니다.                                                        |
| `compactOnLaunch`   | 인스턴스를 열 때 데이터베이스를 압축해야 하는지 여부를 확인하는 조건입니다.                                                                                                                                                                |
| `inspector`         | 디버그 빌드에 대해서 Inspector 를 사용하도록 설정합니다. 프로파일이나 릴리즈 빌드에서는 이 옵션이 무시됩니다.                                                                                                                              |

인스턴스가 이미 열려 있는 경우 `Isar.open()` 을 호출하면 지정된 매개 변수에 관계없이 기존 인스턴스가 생성됩니다. isolate 안에서 Isar 를 사용할 때 유용합니다.

:::tip
모든 플랫폼에서 유효한 저장 경로를 얻기 위해서 [path_provider](https://pub.dev/packages/path_provider) 패키지를 사용하는 것을 고려해보세요.
:::

데이터베이스 파일의 저장 위치는 `directory/name.isar` 입니다.

## 데이터베이스에서 읽기

Isar 에서 지정된 타입의 새로운 객체를 찾고 쿼리하고 생성할 때 `IsarCollection` 인스턴스를 사용합니다.

밑에 나올 예시들에서, 우리는 다음과 같이 정의된 `Recipe` 컬렉션이 있다고 가정합니다.

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### 컬렉션을 가져오기

모든 컬렉션들은 Isar 인스턴스 안에 있습니다. 레시피 컬렉션은 다음 방법으로 가져옵니다:

```dart
final recipes = isar.recipes;
```

너무 쉽죠! 컬렉션 접근자를 사용하기 싫다면, `collection()` 메서드를 사용해도 됩니다.

```dart
final recipes = isar.collection<Recipe>();
```

### 객체 얻기 (id를 이용)

아직 컬렉션에 데이터가 들어있지 않지만, 아이디 `123` 의 가상의 객체가 있다고 가정하고 가져오겠습니다.

```dart
final recipe = await isar.recipes.get(123);
```

`get()` 은 객체를 `Future` 로 반환하고, 해당 객체가 존재하지 않는 경우에는 `null` 을 반환합니다. 모든 Isar 작업들은 기본적으로 비동기적으로 작동합니다. 대부분의 경우는 동기적인 방법도 가지고 있습니다.

```dart
final recipe = isar.recipes.getSync(123);
```

:::warning
UI isolate 에서는 비동기 버전을 기본적으로 사용해야 합니다. 하지만 Isar 는 매우 빠르기 때문에, 동기식으로 사용하는 것도 종종 허용됩니다.
:::

한 번에 여러 객체를 가져오려면 `getAll()` 또는 `getAllSync()` 를 사용하세요:

```dart
final recipe = await isar.recipes.getAll([1, 2]);
```

### 객체 쿼리

id를 이용해서 객체를 가져오는 대신, `.where()` 과 `.filter()` 를 사용해서 특정 조건에 맞는 객체 목록을 쿼리할 수 있습니다:

```dart
final allRecipes = await isar.recipes.where().findAll();

final favouires = await isar.recipes.filter()
  .isFavoriteEqualTo(true)
  .findAll();
```

➡️ 더 알아보기: [Queries](queries)

## 데이터베이스 수정하기

드디어 컬렉션을 수정할 때가 됐습니다! 객체를 생성, 갱신, 삭제하려면 쓰기 트랜잭션 안에서 각각의 작업들을 수행하세요.

```dart
await isar.writeTxn(() async {
  final recipe = await isar.recipes.get(123)

  recipe.isFavorite = false;
  await isar.recipes.put(recipe); // 갱신 작업을 수행합니다.

  await isar.recipes.delete(123); // 또는 삭제 작업
});
```

➡️ 더 알아보기: [Transactions](transactions)

### 객체 삽입

Isar 에 객체를 보존하기 위해서, 컬렉션에 집어넣어야 합니다. 컬렉션에 객체를 삽입할 때는 Isar의 `put()` 메소드를 이용합니다. 만약 이미 들어있는 객체라면 갱신을 합니다.

id 필드가 `null` 이나 `Isar.autoIncrement` 라면, Isar 는 자동 증분 아이디를 사용합니다.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await isar.recipes.put(pancakes);
})
```

`id` 필드가 final 이 아닌 경우에 Isar 가 id를 객체에 자동으로 할당합니다.

여러 객체를 한 번에 삽입하는 것도 쉽습니다:

```dart
await isar.writeTxn(() async {
  await isar.recipes.putAll([pancakes, pizza]);
})
```

### 객체 갱신

`collection.put(object)` 를 이용해서 만들고 갱신하는 동작을 모두 할 수 있습니다. id가 `null`(또는 존재하지 않는 경우) 이라면, 객체는 추가됩니다. 그 이외의 경우에는 갱신됩니다.

만약 팬케익에 즐겨찾기를 해제하는 경우, 이렇게 할 수 있습니다.

```dart
await isar.writeTxn(() async {
  pancakes.isFavorite = false;
  await isar.recipes.put(pancakes);
});
```

### 객체 삭제

Isar 에 있는 것을 없애고 싶나요? `collection.delete(id)` 를 사용하세요. delete 메소드는 주어진 id 를 가진 객체를 찾아서 삭제합니다. id `123` 을 가지는 객체를 삭제하는 예시 입니다:

```dart
await isar.writeTxn(() async {
  final success = await isar.recipes.delete(123);
  print('Recipe deleted: $success');
});
```

get 과 put 과 마찬가지로 delete 에도 여러개를 한꺼번에 삭제하는 방법이 있습니다. 삭제된 객체의 수를 반환합니다.

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.deleteAll([1, 2, 3]);
  print('We deleted $count recipes');
});
```

만약 삭제할 객체의 id 를 모른다면 query 를 사용할 수 있습니다.

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  print('We deleted $count recipes');
});
```
