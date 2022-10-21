---
title: 文字列のID
---

# 文字列のID

このチュートリアルは、私が最も頻繁に受け取るリクエストの一つです。

IsarはString IDを標準サポートしていませんが、それには理由があります。特にリンクの場合、String IDのオーバーヘッドが大きすぎるのです。

時には、UUIDやその他の整数型ではないidを利用する外部データを保存しなければならない場合があることは理解しています。 そこで、String idをオブジェクトのプロパティとして保存し、fastHashを実装して、Idとして使用できる64ビットintを生成することをお勧めします。

```dart
@collection
class User {
  String? id;

  Id get isarId => fastHash(id!);

  String? name;

  int? age;
}
```

この方法を使用すれば、リンク用の効率的な整数IDと、文字列IDを使用する機能という、両方の長所を得ることができます。

## Fast hash 関数

ハッシュ関数は高品質で高速なものが理想的です（かつコリジョンは避けたい）。
そこで、以下のような実装をお勧めします。

```dart
/// Dart Stringsの為に最適化されたFNV-1a 64bitハッシュアルゴリズム 
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
```

もし別のハッシュ関数を選択したい場合は、64ビットの整数値を返すことを確認する事に加えて、暗号化ハッシュ関数を使用することは避けてください（処理速度が大幅に低下します）。

:::warning
`String.hashCode` は、異なるプラットフォームやバージョンの Dart で安定して動作することが保証されていないため、使用しないようにしましょう。
:::
