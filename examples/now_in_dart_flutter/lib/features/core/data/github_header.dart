import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

part 'github_header.g.dart';

@Collection(inheritance: false)
class GithubHeader extends Equatable {
  const GithubHeader({
    required this.id,
    required this.eTag,
    required this.path,
  });

  factory GithubHeader.parse(int id, Response<String> response, String path) {
    return GithubHeader(
      id: id,
      eTag: response.headers.map['ETag']![0],
      path: path,
    );
  }

  final String eTag;

  // We are only making `path` a property of this class because we want to make
  // a query using path value. If Isar supports key-value storage mechanism too
  // in the future, then the `path` property can be removed from this file.

  @Index(unique: true)
  final String path;

  final Id id;

  @ignore
  @override
  List<Object?> get props => [id, eTag, path];
}
