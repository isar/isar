import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:test/test.dart';
import 'package:dartx/dartx.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';
import 'twitter/tweet.dart';
import 'twitter/entities.dart';

Future<List<Tweet>> downloadTweets(String dir, int index) async {
  final i = index < 10 ? '0$index' : '$index';
  final file = File('$dir/tweets$i.json');

  late String jsonStr;
  if (file.existsSync()) {
    jsonStr = await file.readAsString();
  } else {
    final uri = Uri.parse(
        'https://raw.githubusercontent.com/isar/testdata/main/twitter$i.json');
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();
    jsonStr = await response.transform(utf8.decoder).join();
    await file.writeAsString(jsonStr);
  }

  final json = jsonDecode(jsonStr) as List<dynamic>;
  return json.map((e) => Tweet.fromJson(e as Map<String, dynamic>)).toList();
}

void main() async {
  group('Stress', () {
    late Isar isar;
    late IsarCollection<Tweet> col;

    /*setUp(() async {
      isar = await openTempIsar(
        [TweetSchema],
        name: '776524265_tmp',
        
      );
      col = isar.collection<Tweet>();
      /*for (var i = 0; i < 100; i++) {
        final tweets = await downloadTweets(isar.directory!, i);
        await isar.tWriteTxn(() async {
          await col.tPutAll(tweets);
        });
      }*/
    });

    isarTest(
      'Query',
      () async {
        expect(await col.where().tCount(), 500000);

        await qEqualSet(col.where().distinctByLang().langProperty(), [
          'en', 'it', 'de', 'fr', 'pt', 'und', 'es', 'qme', 'qht', //
          'hu', 'ja', 'et', 'tl', 'eu', 'pl', 'ht', 'in', 'lt', 'ar', //
          'ca', 'ru', 'el', 'ro', 'uk', 'sl', 'cy', 'no', 'nl', 'sv', //
          'fi', 'zh', 'tr', 'cs', 'lv', 'hi', 'is', 'da', 'bg', 'vi', //
          'ko', 'fa', 'th', 'sr', 'ne', 'ur', 'iw'
        ]);

        final nn = col
            .filter()
            /*.not()
            .group(
              (q) => q
                  .placeIsNull()
                  .or()
                  .entitiesIsNull()
                  .or()
                  .coordinatesIsNull(),
            )*/
            .extendedEntities((q) => q.hashtagsLengthGreaterThan(0))
            .limit(5)
            .findAllSync();

        final favs =
            col.where().sortByFavoriteCountDesc().limit(10).findAllSync();
        print(favs.first.favoriteCount);
      },
      timeout: const Timeout(Duration(minutes: 10)),
      skip: true,
    );*/
  });
}
