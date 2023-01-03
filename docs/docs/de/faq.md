---
title: FAQ
---

# Häufig gestellte Fragen

Eine zufällige Zusammenstellung an häufig gestellten Fragen zu Isar und Flutter-Datenbanken.

### Warum brauche ich eine Datenbank?

> Ich speichere meine Daten in einer Backend-Datenbank, warum benötige ich Isar?

Sogar heute kommt es vor, dass du keine Internetverbindung hast, wenn du in einer U-Bahn, einem Flugzeug oder zu Besuch bei deiner Oma bist, die kein WLAN und einen sehr schlechten Mobilfunkempfang hat. Du solltest deine App nicht durch schlechte Verbindung lahmlegen lassen.

### Isar vs Hive

Die Antwort ist leicht: Isar wurde [als Ersatz für Hive begonnen](https://github.com/hivedb/hive/issues/246) und ist nun an einem Punkt, wo ich immer empfehlen würde, Isar statt Hive zu benutzen.

### Where-Klauseln?!

> Warum muss **_ich_** wählen, welcher Index genutzt wird?

Es gibt mehrere Gründe. Viele Datenbanken benutzen Heuristik um den besten Index für eine bestimmte Abfrage zu nutzen. Die Datenbank muss zusätzliche Nutzungsdaten sammeln (-> Overhead) und verwendet möglicherweise immer noch den falschen Index. Es dauert dadurch auch länger eine Abfrage zu starten.

Niemand kennt deine Daten besser, als du, der Entwickler. Also kannst du den besten Index wählen und z.B. entscheiden, ob du einen Index zum Abfragen oder Sortieren verwenden willst.

### Muss ich Indizes / Where-Klauseln benutzen?

Nö! Isar ist vermutlich schnell genug, auch wenn du nur Filter verwendest.

### Ist Isar schnell genug?

Isar ist unter den schnellsten Datenbanken für Mobilgeräte, also sollte es in den meisten Fällen schnellgenug sein. Wenn du auf Leistungsprobleme stößt, besteht die Möglichkeit, dass du was falschmachst.

### Steigert Isar die Größe meiner App?

Ja, ein bisschen. Isar wird die Download-Größe deiner App um 1 - 1,5 MB erhöhen. Isar Web fügt nur wenige KB hinzu.

### Die Docs sind falsch / Da ist ein Tippfehler

Oh nein, sorry. Bitte [öffne ein Issue](https://github.com/isar/isar/issues/new/choose), oder noch besser, mach einen PR um den Fehler zu beheben 💪.
