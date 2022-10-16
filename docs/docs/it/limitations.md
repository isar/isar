# Limitazioni

Come sapete, Isar funziona su dispositivi mobili e desktop in esecuzione su VM oltre che su Web. Entrambe le piattaforme sono molto diverse e hanno limitazioni diverse.

## Limitazioni VM

- Solo i primi 1024 byte di una stringa possono essere usati per un prefisso clausola-where
- Gli oggetti possono avere una dimensione di soli 16 MB

## Limitazioni Web

Poiché Isar Web si basa su IndexedDB, ci sono più limitazioni ma sono appena percettibili durante l'utilizzo di Isar.

- I metodi sincroni non sono supportati
- Attualmente, i filtri `Isar.splitWords()` e `.matches()` non sono ancora implementati
- Le modifiche allo schema non vengono controllate rigorosamente come nella VM, quindi fai attenzione a rispettare le regole
- Tutti i tipi di numeri sono memorizzati come double (l'unico tipo di numero js) quindi `@Size32` non ha alcun effetto
- Gli indici sono rappresentati in modo diverso, quindi gli indici hash non utilizzano meno spazio (funzionano comunque allo stesso modo)
- `col.delete()` e `col.deleteAll()` funzionano correttamente ma il valore restituito non è corretto
- `col.clear()` non reimposta il valore di incremento automatico
- `NaN` non è supportato come valore
