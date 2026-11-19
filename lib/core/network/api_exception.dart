class ApiException implements Exception {
  final String message;

  /// HTTP status of the web app's answer; null if there was none.
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});
  @override
  String toString() {
    return message;
  }
}
