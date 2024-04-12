---
title: Início rápido
---

# Início rápido

Caramba, você está aqui! Vamos começar a usar o banco de dados Flutter mais legal que existe...

Seremos curtos em palavras e rápidos em código neste início rápido.

## 1. Adicionar dependências

Antes que a diversão comece, precisamos adicionar alguns pacotes ao `pubspec.yaml`. Podemos usar o pub para fazer o trabalho complexo para nós.

```bash
dart pub add isar:^0.0.0-placeholder isar_flutter_libs:^0.0.0-placeholder --hosted-url=https://pub.isar-community.dev
```

## 2. Anotar classes

Anote suas coleções de classes com `@collection` e escolha um campo 'Id'.

```dart
import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  late int id;

  String? name;

  int? age;
}
```

Os IDs identificam exclusivamente objetos em uma coleção e permitem que você os encontre novamente mais tarde.

## 3. Executar gerador de código

Execute o seguinte comando para iniciar o `build_runner`:

```
dart run build_runner build
```

## 4. Abrir instância Isar

Abra uma nova instância Isar e passe todos os seus esquemas de coleção. Opcionalmente, você pode especificar um nome de instância e um diretório.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.openAsync(
  schemas: [UserSchema],
  directory: dir.path,
);
```

## 5. Escrever e ler

Depois que sua instância estiver aberta, você poderá começar a usar as coleções.

Todas as operações básicas de CRUD estão disponíveis via `IsarCollection`.

```dart
final newUser = User()
  ..id = isar!.users.autoIncrement()
  ..name = 'Jane Doe'
  ..age = 36;

await isar!.writeAsync((isar) {
  return isar.users.put(newUser); // inserir & atualizar
});

final existingUser = isar!.users.get(newUser.id); // ler

if (existingUser != null) {
  await isar!.writeAsync((isar) {
    return isar.users.delete(existingUser.id); // apagar
  });
}
```

## Outros recursos

Você é um aprendiz visual? Confira estes vídeos para começar com Isar:
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/CwC9-a9hJv4" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/videoseries?list=PLKKf8l1ne4_hMBtRykh9GCC4MMyteUTyf" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/pdKb8HLCXOA " title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
