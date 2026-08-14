class ApiConfig {
  const ApiConfig._();

  static const String localFallbackBaseUrl = 'http://localhost:3000';

  static const String _environmentBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: localFallbackBaseUrl,
  );

  static String get baseUrl => normalizeBaseUrl(_environmentBaseUrl);

  static String normalizeBaseUrl(String value) {
    final configured = value.trim();
    final root = configured.isEmpty ? localFallbackBaseUrl : configured;
    final withoutTrailingSlash = root.replaceFirst(RegExp(r'/+$'), '');
    if (withoutTrailingSlash.toLowerCase().endsWith('/v1')) {
      return withoutTrailingSlash;
    }
    return '$withoutTrailingSlash/v1';
  }
}
