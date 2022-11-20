---
title: Schema
---

# Schema

Quando utilizzi Isar per archiviare i dati della tua app, hai a che fare con le raccolte. Una raccolta è come una tabella di database nel database Isar associato e può contenere solo un singolo tipo di oggetto Dart. Ogni oggetto della raccolta rappresenta una riga di dati nella raccolta corrispondente.

Una definizione di raccolta è chiamata "schema". Isar Generator farà il lavoro pesante per te e genererà la maggior parte del codice necessario per utilizzare la raccolta.

## Anatomia di una collezione

Definisci ogni collezione Isar annotando una classe con `@collection` o `@Collection()`. Una raccolta Isar include campi per ogni colonna nella tabella corrispondente nel database, incluso uno che comprende la chiave primaria.

Il codice seguente è un esempio di una raccolta semplice che definisce una tabella `User` con colonne per ID, nome e cognome:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
Per rendere permanente un campo, Isar deve avervi accesso. Puoi assicurarti che Isar abbia accesso a un campo rendendolo pubblico o fornendo metodi getter e setter.
:::

Ci sono alcuni parametri opzionali per personalizzare la collezione:

| Config        | Description                                                                                                                      |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Controlla se i campi delle classi padre e dei mixin verranno archiviati in Isar. Abilitato per impostazione predefinita.         |
| `accessor`    | Consente di rinominare la funzione di accesso predefinita della raccolta (ad esempio `isar.contacts` per la raccolta `Contact`). |
| `ignore`      | Consente di ignorare determinate proprietà. Questi sono anche rispettati per le super classi.                                    |

### Isar ID

Ogni classe di raccolta deve definire una proprietà id con il tipo 'Id' che identifica in modo univoco un oggetto. `Id` è solo un alias per `int` che permette a Isar Generator di riconoscere la proprietà id.

Isar indicizza automaticamente i campi id, il che ti consente di ottenere e modificare gli oggetti in base al loro id in modo efficiente.

Puoi impostare gli ID da solo o chiedere a Isar di assegnare un ID con incremento automatico. Se il campo `id` è `null` e non `finale`, Isar assegnerà un id di autoincremento. Se vuoi un ID di incremento automatico non annullabile, puoi usare `Isar.autoIncrement` invece di `null`.

:::tip
Gli ID di incremento automatico non vengono riutilizzati quando un oggetto viene eliminato. L'unico modo per reimpostare gli ID di incremento automatico è cancellare il database.
:::

### Rinominare raccolte e campi

Per impostazione predefinita, Isar utilizza il nome della classe come nome della raccolta. Allo stesso modo, Isar utilizza i nomi dei campi come nomi di colonne nel database. Se desideri che una raccolta o un campo abbia un nome diverso, aggiungi l'annotazione `@Name`. L'esempio seguente mostra i nomi personalizzati per la raccolta e i campi:

```dart
@collection
@Name("User")
class MyUserClass1 {

  @Name("id")
  Id myObjectId;

  @Name("firstName")
  String theFirstName;

  @Name("lastName")
  String familyNameOrWhatever;
}
```

Soprattutto se vuoi rinominare i campi o le classi Dart che sono già archiviati nel database, dovresti considerare di usare l'annotazione `@Name`. In caso contrario, il database eliminerà e ricreerà il campo o la raccolta.

### Ignorare i campi

Isar mantiene tutti i campi pubblici di una classe di raccolta. Annotando una proprietà o un getter con `@ignore`, puoi escluderlo dalla persistenza, come mostrato nel seguente frammento di codice:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;

  @ignore
  String? password;
}
```

Nei casi in cui una raccolta eredita i campi da una raccolta padre, di solito è più semplice utilizzare la proprietà `ignore` dell'annotazione `@Collection`:

```dart
@collection
class User {
  Image? profilePicture;
}

@Collection(ignore: {'profilePicture'})
class Member extends User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

Se una collezione contiene un campo con un tipo non supportato da Isar, devi ignorare il campo.

:::warning
Tieni presente che non è buona norma memorizzare informazioni in oggetti Isar che non sono persistenti.
:::

## Tipi supportati

Isar supporta i seguenti tipi di dati:

