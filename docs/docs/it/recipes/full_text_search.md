---
title: Ricerca full-text
---

# Ricerca full-text

La ricerca full-text è un modo efficace per cercare il testo nel database. Dovresti già avere familiarità con il funzionamento degli [indici](../indexes.md), ma andiamo oltre le basi.

Un indice funziona come una tabella di ricerca, consentendo al motore di query di trovare rapidamente i record con un determinato valore. Ad esempio, se hai un campo `title` nel tuo oggetto, puoi creare un indice su quel campo per rendere più veloce la ricerca di oggetti con un determinato titolo.

## Perché la ricerca full-text è utile?

Puoi cercare facilmente il testo usando i filtri. Esistono varie operazioni sulle stringhe, ad esempio `.startsWith()`, `.contains()` e `.matches()`. Il problema con i filtri è che il loro runtime è `O(n)` dove `n` è il numero di record nella raccolta. Le operazioni sulle stringhe come `.matches()` sono particolarmente costose.

:::tip
La ricerca full-text è molto più veloce dei filtri, ma gli indici presentano alcune limitazioni. In questa ricetta, esploreremo come aggirare queste limitazioni.
:::

## Esempio di base

L'idea è sempre la stessa: invece di indicizzare l'intero testo, indicizziamo le parole nel testo in modo da poterle cercare singolarmente.

Creiamo l'indice full-text più semplice:

```dart
class Message {
  Id? id;

  late String content;

  @Index()
  List<String> get contentWords => content.split(' ');
}
```

Ora possiamo cercare messaggi con parole specifiche nel contenuto:

```dart
final posts = await isar.messages
  .where()
  .contentWordsAnyEqualTo('hello')
  .findAll();
```

Questa query è super veloce, ma ci sono alcuni problemi:

1. Possiamo cercare solo parole intere
2. Non consideriamo la punteggiatura
3. Non supportiamo altri caratteri di spazio vuoto

## Dividere il testo nel modo giusto

Proviamo a migliorare l'esempio precedente. Potremmo provare a sviluppare un'espressione regolare complicata per correggere la divisione delle parole, ma probabilmente sarà lenta e sbagliata per i casi limite.

L'[Unicode Annex #29](https://unicode.org/reports/tr29/) definisce come dividere correttamente il testo in parole per quasi tutte le lingue. È piuttosto complicato, ma fortunatamente Isar fa il lavoro pesante per noi:

```dart
Isar.splitWords('hello world'); // -> ['hello', 'world']

Isar.splitWords('The quick (“brown”) fox can’t jump 32.3 feet, right?');
// -> ['The', 'quick', 'brown', 'fox', 'can’t', 'jump', '32.3', 'feet', 'right']
```

## Voglio più controllo

Facilissimo! Possiamo modificare il nostro indice anche per supportare la corrispondenza dei prefissi e la corrispondenza senza distinzione tra maiuscole e minuscole:

```dart
class Post {
  Id? id;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get titleWords => title.split(' ');
}
```

Per impostazione predefinita, Isar memorizzerà le parole come valori hash che sono veloci ed efficienti in termini di spazio. Ma gli hash non possono essere usati per la corrispondenza dei prefissi. Usando `IndexType.value`, possiamo cambiare l'indice per usare invece le parole direttamente. Ci fornisce la clausola where `.titleWordsAnyStartsWith()`:

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

## Ho anche bisogno di `.endsWith()`

Sicuramente! Useremo un trucco per ottenere la corrispondenza `.endsWith()`:

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

Non dimenticare di invertire il finale che vuoi cercare:

```dart
final posts = await isar.posts
  .where()
  .revTitleWordsAnyStartsWith('lcome'.reversed)
  .findAll();
```

## Algoritmi di derivazione

Sfortunatamente, gli indici non supportano la corrispondenza `.contains()` (questo vale anche per altri database). Ma ci sono alcune alternative che vale la pena esplorare. La scelta dipende molto dal tuo utilizzo. Un esempio è l'indicizzazione delle radici delle parole anziché dell'intera parola.

Un algoritmo stemming è un processo di normalizzazione linguistica in cui le forme varianti di una parola sono ridotte a una forma comune:

```
connection
connections
connective          --->   connect
connected
connecting
```

Gli algoritmi più diffusi sono [Algoritmo di stemming di Porter](https://tartarus.org/martin/PorterStemmer/) e [Algoritmi di stemming di Snowball](https://snowballstem.org/algorithms/).

Esistono anche forme più avanzate come [lemmatizzazione](https://en.wikipedia.org/wiki/Lemmatizzazione).

## Algoritmi fonetici

Un [algoritmo fonetico](https://en.wikipedia.org/wiki/Phonetic_algorithm) è un algoritmo per indicizzare le parole in base alla loro pronuncia. In altre parole, ti permette di trovare parole che suonano simili a quelle che stai cercando.

:::warning
La maggior parte degli algoritmi fonetici supporta solo una singola lingua.
:::

### Soundex

[Soundex](https://en.wikipedia.org/wiki/Soundex) è un algoritmo fonetico per indicizzare i nomi in base al suono, come si pronuncia in inglese. L'obiettivo è che gli omofoni siano codificati nella stessa rappresentazione in modo che possano essere abbinati nonostante piccole differenze nell'ortografia. È un algoritmo semplice e ci sono più versioni migliorate.

Usando questo algoritmo, sia `"Robert"` che `"Rupert"` restituiscono la stringa `"R163"` mentre `"Rubin"` restituisce `"R150"`. `"Ashcraft"` e `"Ashcroft"` producono entrambi `"A261"`.

### Double Metaphone

L'algoritmo di codifica fonetica [Double Metaphone](https://en.wikipedia.org/wiki/Metaphone) è la seconda generazione di questo algoritmo. Apporta diversi miglioramenti di progettazione fondamentali rispetto all'algoritmo Metaphone originale.

Double Metaphone spiega varie irregolarità in inglese di origine slava, germanica, celtica, greca, francese, italiana, spagnola, cinese e di altro tipo.
