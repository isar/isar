import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import 'twitter/entities.dart';
import 'twitter/tweet.dart';

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

      isarTest('Import Export Json', () async {
        final isar = await openTempIsar([TweetSchema]);

        await isar.tWriteTxn(() async {
          await isar.tweets.tImportJson([tweetJson]);
        });

        expect(await isar.tweets.where().exportJson(), [tweetJson]);
      });
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

const tweetJson = {
  'coordinates': {
    'coordinates': [14.48532271, 40.63070878],
    'type': 'Point'
  },
  'createdAt': 1432502262000000,
  'currentUserRetweet': null,
  'displayTextRange': [0, 123],
  'entities': {
    'hashtags': [
      {
        'indices': [42, 51],
        'text': 'foodporn'
      },
      {
        'indices': [52, 64],
        'text': 'gialloblogs'
      },
      {
        'indices': [65, 87],
        'text': 'RicetteBloggerRiunite'
      },
      {
        'indices': [88, 97],
        'text': 'Expo2015'
      }
    ],
    'media': [
      {
        'additionalMediaInfo': null,
        'displayUrl': 'pic.twitter.com/yFgRfzL6DF',
        'expandedUrl':
            'https://twitter.com/caterinaboagno/status/602408908561473536/photo/1',
        'idStr': '602408906787291136',
        'indices': [98, 120],
        'mediaUrl': 'http://pbs.twimg.com/media/CFwvtYKWgAAaOV9.jpg',
        'mediaUrlHttps': 'https://pbs.twimg.com/media/CFwvtYKWgAAaOV9.jpg',
        'sizes': {
          'large': {'h': 450, 'resize': 'fit', 'w': 600},
          'medium': {'h': 450, 'resize': 'fit', 'w': 600},
          'small': {'h': 450, 'resize': 'fit', 'w': 600},
          'thumb': {'h': 150, 'resize': 'crop', 'w': 150}
        },
        'sourceStatusIdStr': '602408908561473536',
        'type': 'photo',
        'url': 'http://t.co/yFgRfzL6DF',
        'videoInfo': null
      }
    ],
    'polls': null,
    'symbols': <dynamic>[],
    'urls': [
      {
        'displayUrl': 'blog.giallozafferano.it/lacucinadikaty…',
        'expandedUrl':
            'http://blog.giallozafferano.it/lacucinadikaty/cheesecake-frutta/',
        'indices': [18, 40],
        'url': 'http://t.co/S8yyMcL62d'
      }
    ],
    'userMentions': [
      {
        'idStr': '993103729',
        'indices': [1, 16],
        'name': 'La cucina di katy',
        'screenName': 'caterinaboagno'
      }
    ]
  },
  'extendedEntities': {
    'hashtags': null,
    'media': [
      {
        'additionalMediaInfo': null,
        'displayUrl': 'pic.twitter.com/yFgRfzL6DF',
        'expandedUrl':
            'https://twitter.com/caterinaboagno/status/602408908561473536/photo/1',
        'idStr': '602408906787291136',
        'indices': [98, 120],
        'mediaUrl': 'http://pbs.twimg.com/media/CFwvtYKWgAAaOV9.jpg',
        'mediaUrlHttps': 'https://pbs.twimg.com/media/CFwvtYKWgAAaOV9.jpg',
        'sizes': {
          'large': {'h': 450, 'resize': 'fit', 'w': 600},
          'medium': {'h': 450, 'resize': 'fit', 'w': 600},
          'small': {'h': 450, 'resize': 'fit', 'w': 600},
          'thumb': {'h': 150, 'resize': 'crop', 'w': 150}
        },
        'sourceStatusIdStr': '602408908561473536',
        'type': 'photo',
        'url': 'http://t.co/yFgRfzL6DF',
        'videoInfo': null
      }
    ],
    'polls': null,
    'symbols': null,
    'urls': null,
    'userMentions': null
  },
  'favoriteCount': 2,
  'favorited': false,
  'fullText':
      '"@caterinaboagno: http://t.co/S8yyMcL62d\n\n#foodporn #gialloblogs #RicetteBloggerRiunite #Expo2015 http://t.co/yFgRfzL6DF" 😍',
  'idStr': '602584278883553280',
  'inReplyToScreenName': 'caterinaboagno',
  'inReplyToStatusIdStr': '602408908561473536',
  'inReplyToUserIdStr': '993103729',
  'isQuoteStatus': false,
  'isarId': 372526,
  'lang': 'und',
  'place': {
    'country': 'Italien',
    'countryCode': 'IT',
    'fullName': 'Positano, Kampanien',
    'id': 'ab6034f6c3eb69c8',
    'name': 'Positano',
    'placeType': 'city',
    'url': 'https://api.twitter.com/1.1/geo/id/ab6034f6c3eb69c8.json'
  },
  'possiblySensitive': false,
  'possiblySensitiveAppealable': null,
  'quoteCount': null,
  'quotedStatusIdStr': null,
  'quotedStatusPermalink': null,
  'replyCount': null,
  'retweetCount': 3,
  'retweeted': false,
  'source':
      '<a href="http://www.twitter.com" rel="nofollow">Twitter for Windows Phone</a>',
  'truncated': false,
  'user': {
    'createdAt': 1409213170000000,
    'defaultProfile': true,
    'defaultProfileImage': false,
    'description': 'Born&Living in Positano ❤',
    'entities': {
      'description': {'urls': <dynamic>[]},
      'url': null
    },
    'favoritesCount': null,
    'followersCount': 1671,
    'friendsCount': 2293,
    'idStr': '2753148281',
    'listedCount': 32,
    'location': 'Positano',
    'name': 'Rosa Cinque',
    'profileBannerUrl':
        'https://pbs.twimg.com/profile_banners/2753148281/1519746619',
    'profileImageUrlHttps':
        'https://pbs.twimg.com/profile_images/784521636955451393/Xwp0rcPc_normal.jpg',
    'protected': false,
    'screenName': 'rosa_cinque',
    'statusesCount': 4901,
    'url': null,
    'verified': false,
    'withheldInCountries': <dynamic>[],
    'withheldScope': null
  }
};
