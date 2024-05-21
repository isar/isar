import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:now_in_dart_flutter/features/core/data/data.dart';

typedef _RemoteMarkdown = Future<RemoteResponse<String>>;

abstract class DetailRemoteService {
  DetailRemoteService({
    Dio? dio,
    HeaderCache? headerCache,
  })  : _dio = dio ?? Dio(),
        _headerCache = headerCache ?? GithubHeaderCache();

  final Dio _dio;
  final HeaderCache _headerCache;

  @protected
  _RemoteMarkdown getDetail(int id, String fullPathToMarkdownFile) async {
    final requestUri = Uri.https(_dio.options.baseUrl, fullPathToMarkdownFile);
    final cachedHeader = await _headerCache.getHeader(fullPathToMarkdownFile);

    try {
      final response = await _dio.getUri<String>(
        requestUri,
        options: Options(
          headers: <String, String>{
            'If-None-Match': cachedHeader?.eTag ?? '',
          },
        ),
      );

      switch (response.statusCode) {
        case 200:
          final header = GithubHeader.parse(
            id,
            response,
            fullPathToMarkdownFile,
          );
          await _headerCache.saveHeader(header);
          final html = response.data!;
          return RemoteResponse.withNewData(html);

        case 304:
          return const RemoteResponse.notModified();

        default:
          throw RestApiException(response.statusCode);
      }
    } on DioError catch (e) {
      if (e.isNoConnectionError) {
        return const RemoteResponse.noConnection();
      } else if (e.response != null) {
        throw RestApiException(e.response?.statusCode);
      } else {
        rethrow;
      }
    }
  }
}
