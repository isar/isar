# Limitaciones

Como ya sabes, Isar funciona en dispositivos móbiles y de escritorio corriendo en la VM así como en la web. Ambas plataformas son muy diferentes y tienen distintas limitaciones.

## Limitaciones de la VM

- Para consultas `where` de prefijo sólo se pueden usar los primeros 1024 bytes
- Los objetos pueden ser de 16MB en tamaño como máximo

## Limitaciones de la Web

Dado que Isar Web confía en IndexedDB, hay más limitaciones pero apenas son notadas mientras se usa Isar.

- No hay soporte para métodos síncronos
- Actualmente, los filtros `Isar.splitWords()` y `.matches()` aún no están implementados
- Los cambios en los esquemas no son estrechamente verificados como en la VM entonces sé cuidadoso de cumplir con las reglas
- Todos los tipos numéricos se almacenan como `double` (el único tipo numérico de js) por lo tanto `@Size32` no tiene efecto
- Lo índices se representan de forma diferente entonces los índices hash no usan menos espacio (pero funcionan de la misma manera)
- `col.delete()` y `col.deleteAll()` funcionan correctamente pero el valor retornado es incorrecto
- `col.clear()` no resetea el valor de auto incrementado
- `NaN` no está soportado como valor
