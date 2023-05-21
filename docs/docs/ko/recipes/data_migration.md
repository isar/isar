---
title: 데이터 마이그레이션 (Data migration)
---

# 데이터 마이그레이션

Isar 는 컬렉션, 속성, 인덱스를 추가하거나 삭제하면 데이터베이스 스키마를 자동으로 마이그레이션합니다. 가끔은 데이터도 마이그레이션해야 할 수 있습니다. Isar 는 임의 마이그레이션 제한을 적용하기 때문에 기본 제공 솔루션을 제공하지는 않습니다. 사용자의 요구사항에 맞는 마이그레이션 로직을 쉽게 구현할 수 있습니다.

이 예시에서는 전체 데이터베이스에서 하나의 버전을 이용하려고 합니다. shared preferences 를 사용해서 현재 버전을 저장하고 마이그레이션하려는 버전과 비교합니다. 버전이 일치하지 않으면 데이터를 마이그레이션하고 버전을 업데이트 합니다.

:::tip
각 컬렉션에 자체 버전을 지정하고 개별적으로 마이그레이션 할 수 있습니다.
:::

생일 필드가 있는 사용자 컬렉션이 있다고 상상해 보십시오. 우리 앱의 버전 2에서는 나이를 기준으로 사용자를 조회할 수 있는 추가 출생 연도 필드가 필요합니다.

버전 1:

```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;
}
```

버전 2:

```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

문제는 기존에 있던 사용자 모델들은 버전 1에서 `birthYear` 가 없었기 때문에 비어있는 `birthYear` 를 가지게 된다는 것입니다. 우리는 `birthYear` 필드를 설정하기 위해서 데이터를 마이그레이션 해야 합니다.

```dart
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [UserSchema],
    directory: dir.path,
  );

  await performMigrationIfNeeded(isar);

  runApp(MyApp(isar: isar));
}

Future<void> performMigrationIfNeeded(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  final currentVersion = prefs.getInt('version') ?? 2;
  switch(currentVersion) {
    case 1:
      await migrateV1ToV2(isar);
      break;
    case 2:
      // 버전이 설정되지 않았거나(새로 설치한 경우), 이미 2인 경우 마이그레이션할 필요가 없습니다.
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // 버전 업데이트
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // 모든 사용자를 한 번에 메모리에 로드하지 않도록 사용자를 페이지 분할합니다.
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // 생년월일 게터를 사용하기 때문에 업데이트할 필요가 없습니다.
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
많은 데이터를 마이그레이션 해야 하는 경우 UI 스레드에 부담이 가지 않도록 백그라운드 isolate 를 사용하는 것이 좋습니다.
:::