- `bool`
- `byte`
- `short`
- `int`
- `float`
- `double`
- `DateTime`
- `String`
- `List<bool>`
- `List<byte>`
- `List<short>`
- `List<int>`
- `List<float>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

Inoltre, sono supportati oggetti incorporati ed enumerazioni. Tratteremo quelli di seguito.

## byte, short, float

Per molti casi d'uso, non è necessario l'intero intervallo di un intero o doppio a 64 bit. Isar supporta tipi aggiuntivi che consentono di risparmiare spazio e memoria durante la memorizzazione di numeri più piccoli.

| Tipo       | Dim. in bytes | Range                                                   |
| ---------- | ------------- | ------------------------------------------------------- |
| **byte**   | 1             | 0 to 255                                                |
| **short**  | 4             | -2,147,483,647 to 2,147,483,647                         |
| **int**    | 8             | -9,223,372,036,854,775,807 to 9,223,372,036,854,775,807 |
| **float**  | 4             | -3.4e38 to 3.4e38                                       |
| **double** | 8             | -1.7e308 to 1.7e308                                     |

I tipi di numeri aggiuntivi sono solo alias per i tipi Dart nativi, quindi usare `short`, ad esempio, funziona come usare `int`.

Ecco una raccolta di esempio contenente tutti i tipi di cui sopra:

```dart
@collection
class TestCollection {
  Id? id;

  late byte byteValue;

  short? shortValue;

  int? intValue;

  float? floatValue;

  double? doubleValue;
}
```

Tutti i tipi di numeri possono essere utilizzati anche negli elenchi. Per memorizzare i byte, dovresti usare `List<byte>`.

## Tipi annullabili

Comprendere come funziona l'annullamento dei valori in Isar è essenziale: i tipi numerici **NON** hanno una rappresentazione `null` dedicata. Viene invece utilizzato un valore specifico:

| Type       | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN`  |
| **double** |  `double.NaN` |

`bool`, `String` e `List` hanno una rappresentazione `null` separata.

Questo comportamento consente miglioramenti delle prestazioni e ti consente di modificare liberamente la capacità di Null dei tuoi campi senza richiedere la migrazione o codice speciale per gestire i valori `null`.

:::warning
Il tipo `byte` non supporta valori nulli.
:::

## DateTime

Isar non memorizza le informazioni sul fuso orario delle tue date. Invece, converte `DateTime`s in UTC prima di archiviarli. Isar restituisce tutte le date nell'ora locale.

I `DateTime`s vengono archiviati con una precisione di microsecondi. Nei browser è supportata solo la precisione in millisecondi a causa delle limitazioni di JavaScript.

## Enum

Isar consente di archiviare e utilizzare le enumerazioni come altri tipi di Isar. Devi scegliere, tuttavia, come Isar deve rappresentare le enumerazioni sul disco. Isar supporta quattro diverse strategie:

| EnumType    | Descrizione                                                                                                    |
| ----------- | -------------------------------------------------------------------------------------------------------------- |
| `ordinal`   | TL'indice dell'enum è memorizzato come `byte`. Questo è molto efficiente ma non consente enumerazioni nullable |
| `ordinal32` | L'indice dell'enumerazione viene archiviato come `short` (4-byte integer).                                     |
| `name`      | Il nome dell'enumerazione viene memorizzato come `String`.                                                     |
| `value`     | Per recuperare il valore dell'enumerazioni viene utilizzata una proprietà personalizzata.                      |

:::warning
`ordinal` e `ordinal32` dipendono dall'ordine dei valori dell'enumerazione. Se modifichi l'ordine, i database esistenti restituiranno valori errati.
:::

Diamo un'occhiata a un esempio per ciascuna strategia.

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // same as EnumType.ordinal
  late TestEnum byteIndex; // cannot be nullable

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // cannot be nullable

  @Enumerated(EnumType.ordinal32)
  TestEnum? shortIndex;

  @Enumerated(EnumType.name)
  TestEnum? name;

  @Enumerated(EnumType.value, 'myValue')
  TestEnum? myValue;
}

enum TestEnum {
  first(10),
  second(100),
  third(1000);

  const TestEnum(this.myValue);

  final short myValue;
}
```

Naturalmente, Enums può essere utilizzato anche nelle liste.

## Oggetti incorporati

Spesso è utile avere oggetti nidificati nel modello di raccolta. Non c'è limite a quanto in profondità puoi annidare gli oggetti. Tieni presente, tuttavia, che l'aggiornamento di un oggetto profondamente nidificato richiederà la scrittura dell'intero albero degli oggetti nel database.

```dart
@collection
class Email {
  Id? id;

  String? title;

  Recepient? recipient;
}

@embedded
class Recepient {
  String? name;

  String? address;
}
```

Gli oggetti incorporati possono essere nulli ed estendere altri oggetti. L'unico requisito è che siano annotati con `@embedded` e abbiano un costruttore predefinito senza parametri richiesti.
