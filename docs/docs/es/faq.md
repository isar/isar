---
title: FAQ
---

# Preguntas frecuentes

Una colección aleatoria de preguntas frecuentes sobre Isar y bases de datos en Flutter.

### Porqué necesito una base de datos?

> Estoy almacenando mis datos es una base datos en mi backend, porqué necesito Isar?.

Incluso hoy en día, es muy común no tener conexión a internet si estás en el subterráneo o en un avión o si visitaste a tu abuela, que no tiene WiFi y muy mala señal de celular. No deberías dejar que la mala conexión afectua a tu aplicación!

### Isar versus Hive

La respuesta es fácil: Isar [inició como un reemplazo para Hive](https://github.com/hivedb/hive/issues/246) y está en un estado de madurez tal que se recomienda siempre usar Isar en lugar de Hive.

### Cláusulas `where`?!

> Porqué **_YO_** tengo que elejir qué índice usar?

Existen muchas razones. Muchas base de datos utilizan heurística para elegir el mejor índice para una determinada consulta. La base de datos necesita recolectar datos de uso adicionales (-> overhead) y aún así podría elegir un índice incorrecto. Además crear la consulta es más lento.

Nadie conoce tus datos mejor que tú, el desarrollador. Entonces tú puedes elegir el índice óptimo y decidir por ejemplo si quieres usar un índice para consultas u ordenamiento.

### Tengo que usar índices / cláusulas `where`?

No! Isar es lo suficientemente rápida si solo quieres confiar en filtros.

### Isar es lo suficientemente rápida?

Isar está entre las bases de datos más rápidas para dispositivos móbiles, por lo que debería ser lo suficientemente rápida para las mayoría de los casos de uso. Si tienes problemas de rendimiento, hay posibilidades que estés haciendo algo mal.

### Isar incrementa el tamaño de mi aplicación?

Un poco, sí. Isar incrementará el tamaño de descarga de tu aplicaicón alrededor de 1 - 1.5 MB. Isar Web agrega solo algunos KB.

### La documentación es incorrecta / hay un error de ortografía.

Oh no, lo siento. Por favor [apunta el problema](https://github.com/isar/isar/issues/new/choose) o, mejor aún, un PR para solucionarlo! 💪.
