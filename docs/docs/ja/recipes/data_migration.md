---
title: データの移行
---

# データの移行

コレクション、フィールド、インデックスを追加または削除すると、Isarは自動的にデータベーススキーマを移行(マイグレート)します。時には、データも一緒に移行したい場合もあるでしょう。 Isarは組み込み解決法を提供していません。これはデタラメな移行制限が課される可能性があるためです。ただ、ニーズに合った移行ロジックを簡単に実装することができます。

この例では、データベース全体で1つのバージョンを使用したいと思います。共有環境設定を使って現在のバージョンを保存し、移行したいバージョンと比較します。バージョンが一致しない場合、データを移行し、バージョンを更新します。

:::tip
各コレクションに独自のバージョンを与え、個別に移行することも可能です。
:::

誕生日フィールドを持つユーザーコレクションがあると仮定します。このアプリのバージョン2では、年齢に基づいてユーザーを照会するために、誕生年のフィールドを追加する必要があります。

Version 1:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;
}
```

Version 2:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

問題は、バージョン1では `birthYear` フィールドが存在しないため、既存のUserモデルを作成しても空の `birthYear`が設定されることです。 `birthYear` フィールドを設定するために、データを移行する必要があります。

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
      // バージョンが設定されていない場合(新規インストール)、または既にver.2の場合は移行する必要はない
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // バージョンを更新する
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // すべてのユーザーを一度にメモリにロードするのを避けるため、ユーザーをページ分割する
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeTxn((isar) async {
      // birthYear ゲッターを使用しているため、何も更新する必要はありません
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
多くのデータを移行する必要がある場合、UIスレッドに負担がかからないようにバックグラウンドアイソレートを使用することを検討してください。
:::
