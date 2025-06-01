import 'package:isar/isar.dart';
import 'package:now_in_dart_flutter/features/core/data/github_header.dart';
import 'package:now_in_dart_flutter/features/core/data/isar_database.dart';

abstract class HeaderCache {
  Future<void> saveHeader(GithubHeader header);
  Future<GithubHeader?> getHeader(String path);
}

class GithubHeaderCache implements HeaderCache {
  GithubHeaderCache({
    IsarDatabase? isarDb,
  }) : _isarDb = isarDb ?? IsarDatabase();

  final IsarDatabase _isarDb;

  Isar get _isar => _isarDb.instance;

  IsarCollection<GithubHeader> get _githubHeaders => _isar.githubHeaders;

  @override
  Future<void> saveHeader(GithubHeader header) {
    return _isar.writeTxn<int>(
      () => _githubHeaders.put(header),
      silent: true,
    );
  }

  @override
  Future<GithubHeader?> getHeader(String path) {
    return _githubHeaders.getByPath(path);
  }
}
