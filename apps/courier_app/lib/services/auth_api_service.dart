import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_http_client.dart';

class AuthSession {
  const AuthSession({required this.accessToken, this.email});

  final String accessToken;
  final String? email;
}

class AuthApiService {
  AuthApiService({
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  }) : _api = ApiHttpClient(
          client: client,
          baseUrl: baseUrl,
          timeout: timeout,
        );

  final ApiHttpClient _api;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final payload = await _api.postJson(
      'auth/login',
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
    );
    final root = ApiHttpClient.toStringMap(payload);
    final data = ApiHttpClient.toStringMap(root['data']);
    final response = data.isEmpty ? root : data;
    final token = _firstText(<dynamic>[
      response['accessToken'],
      response['access_token'],
      response['token'],
      root['accessToken'],
      root['access_token'],
      root['token'],
    ]);

    if (token == null) {
      throw const ApiException(
          'The sign-in response did not include an access token.');
    }

    final user = ApiHttpClient.toStringMap(response['user']);
    return AuthSession(
      accessToken: token,
      email: _firstText(<dynamic>[response['email'], user['email'], email]),
    );
  }

  String? _firstText(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}
