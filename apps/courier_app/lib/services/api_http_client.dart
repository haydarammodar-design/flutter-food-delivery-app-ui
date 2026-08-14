import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiHttpClient {
  ApiHttpClient({
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _baseUrl = ApiConfig.normalizeBaseUrl(baseUrl ?? ApiConfig.baseUrl),
        _timeout = timeout ?? const Duration(seconds: 8);

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  Future<dynamic> getJson(String path, {String? accessToken}) {
    return _send(
      () => _client.get(
        _endpoint(path),
        headers: _headers(accessToken: accessToken),
      ),
    );
  }

  Future<dynamic> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? accessToken,
  }) {
    return _send(
      () => _client.post(
        _endpoint(path),
        headers: _headers(accessToken: accessToken, hasBody: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> patchJson(
    String path, {
    required Map<String, dynamic> body,
    String? accessToken,
  }) {
    return _send(
      () => _client.patch(
        _endpoint(path),
        headers: _headers(accessToken: accessToken, hasBody: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final response = await _request(request);
    _ensureSuccess(response);
    if (response.body.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('The delivery service returned invalid JSON.');
    }
  }

  Uri _endpoint(String path) {
    final normalizedPath = path.replaceFirst(RegExp(r'^/+'), '');
    final uri = Uri.tryParse('$_baseUrl/$normalizedPath');
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const ApiException('API_BASE_URL must be an absolute HTTP URL.');
    }
    return uri;
  }

  Map<String, String> _headers({
    String? accessToken,
    bool hasBody = false,
  }) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (hasBody) {
      headers['Content-Type'] = 'application/json';
    }
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${accessToken.trim()}';
    }
    return headers;
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('The delivery service did not respond in time.');
    } on http.ClientException catch (error) {
      throw ApiException('Could not reach the delivery service: $error');
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw ApiException(
      _errorMessage(response),
      statusCode: response.statusCode,
    );
  }

  String _errorMessage(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return 'The delivery service returned ${response.statusCode}.';
    }
    try {
      final message = _messageFromPayload(jsonDecode(body));
      if (message != null) {
        return message;
      }
    } on FormatException {
      // A text response can still be useful when a proxy rejects a request.
    }
    return body.length > 180 ? '${body.substring(0, 180)}...' : body;
  }

  String? _messageFromPayload(dynamic payload) {
    if (payload is String && payload.trim().isNotEmpty) {
      return payload.trim();
    }
    if (payload is! Map) {
      return null;
    }
    final map = toStringMap(payload);
    for (final key in const <String>['message', 'error', 'detail']) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is List) {
        final parts = <String>[];
        for (final item in value) {
          if (item != null && item.toString().trim().isNotEmpty) {
            parts.add(item.toString().trim());
          }
        }
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> toStringMap(dynamic value) {
    final result = <String, dynamic>{};
    if (value is Map) {
      value.forEach((dynamic key, dynamic item) {
        if (key != null) {
          result[key.toString()] = item;
        }
      });
    }
    return result;
  }
}
