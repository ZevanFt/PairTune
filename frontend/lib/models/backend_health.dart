class BackendHealthStatus {
  const BackendHealthStatus({
    required this.online,
    required this.statusCode,
    required this.statusText,
  });

  final bool online;
  final int statusCode;
  final String statusText;
}
