---
title: FAQ
---

# Domande frequenti

Una raccolta casuale di domande frequenti sui database Isar e Flutter.

### Perché ho bisogno di un database?

> Conservo i miei dati in un database back-end, perché ho bisogno di Isar?.

Ancora oggi è molto comune non avere connessione dati se sei in metropolitana o in aereo o se vai a trovare tua nonna, che non ha WiFi e un segnale cellulare pessimo. Non dovresti lasciare che una cattiva connessione paralizzi la tua app!

### Isar vs Hive

La risposta è semplice: Isar è stato [nato come sostituto di Hive](https://github.com/hivedb/hive/issues/246) e ora si trova in uno stato in cui consiglio di utilizzare sempre Isar invece di Hive.

### Dove sono le clausole?!

> Perché **_Io_** devo scegliere quale indice utilizzare?

Ci sono più ragioni. Molti database utilizzano l'euristica per scegliere l'indice migliore per una determinata query. Il database deve raccogliere dati di utilizzo aggiuntivi (-> sovraccarico) e potrebbe comunque scegliere l'indice errato. Inoltre, rende più lenta la creazione di una query.

Nessuno conosce i tuoi dati meglio di te, lo sviluppatore. Quindi puoi scegliere l'indice ottimale e decidere, ad esempio, se desideri utilizzare un indice per eseguire query o ordinare.

### Devo usare gli indici oppure le clausole where?

No! Molto probabilmente Isar è abbastanza veloce se ti affidi solo ai filtri.

### Isar è abbastanza veloce?

Isar è tra i database più veloci per dispositivi mobili, quindi dovrebbe essere abbastanza veloce per la maggior parte dei casi d'uso. Se riscontri problemi di prestazioni, è probabile che tu stia facendo qualcosa di sbagliato.

### Isar aumenta le dimensioni della mia app?

Un po', sì. Isar aumenterà la dimensione del download della tua app di circa 1 - 1,5 MB. Isar Web aggiunge solo pochi KB.

### La documentazione non è corretta / c'è un errore di battitura.

Oh no, mi dispiace. Per favore [apri un problema](https://github.com/isar/isar/issues/new/choose) o, ancora meglio, un PR per risolverlo 💪.
