---
title: Utilizzo multi-isolate
---

# Utilizzo multi-isolate

Invece dei thread, tutto il codice Dart viene eseguito all'interno degli isolate. Ogni isolate ha il proprio heap di memoria, assicurando che nessuno degli stati in un isolate sia accessibile da qualsiasi altro isolate.

È possibile accedere a Isar da più isolate contemporaneamente e anche gli osservatori lavorano tra gli isolate. In questa ricetta vedremo come utilizzare Isar in un ambiente multiisolate.

## Quando utilizzare più isolate

Le transazioni Isar vengono eseguite in parallelo anche se eseguite nello stesso isolate. In alcuni casi, è comunque vantaggioso accedere all'Isar da più isolate.

Il motivo è che Isar impiega parecchio tempo a codificare e decodificare i dati da e verso gli oggetti Dart. Puoi pensarlo come codifica e decodifica JSON (solo più efficiente). Queste operazioni vengono eseguite all'interno dell'isolate da cui si accede ai dati e bloccano naturalmente altro codice nell'isolate. In altre parole: Isar esegue parte del lavoro nel tuo isolate Dart.

Se hai solo bisogno di leggere o scrivere poche centinaia di oggetti contemporaneamente, farlo nell'isolate dell'interfaccia utente non è un problema. Ma per transazioni enormi o se il thread dell'interfaccia utente è già occupato, dovresti considerare l'utilizzo di un isolate separato.

## Esempio

La prima cosa che dobbiamo fare è aprire l'Isar nel nuovo isolate. Poiché l'istanza di Isar è già aperta nell'isolate principale, `Isar.open()` restituirà la stessa istanza.

:::warning
Assicurati di fornire gli stessi schemi dell'isolate principale. In caso contrario, riceverai un errore.
:::

`compute()` avvia un nuovo isolate in Flutter ed esegue la funzione data in esso.

```dart
void main() {
  // Open Isar in the UI isolate
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [MessageSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  // listen to changes in the database
  isar.messages.watchLazy(() {
    print('omg the messages changed!');
  });

  // start a new isolate and create 10000 messages
  compute(createDummyMessages, 10000).then(() {
    print('isolate finished');
  });

  // after some time:
  // > omg the messages changed!
  // > isolate finished
}

// function that will be executed in the new isolate
Future createDummyMessages(int count) async {
  // we don't need the path here because the instance is already open
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [PostSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Message $i');
  // we use a synchronous transactions in isolates
  isar.writeTxnSync(() {
    isar.messages.insertAllSync(messages);
  });
}
```

Ci sono alcune cose interessanti da notare nell'esempio sopra:

- `isar.messages.watchLazy()` viene chiamato nell'isolate dell'interfaccia utente e viene notificato delle modifiche da un altro isolate.
- Le istanze sono referenziate per nome. Il nome predefinito è `default`, ma in questo esempio lo impostiamo su `myInstance`.
- Abbiamo utilizzato una transazione sincrona per creare i messaggi. Bloccare il nostro nuovo isolate non è un problema e le transazioni sincrone sono un po' più veloci.
