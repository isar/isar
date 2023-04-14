---
title: Limitationen
---

# Limitationen

Wie du weißt, funktioniert Isar auf Mobilgeräten und Desktops und läuft sowohl auf der VM, als auch im Web. Die beiden Plattformen sind sehr verschieden und haben unterschiedliche Limitationen.

## VM Limitationen

- Nur die ersten 1024 Bytes eines Strings können für eine Präfix-Where-Klausel verwendet werden
- Objekte können höchstens 16MB groß sein

## Web Limitationen

Weil Isar Web auf IndexedDB beruht, gibt es dort mehr Limitationen, aber sie sind kaum zu merken, während du Isar benutzt.

- Synchrone Methoden werden nicht unterstützt
- Zurzeit sind die `Isar.splitWords()`- und `.matches()`-Filter noch nicht implementiert
- Schemaänderungen werden nicht so genau wie in der VM überprüft, also achte darauf die Regeln einzuhalten
- Alle Zahlen-Typen werden als Double (dem einzigen JS Zahlen-Typ) gespeichert, also hat `@Size32` keine Wirkung
- Indizes werden anders dargestellt, wodurch Hash-Indizes nicht weniger Platz benötigen (auch wenn sie gleich funktionieren)
- `col.delete()` und `col.deleteAll()` funktionieren korrekt, aber der Rückgabewert ist nicht richtig
- `col.clear()` setzt den auto-increment-Wert nicht zurück
- `NaN` wird als Wert nicht unterstützt
