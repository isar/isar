---
title: 빠른 시작
---

# 빠른 시작

세상에, 이제야 왔군요! 가장 멋진 플러터 데이터베이스를 사용해 보겠습니다...

이 빠른 시작에서는 말은 줄이고 바로 코드를 보겠습니다.

## 1. 의존성 추가하기

재미있는 부분을 보기 전에 `pubspec.yaml` 에 몇 개의 패키지를 추가해야 합니다. 우리는 펍을 이용해서 힘든 일을 쉽게 할 수 있습니다.

```bash
flutter pub add isar isar_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. 클래스에 주석 추가(어노테이션)

컬렉션 클래스에 `@collection` 으로 주석을 달고 `Id` 필드를 선택합니다.

```dart
part 'email.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // id = null 을 사용해도 자동 증분할 수 있습니다.

  String? name;

  int? age;
}
```

Id는 컬렉션에서 개체를 고유하게 식별하고 나중에 개체를 다시 찾을 수 있도록 합니다.

## 3. 코드 생성기를 실행하기

다음 명령을 실행하여 `build_runner` 를 시작합니다:

```
dart run build_runner build
```

플러터를 사용하고 있다면, 다음 명령을 사용합니다.

```
flutter pub run build_runner build
```

## 4. Isar 인스턴스 열기

새 Isar 인스턴스를 열고 모든 컬렉션 스키마를 전달합니다. 선택적으로 인스턴스 이름과 디렉토리를 지정할 수도 있습니다.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [EmailSchema],
  directory: dir.path,
);
```

## 5. 읽기와 쓰기

한번 인스턴스를 열면, 콜렉션들을 사용할 수 있습니다.

모든 기본적인 CRUD 작업은 `IsarCollection` 을 통해서 이루어집니다.

```dart
final newUser = User()..name = 'Jane Doe'..age = 36;

await isar.writeTxn(() async {
  await isar.users.put(newUser); // 삽입 & 업데이트
});

final existingUser = await isar.users.get(newUser.id); // 가져오기

await isar.writeTxn(() async {
  await isar.users.delete(existingUser.id!); // 삭제
});
```

## 다른 자료들

혹시 영상으로 공부를 하는 것이 더 좋나요? 다음 영상으로 Isar를 시작해보세요:

<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/CwC9-a9hJv4" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/videoseries?list=PLKKf8l1ne4_hMBtRykh9GCC4MMyteUTyf" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/pdKb8HLCXOA " title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
