class ApiHttpError implements Exception {
  ApiHttpError({
    required this.statusCode,
    required this.statusText,
    this.endpoint,
  });

  final int statusCode;
  final String statusText;
  final String? endpoint;
}
