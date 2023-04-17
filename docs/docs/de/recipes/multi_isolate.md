---
title: Nutzung von mehreren Isolates
---

# Nutzung von mehreren Isolates

Statt in Threads, läuft der gesamte Dart-Code innerhalb von Isolates. Jeder Isolate hat einen eigenen Memory-Heap, was dafür sorgt, dass der Status eines Isolates von keinem anderen Isolate erreichbar ist.

Auf Isar kann von mehreren Isolates gleichzeitig zugegriffen werden und sogar Watcher funktionieren über Isolates hinweg. In diesem Rezept werden wir prüfen, wie man Isar in einem Umfeld mit mehreren Isolates nutzt.

## Wann man mehrere Isolates benutzt

Isar-Transaktionen werden parallel ausgeführt, auch wenn sie im gleichen Isolate laufen. In manchen Fällen ist es dennoch von Vorteil von mehreren Isolates auf Isar zuzugreifen.

Der Grund ist, dass Isar einige Zeit benötigt, um Daten von und zu Dart-Objekten zu codieren und decodieren. Du kannst es dir vorstellen, als würdest du JSON codieren und decodieren (nur effizienter). Diese Operationen laufen innerhalb des Isolates, von dem auf die Daten zugegriffen wird und blockieren daher natürlich anderen Code in dem Isolate. In anderen Worten: Isar führt einen Teil der Arbeit in deinem Dart-Isolate aus.

Wenn du nur ein paar hundert Objekte gleichzeitig lesen oder schreiben musst, ist es kein Problem, das im UI-Isolate zu tun. Aber für riesige Transaktionen oder wenn dein UI-Thread schon zu tun hat, solltest du überlegen ein seperates Isolate zu verwenden.

## Beispiel

Die erste Sache, die wir machen müssen, ist Isar in einem neuen Isolate zu öffnen. Weil eine Instanz von Isar schon im zentralen Isolate offen ist, wird `Isar.open()` diese Instanz zurückgeben.

:::warning
Stelle sicher, dass du die gleichen Schemas wie im zentralen Isolate zur Verfügung stellst. Sonst wirst du einen Fehler erhalten.
:::

`compute()` startet ein neues Isolate in Flutter und führt die angegebene Funktion in ihm aus.

```dart
void main() {
  // Isar im UI-Isolate öffnen
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [MessageSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  // Auf Änderungen in der Datenbank warten
  isar.messages.watchLazy(() {
    print('omg the messages changed!');
  });

  // Startet ein neues Isolate und erzeugt 10000 Nachrichten
  compute(createDummyMessages, 10000).then(() {
    print('isolate finished');
  });

  // Nach einiger Zeit:
  // > omg the messages changed!
  // > isolate finished
}

// Funktion, die im neuen Isolate ausgeführt werden soll
Future createDummyMessages(int count) async {
  // Wir benötigen hier keinen Pfad, weil die Instanz schon offen ist
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [PostSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Message $i');
  // Wir benutzen synchrone Transaktionen in Isolates
  isar.writeTxnSync(() {
    isar.messages.insertAllSync(messages);
  });
}
```

Es gibt ein paar interessante Dinge, die in dem Beispiel von eben auffallen:

- `isar.messages.watchLazy()` wird im UI-Isolate aufgerufen und wird über Änderungen durch ein anderes Isolate benachrichtigt.
- Instanzen werden über den Namen referenziert. Der Standardname ist `default`, aber in diesem Beispiel haben wir ihn auf `myInstance` gesetzt.
- Wir haben eine synchrone Transaktion benutzt, um die Nachrichten zu erzeugen. Unser neues Isolate zu blockieren ist kein Problem und synchrone Transaktionen sind ein bisschen schneller.
