import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

Future<List<Tweet>> downloadTweets(String dir, int index) async {
  final i = index < 10 ? '0$index' : '$index';
  final file = File('$dir/tweets$i.json');

  late String jsonStr;
  if (file.existsSync()) {
    jsonStr = await file.readAsString();
  } else {
    final uri = Uri.parse(
      'https://raw.githubusercontent.com/isar/testdata/main/twitter$i.json',
    );
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();
    jsonStr = await response.transform(utf8.decoder).join();
    await file.writeAsString(jsonStr);
  }

  final json = jsonDecode(jsonStr) as List<dynamic>;
  return json.map((e) => Tweet.fromJson(e as Map<String, dynamic>)).toList();
}

void main() async {
  group(
    'Twitter Stress',
    () {
      late Isar isar;
      late IsarCollection<Tweet> col;

      setUpAll(() async {
        isar = await openTempIsar(
          [TweetSchema],
          closeAutomatically: false,
        );
        col = isar.collection<Tweet>();

        for (var i = 0; i < 100; i++) {
          final tweets = await downloadTweets(isar.directory!, i);
          await isar.tWriteTxn(() async {
            await col.tPutAll(tweets);
          });
        }
      });

      tearDownAll(() => isar.close(deleteFromDisk: true));

      isarTest('Aggregation', () async {
        expect(await col.where().tCount(), 500000);
        expect(await col.where().favoriteCountProperty().tSum(), 307278);
        expect(await col.where().favoriteCountProperty().tAverage(), 0.614556);
        expect(await col.where().favoriteCountProperty().tMin(), 0);
        expect(await col.where().favoriteCountProperty().tMax(), 2317);

        expect(
          (await col.where().createdAtProperty().tMin())!.toUtc(),
          DateTime.utc(2015, 4, 23, 9, 10, 58),
        );
        expect(
          (await col.where().createdAtProperty().tMax())!.toUtc(),
          DateTime.utc(2015, 6, 18, 10, 1, 57),
        );
      });

      isarTest('Distinct', () async {
        await qEqualSet(col.where().distinctByLang().langProperty(), [
          'en', 'it', 'de', 'fr', 'pt', 'und', 'es', 'qme', 'qht', //
          'hu', 'ja', 'et', 'tl', 'eu', 'pl', 'ht', 'in', 'lt', 'ar', //
          'ca', 'ru', 'el', 'ro', 'uk', 'sl', 'cy', 'no', 'nl', 'sv', //
          'fi', 'zh', 'tr', 'cs', 'lv', 'hi', 'is', 'da', 'bg', 'vi', //
          'ko', 'fa', 'th', 'sr', 'ne', 'ur', 'iw'
        ]);
      });

      isarTest('Sort by', () async {
        final query = col
            .where()
            .sortByFavoriteCount()
            .thenByLang()
            .thenByFullText()
            .limit(5)
            .isarIdProperty();
        await qEqual(query, [458669, 441027, 368275, 222021, 368289]);
      });

      isarTest('Query', () async {
        final complexQuery = col
            .filter()
            .not()
            .group(
              (q) => q
                  .placeIsNull()
                  .or()
                  .entitiesIsNull()
                  .or()
                  .coordinatesIsNull(),
            )
            .not()
            .inReplyToScreenNameIsNull()
            .entities(
              (q) => q
                  .hashtagsLengthGreaterThan(0)
                  .urlsLengthGreaterThan(0)
                  .mediaLengthGreaterThan(0)
                  .userMentionsLengthGreaterThan(0),
            )
            .idStrProperty();
        await qEqual(complexQuery, [
          '592572613462986752',
          '596576703285174272',
          '597445810696126464',
          '602584278883553280'
        ]);
      });
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
