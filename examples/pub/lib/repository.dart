// ignore_for_file: avoid_dynamic_calls

import 'package:dio/dio.dart';
import 'package:pub_app/models/api/metrics.dart';
import 'package:pub_app/models/api/package.dart';
import 'package:pub_app/models/package.dart';

const _api = 'https://pub.dev/api';

class Repository {
  Repository(this.dio);

  final Dio dio;

  Future<List<Package>> getPackageVersions(String name) async {
    final response =
        await dio.get<Map<String, dynamic>>('$_api/packages/$name');
    final package = ApiPackage.fromJson(response.data!);
    return Package.fromApiPackage(package);
  }

  Future<ApiPackageMetrics> getPackageMetrics(
    String name,
    String version,
  ) async {
    final response = await dio.get<Map<String, dynamic>>(
      '$_api/packages/$name/versions/$version/score',
    );
    return ApiPackageMetrics.fromJson(response.data!);
  }

  Future<List<int>> downloadPackage(String name, String version) async {
    final response = await dio.get<List<int>>(
      '$_api/packages/$name/versions/$version/archive.tar.gz',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  Future<List<String>> search(String query, int page) async {
    final response = await dio.get<Map<String, dynamic>>(
      '$_api/search',
      queryParameters: {
        'q': query,
        'page': page,
      },
    );
    return (response.data!['packages'] as List)
        .map((e) => e['package'] as String)
        .toList();
  }
}
