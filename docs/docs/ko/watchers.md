---
title: 감시자(Watchers)
---

# 감시자

Isar 에서는 데이터 변경을 구독할 수 있습니다. 특정 객체, 전체 컬렉션 또는 쿼리의 변경 내용을 "감시" 할 수 있습니다.

감시자(Watchers)를 사용하면 데이터베이스의 변경사항에 효율적으로 대응할 수 있습니다. 연락처가 추가될 때 UI를 재구성하거나 문서가 업데이트될 때 네트워크 요청을 보내는 등의 작업을 수행할 수 있습니다.

트랜잭션이 성공적으로 커밋되고 대상이 실제로 변경된 후 감시자에게 통지됩니다.

## 객체 감시

특정 객체가 생성, 업데이트 또는 삭제될 때 알림을 받으려면 객체를 확인해야 합니다:

```dart
Stream<User> userChanged = isar.users.watchObject(5);
userChanged.listen((newUser) {
  print('User changed: ${newUser?.name}');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// 출력: User changed: David

final user2 = User(id: 5)..name = 'Mark';
await isar.users.put(user);
// 출력: User changed: Mark

await isar.users.delete(5);
// 출력: User changed: null
```

위의 예시에서 볼 수 있듯이 객체가 아직 존재하지 않아도 됩니다. 객체가 생성되면 감시자가 알게 됩니다.

`fireImmediately` 라는 추가 매개 변수가 있습니다. `true` 로 설정하면 Isar 는 즉시 스트림에 객체의 현재 값을 추가합니다.

### 게으른 감시 (Lazy watching)

새 값 말고 변경 사항에 대해서만 구독할 수 있습니다. 그러면 Isar 가 객체를 가져올 필요가 없어집니다.

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('User 5 changed');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// 출력: User 5 changed
```

## 컬렉션 감시

단일 객체를 감시하는 대신에, 전체 컬렉션을 보고 객체가 추가, 업데이트, 또는 삭제될 때 알아차릴 수 있습니다:

```dart
Stream<void> userChanged = isar.users.watchLazy();
userChanged.listen(() {
  print('A User changed');
});

final user = User()..name = 'David';
await isar.users.put(user);
// 출력: A User changed
```

## 쿼리 감시

전체 쿼리를 감시할 수 있습니다. Isar 는 쿼리 결과가 실제로 변경될 때만 알리려고 최선을 다합니다. 링크로 인해 쿼리가 변경되는 경우 알림이 표시되지 않습니다. 링크 변경에 대한 알림이 필요한 경우 컬렉션 감시를 이용합니다.

```dart
Query<User> usersWithA = isar.users.filter()
    .nameStartsWith('A')
    .build();

Stream<List<User>> queryChanged = usersWithA.watch(fireImmediately: true);
queryChanged.listen((users) {
  print('Users with A are: $users');
});
// 출력: Users with A are: []

await isar.users.put(User()..name = 'Albert');
// 출력: Users with A are: [User(name: Albert)]

await isar.users.put(User()..name = 'Monika');
// 출력 없음

awaited isar.users.put(User()..name = 'Antonia');
// 출력: Users with A are: [User(name: Albert), User(name: Antonia)]
```

:::주의
오프셋과 제한 또는 별개의 쿼리를 사용하는 경우에, Isar 는 객체가 쿼리의 바깥에 있지만, 필터와 일치하는 경우에도 알림을 받습니다.
:::

`watchObject()` 처럼 `watchLazy()` 를 사용하여 쿼리 결과가 변경될 때 알림을 받을 수 있지만 결과를 가져오지는 않습니다.

:::위험
모든 변경 사항에 대해서 쿼리를 다시 실행하는 것은 매우 비효율적입니다. 대신 게으른 컬렉션 감시자를 사용하는 것이 가장 좋습니다.
:::
