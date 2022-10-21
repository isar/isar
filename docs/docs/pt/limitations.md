# Limitações

Como você sabe, o Isar funciona em dispositivos móveis e desktops executados na VM e na Web. Ambas as plataformas são muito diferentes e têm limitações diferentes.

## Limitações da VM

- Apenas os primeiros 1024 bytes de uma string podem ser usados ​​para um prefixo where-clause
- Objetos podem ter apenas 16 MB de tamanho

## Limitações da Web

Como o Isar Web depende do IndexedDB, há mais limitações, mas elas são quase imperceptíveis ao usar o Isar.

- Métodos síncronos não são suportados
- Atualmente, os filtros `Isar.splitWords()` e `.matches()` ainda não estão implementados
- As alterações de esquema não são tão rigorosamente verificadas quanto na VM, portanto, tenha cuidado para cumprir as regras
- Todos os tipos de números são armazenados como double (o único tipo de número js) para que `@Size32` não tenha efeito
- Os índices são representados de forma diferente para que os índices de hash não usem menos espaço (eles ainda funcionam da mesma forma)
- `col.delete()` e `col.deleteAll()` funcionam corretamente, mas o valor de retorno não está correto
- `col.clear()` não redefine o valor de incremento automático
- `NaN` não é suportado como valor