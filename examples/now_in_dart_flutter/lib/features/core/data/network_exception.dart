class RestApiException implements Exception {
  RestApiException(this.errorCode);

  final int? errorCode;
}
