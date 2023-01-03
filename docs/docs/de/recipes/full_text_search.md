---
title: Volltextsuche
---

# Volltextsuche

Volltextsuche ist ein mächtiges Werkzeug um Text in der Datenbank zu suchen. Du solltest schon damit vertraut sein, wie [Indizes](/indexes) funktionieren, aber wir schauen uns die Grundlagen an.

Ein Index funktioniert wie eine Nachschlagetabelle, die es der Abfrage-Engine ermöglicht Einträge mit einem bestimmten Wert schnell zu finden. Zum Beispiel, wenn du ein `title`-Feld in deinem Objekt hast, kannst du einen Index auf das Feld anlegen, um die Geschwindigkeit zu erhöhen, ein Objekt mit bestimmtem Titel zu finden.

## Warum ist Volltextsuche sinnvoll?

Du kannst Text leicht durchsuchen, indem du Filter verwendest. Es gibt mehrere unterschiedliche String-Operationen, zum Beispiel `.startsWith()`, `.contains()` und `.matches()`. Das Problem mit Filtern ist, dass ihre Laufzeit `O(n)` ist, wobei `n` die Anzahl der Einträge in der Collection ist. String-Operationen wie `.matches()` sind besonders teuer.

:::tip
Volltextsuche ist deutlich schneller als Filter, aber Indizes haben ein paar Einschränkungen. In diesem Rezept wollen wir uns angucken, wie man diese Limitationen umgeht.
:::

## Grundlegendes Beispiel

Die Idee ist immer die Gleiche: Anstatt den ganzen Text zu indizieren, indizieren wir die Worte im Text, sodass wir individuell nach ihnen suchen können.

Bauen wir den grundlegendsten Volltext-Index:

```dart
class Message {
  Id? id;

  late String content;

  @Index()
  List<String> get contentWords => content.split(' ');
}
```

Wir können jetzt nach Nachrichten suchen, die spezifische Worte enthalten:

```dart
final posts = await isar.messages
  .where()
  .contentWordsAnyEqualTo('hello')
  .findAll();
```

Diese Abfrage ist superschnell, aber es gibt ein paar Probleme:

1. Wir können nur nach ganzen Worten suchen
2. Wir missachten Zeichensetzung
3. Wir unterstützen keine anderen Leerzeichen

## Text richtig trennen

Versuchen wir das vorherige Beispiel zu verbessern. Wir könnten versuchen einen komplizierten Regex zu entwickeln, um Worte zu trennen, aber das ist vermutlich langsam und in Grenzfällen falsch.

Der [Unicode Annex #29](https://unicode.org/reports/tr29/) definiert wie man, für fast alle Sprachen, Text richtig in Worte trennt. Das ist ziemlich kompliziert, aber glücklicherweise macht Isar den schwierigsten Teil der Arbeit für uns:

```dart
Isar.splitWords('hello world'); // -> ['hello', 'world']

Isar.splitWords('The quick (“brown”) fox can’t jump 32.3 feet, right?');
// -> ['The', 'quick', 'brown', 'fox', 'can’t', 'jump', '32.3', 'feet', 'right']
```

## Ich will mehr Kontrolle

Das ist kinderleicht! Wir können unseren Index so ändern, dass er auch Präfixe findet und Groß-/Kleinschreibung ignoriert:

```dart
class Post {
  Id? id;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get titleWords => title.split(' ');
}
```

Isar speichert die Worte standardmäßig als gehashte Werte, was schnell und platzsparend ist. Aber Hashes können nicht für die Präfixüberprüfung verwendet werden. Wenn wir `IndexType.value` verwenden, können wir den Index ändern, um direkt Worte zu benutzen. Das ermöglicht uns die `.titleWordsAnyStartsWith()`-Where-Klausel benutzen zu können:

```dart
final posts = await isar.posts
  .where()
  .titleWordsAnyStartsWith('hel')
  .or()
  .titleWordsAnyStartsWith('welco')
  .or()
  .titleWordsAnyStartsWith('howd')
  .findAll();
```

## Ich brauche auch `.endsWith()`

Klar! Wir werden einen Trick verwenden, um `.endsWith()` verwenden zu können:

```dart
class Post {
    Id? id;

    late String title;

    @Index(type: IndexType.value, caseSensitive: false)
    List<String> get revTitleWords {
        return Isar.splitWords(title).map(
          (word) => word.reversed).toList()
        );
    }
}
```

Vergiss nicht das Wortende umzukehren nach dem du suchen willst:

```dart
final posts = await isar.posts
  .where()
  .revTitleWordsAnyStartsWith('lcome'.reversed)
  .findAll();
```

## Abstammungsalgorithmen

Leider unterstützen Indizes nicht die `.contains()`-Methode (das stimmt auch für andere Datenbanken). Aber es gibt ein paar Alternativen, die es wert sind, erkundet zu werden. Eine Wahl hängt stark von deinem Verwendungszweck ab. Ein Beispiel ist, den Ursprung von Worten, statt ganzer Worte, zu indizieren.

Ein Abstammungsalgorithmus ist der Prozess einer linguistischen Normalisierung, bei dem die Varianten eines Wortes in eine gleichmäßige Form reduziert werden:

```
connection
connections
connective          --->   connect
connected
connecting
```

Beliebte Algorithmen sind der [Porter stemming algorithm](https://tartarus.org/martin/PorterStemmer/) und der [Snowball stemming algorithms](https://snowballstem.org/algorithms/).

Es gibt auch fortgeschrittenere Formen wie der [Lemmatisierung](https://de.wikipedia.org/wiki/Lemma_(Lexikographie)#Lemmatisierung).

## Phonetische Suche

Eine [Phonetische Suche](https://de.wikipedia.org/wiki/Phonetische_Suche) ist ein Algorithmus, um Worte nach ihrer Aussprache zu indizieren. Anders augedrückt, erlaubt es dir Worte zu finden, die ähnlich zu den Gesuchten klingen.

:::warning
Die meisten phonetischen Algorithmen unterstützen nur eine einzige Sprache.
:::

### Soundex

[Soundex](https://de.wikipedia.org/wiki/Soundex) ist ein phonetischer Algorithmus um Namen danach zu indizieren, wie sie im Englischen ausgesprochen werden. Das Ziel ist es Homophone in die gleiche Repräsentation zu übertragen, sodass sie gefunden werden, trotz der kleinen Unterschiede in der Rechtschreibung. Es ist ein unkomplizierter Algorithmus, von dem es mehrere verbesserte Versionen gibt.

Wenn du diesen Algorithmus verwendest, wegeben `"Robert"` und `"Rupert"` beide den String `"R163"`, während `"Rubin"` `"R150"` ergibt. `"Ashcraft"` und `"Ashcroft"` erzeugen beide `"A261"`.

### Double Metaphone

Der phonetische Umwandlungsalgorithmus [Double Metaphone](https://en.wikipedia.org/wiki/Metaphone) ist die zweite Generation dieses Algorithmus. Er macht mehrere fundamentale Designverbesserungen gegenüber dem originalen Metaphone-Algorithmus.

Double Metaphone klärt verschiedene Unregelmäßigkeiten im Englischen aufgrund von slawischer, germanischer, keltischer, griechischer, französischer, italienischer, spanischer, chinesischer und anderer Herkunft.
