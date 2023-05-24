import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:isar_test/src/twitter/tweet.dart';
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

void main() {
  group(
    'Twitter Stress',
    () {
      late Isar isar;

      setUpAll(() async {
        isar = openTempIsar(
          [TweetSchema],
          maxSizeMiB: 1500,
          closeAutomatically: false,
        );

        for (var i = 0; i < 100; i++) {
          final tweets = await downloadTweets(isar.directory, i);
          isar.writeTxn((isar) {
            isar.tweets.putAll(tweets);
          });
        }
      });

      tearDownAll(() => isar.close(deleteFromDisk: true));

      isarTest('Aggregation', () {
        expect(isar.tweets.where().count(), 500000);
        expect(isar.tweets.where().favoriteCountProperty().sum(), 307278);
        expect(isar.tweets.where().favoriteCountProperty().average(), 0.614556);
        expect(isar.tweets.where().favoriteCountProperty().min(), 0);
        expect(isar.tweets.where().favoriteCountProperty().max(), 2317);

        expect(
          isar.tweets.where().createdAtProperty().min()!.toUtc(),
          DateTime.utc(2015, 4, 23, 9, 10, 58),
        );
        expect(
          isar.tweets.where().createdAtProperty().max()!.toUtc(),
          DateTime.utc(2015, 6, 18, 10, 1, 57),
        );
      });

      isarTest('Distinct', () {
        expect(isar.tweets.where().distinctByLang().langProperty().findAll(), [
          'en', 'it', 'de', 'fr', 'pt', 'und', 'es', 'qme', 'qht', //
          'hu', 'ja', 'et', 'tl', 'eu', 'pl', 'ht', 'in', 'lt', 'ar', //
          'ca', 'ru', 'el', 'ro', 'uk', 'sl', 'cy', 'no', 'nl', 'sv', //
          'fi', 'zh', 'tr', 'cs', 'lv', 'hi', 'is', 'da', 'bg', 'vi', //
          'ko', 'fa', 'th', 'sr', 'ne', 'ur', 'iw'
        ]);
      });

      isarTest('Sort by', () {
        final query = isar.tweets
            .where()
            .sortByFavoriteCount()
            .thenByLang()
            .thenByFullText()
            .idStrProperty()
            .findAll(limit: 5);
        expect(query, [458669, 441027, 368275, 222021, 368289]);
      });

      isarTest('Query', () {
        final complexQuery = isar.tweets
            .where()
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
            /*.entities(
              (q) => q
                  .hashtagsLengthGreaterThan(0)
                  .urlsLengthGreaterThan(0)
                  .mediaLengthGreaterThan(0)
                  .userMentionsLengthGreaterThan(0),
            )*/
            .idStrProperty();
        expect(complexQuery, [
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
