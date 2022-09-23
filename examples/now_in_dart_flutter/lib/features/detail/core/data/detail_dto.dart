import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:now_in_dart_flutter/features/detail/core/domain/detail.dart';

part 'detail_dto.g.dart';

@Collection(inheritance: false)
class DetailDTO extends Equatable {
  const DetailDTO({required this.id, required this.html});

  /// The parser that parses the received html data.
  ///
  /// The markdowns in the flutter's github repo has some data in the format
  /// `%7B%7Bsite.url%7D%7D` which actually is `{{site.url}}`. But WebView will
  /// not be able to take us to relevant web page if `%7B%7Bsite.url%7D%7D`
  /// isn't parsed. So, we need to convert `%7B%7Bsite.url%7D%7D` to
  /// `https://docs.flutter.dev`.
  ///
  /// The mappings will have to be done in accordance to [_mappings].
  factory DetailDTO.parseHtml(int id, String html) {
    final parsedHtml = _mappings.entries.fold(
      html,
      (str, map) => str.replaceAll(map.key, map.value),
    );
    return DetailDTO(id: id, html: parsedHtml);
  }

  final Id id;
  final String html;

  Detail toDomain() => Detail(html: html);

  static const _mappings = <String, String>{
    '%7B%7Bsite.url%7D%7D': 'https://docs.flutter.dev',
    '%7B%7Bsite.medium%7D%7D': 'https://medium.com',
    '%7B%7Bsite.github%7D%7D': 'https://github.com',
    '%7B%7Bsite.groups%7D%7D': 'https://groups.google.com',
    '%7B%7Bsite.dart-site%7D%7D': 'https://dart.dev',
    '%7B%7Bsite.main-url%7D%7D': 'https://flutter.dev',
    '%7B%7Bsite.codelabs%7D%7D': 'https://codelabs.developers.google.com',
    '%7B%7Bsite.youtube-site%7D%7D': 'https://youtube.com',
    '%7B%7Bsite.flutter-medium%7D%7D': 'https://medium.com/flutter',
    '%7B%7Bsite.repo.this%7D%7D': 'https://github.com/flutter/website',
    '%7B%7Bsite.firebase%7D%7D': 'https://firebase.google.com',
    '%7B%7Bsite.google-blog%7D%7D': 'https://developers.googleblog.com',
    '%7B%7Bsite.pub%7D%7D': 'https://pub.dev',
    '%7B%7Bsite.api%7D%7D': 'https://api.flutter.dev',
    '%7B%7Bsite.repo.flutter%7D%7D': 'https://github.com/flutter/flutter',
  };

  @ignore
  @override
  List<Object?> get props => [id, html];
}
