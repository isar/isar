---
title: QF
---

# Questões Frequentes

Uma coleção aleatória de questões frequentes sobre bancos de dados Isar e Flutter.

### Por que preciso de um banco de dados?

> Armazeno meus dados em um banco de dados backend, por que preciso do Isar?.

Ainda hoje, é muito comum não ter conexão de dados se você estiver no metrô ou no avião ou se for visitar sua avó, que não tem WiFi e o sinal do celular é muito ruim. Você não deve deixar uma conexão ruim paralisar seu aplicativo!

### Isar vs Hive

A resposta é fácil: o Isar foi [iniciado como substituto do Hive](https://github.com/hivedb/hive/issues/246) e agora está em um estado em que recomendo sempre usar o Isar sobre o Hive.

### Cláusulas Where?!

> Por que **_I_** precisa escolher qual índice usar?

Existem várias razões. Muitos bancos de dados usam heurísticas para escolher o melhor índice para uma determinada consulta. O banco de dados precisa coletar dados de uso adicionais (-> sobrecarga) e ainda pode escolher o índice errado. Também torna a criação de uma consulta mais lenta.

Ninguém conhece seus dados melhor do que você, o desenvolvedor. Assim, você pode escolher o índice ideal e decidir, por exemplo, se deseja usar um índice para consulta ou classificação.

### Eu tenho que usar índices / cláusulas where?

Não! Isar provavelmente é rápido o suficiente se você confiar apenas em filtros.

### Isar é rápido o suficiente?

O Isar está entre os bancos de dados mais rápidos para dispositivos móveis, portanto, deve ser rápido o suficiente para a maioria dos casos de uso. Se você tiver problemas de desempenho, é provável que esteja fazendo algo errado.

### O Isar aumenta o tamanho do meu aplicativo?

Um pouco, sim. O Isar aumentará o tamanho do download do seu aplicativo em cerca de 1 a 1,5 MB. Isar Web adiciona apenas alguns KB.

### Os documentos estão incorretos/há um erro de digitação.

Ah não, desculpe. Por favor [abra um issue](https://github.com/isar/isar/issues/new/choose) ou, melhor ainda, um PR para corrigi-lo 💪.
