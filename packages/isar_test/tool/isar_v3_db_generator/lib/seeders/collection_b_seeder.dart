import 'package:isar/isar.dart';
import 'package:isar_v3_db_generator/collections/collection_b.dart';

const _fieldAValues = [
  'isar',
  '',
  '''Modi vel ut voluptatum maiores et. Aperiam et reiciendis neque architecto expedita quia. Ut quia in recusandae. Rerum assumenda dolorem aut quia similique quasi et tempore. Culpa consequatur omnis rerum. Culpa at sit sequi laborum quia tempora est dolor.
Et deleniti vitae eos consequuntur. Rerum recusandae quae rerum consequatur minima dolore aliquid. Quia veritatis dolores mollitia voluptatum eveniet et tenetur dolorem. Ut rerum ratione ut cum cum. Aut quis consequuntur ad inventore quae dignissimos.
Temporibus non assumenda quia voluptatem. Ut quia architecto reprehenderit. Et doloribus ut vitae quisquam quasi nostrum quia. A officia occaecati aut quo sint qui facere aliquam.
Vel tenetur voluptatibus dolorum dolor quibusdam ut voluptate velit. Qui similique quia sint aspernatur est error nulla perspiciatis. Tempore omnis veniam qui. Repellat adipisci magnam dolore eos. Dignissimos ut neque reiciendis reprehenderit.
Repellat et et labore nisi tempora. Consequuntur odit unde tempore nostrum accusamus consequatur consequatur. Ea repudiandae ullam magnam harum. Voluptatem tempore corporis quod doloribus amet modi. Autem aliquam aliquid nobis. Doloribus natus eos et sit alias.''',
  'Flutter',
  'abcdefghijklmnopqrstuvwxyz',
  'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  '0123456789',
  '!@#\$%^&*()',
  '                                      ',
];

const _fieldBValues = [
  true,
  false,
  true,
  true,
  false,
  false,
  false,
  false,
  true,
  false,
  false,
];

const _fieldCValues = [
  -421,
  124,
  0,
  12454123,
  -125123,
  345,
  42,
  54123,
  314,
  5,
  9,
  -987654321,
  44
];

Future<void> seedCollectionB(Isar isar) async {
  final objects = _generateObjects();

  await isar.writeTxn(() async {
    await isar.collectionBs.putAll(objects);

    for (int i = 0; i < objects.length; i += 7) {
      objects[i].link.value = objects[i % 5];
      objects[i].link.save();
    }
  });
}

List<CollectionB> _generateObjects() {
  final objects = <CollectionB>[];

  for (int objectIndex = 4; objectIndex < 10000; objectIndex++) {
    final fieldAValue = switch (objectIndex % 11 == 0) {
      true => null,
      false => _fieldAValues[objectIndex % _fieldAValues.length],
    };

    final embeddedAValue = _getEmbeddedA(objectIndex);

    final nEmbeddedAValue = switch (objectIndex % 8 == 0) {
      true => null,
      false => _getEmbeddedA(objectIndex),
    };

    final embeddedAListValue = [
      for (int i = 0; i < objectIndex % 5; i++) _getEmbeddedA(objectIndex + i),
    ];

    final embeddedANListValue = switch (objectIndex % 4 == 0) {
      true => null,
      false => [
          for (int i = 0; i < objectIndex % 7; i++)
            _getEmbeddedA(objectIndex + i),
        ],
    };

    final nEmbeddedAListValue = [
      for (int i = 0; i < objectIndex % 6; i++)
        if ((i + objectIndex) % 5 == 0)
          null
        else
          _getEmbeddedA(objectIndex + i),
    ];

    final nEmbeddedANListValue = switch (objectIndex % 9 == 0) {
      true => null,
      false => [
          for (int i = 0; i < objectIndex % 21; i++)
            if (i % 4 == 0) null else _getEmbeddedA(objectIndex + i),
        ],
    };

    objects.add(
      CollectionB(
        id: objectIndex + 1,
        duplicatedId: objectIndex + 1,
        fieldA: fieldAValue,
        embeddedA: embeddedAValue,
        nEmbeddedA: nEmbeddedAValue,
        embeddedAList: embeddedAListValue,
        embeddedANList: embeddedANListValue,
        nEmbeddedAList: nEmbeddedAListValue,
        nEmbeddedANList: nEmbeddedANListValue,
      ),
    );
  }

  return objects;
}

EmbeddedA _getEmbeddedA(
  int objectIndex, {
  int depth = 0,
}) {
  final fieldAValue = objectIndex % 17 == 0
      ? null
      : _fieldAValues[objectIndex % _fieldAValues.length];

  final fieldBValue = objectIndex % 22 == 0
      ? null
      : _fieldBValues[objectIndex % _fieldBValues.length];

  final embeddedAValue = depth >= 3 || objectIndex % 17 == 0
      ? null
      : _getEmbeddedA(objectIndex + 1, depth: depth + 1);

  final embeddedBValue =
      objectIndex % 9 == 0 ? null : _getEmbeddedB(objectIndex);

  final embeddedBNListValue = switch (objectIndex % 11 == 0) {
    true => null,
    false => [
        for (int index = 0; index < objectIndex % 12; index++)
          _getEmbeddedB(objectIndex + index),
      ],
  };

  final nEmbeddedBNListValue = switch (objectIndex % 7 == 0) {
    true => null,
    false => [
        for (int index = 0; index < objectIndex % 27; index++)
          if (index % 3 == 0 && objectIndex & 7 == 0)
            null
          else
            _getEmbeddedB(objectIndex + index),
      ],
  };

  return EmbeddedA(
    fieldA: fieldAValue,
    fieldB: fieldBValue,
    embeddedA: embeddedAValue,
    embeddedB: embeddedBValue,
    embeddedBNList: embeddedBNListValue,
    nEmbeddedBNList: nEmbeddedBNListValue,
  );
}

EmbeddedB _getEmbeddedB(int objectIndex) {
  final fieldAValue = objectIndex % 12 == 0
      ? null
      : _fieldAValues[objectIndex % _fieldAValues.length];

  final fieldCValue = objectIndex % 21 == 0
      ? null
      : _fieldCValues[objectIndex % _fieldCValues.length];

  return EmbeddedB(
    fieldA: fieldAValue,
    fieldC: fieldCValue,
  );
}
