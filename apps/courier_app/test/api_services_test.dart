import 'dart:convert';

import 'package:courier_app/config/api_config.dart';
import 'package:courier_app/services/auth_api_service.dart';
import 'package:courier_app/services/delivery_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('API base URLs receive one v1 prefix', () {
    expect(
      ApiConfig.normalizeBaseUrl('https://dispatch.example.test'),
      'https://dispatch.example.test/v1',
    );
    expect(
      ApiConfig.normalizeBaseUrl('https://dispatch.example.test/v1/'),
      'https://dispatch.example.test/v1',
    );
  });

  test('login posts credentials to the normalized auth endpoint', () async {
    final service = AuthApiService(
      baseUrl: 'https://dispatch.example.test/',
      client: MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(
          request.url,
          Uri.parse('https://dispatch.example.test/v1/auth/login'),
        );
        expect(request.headers['content-type'], startsWith('application/json'));
        expect(
          jsonDecode(request.body),
          <String, String>{
            'email': 'courier@example.test',
            'password': 'not-a-real-password',
          },
        );
        return http.Response(
          jsonEncode(<String, dynamic>{
            'accessToken': 'session-token',
            'user': <String, String>{'email': 'courier@example.test'},
          }),
          200,
        );
      }),
    );

    final session = await service.login(
      email: 'courier@example.test',
      password: 'not-a-real-password',
    );

    expect(session.accessToken, 'session-token');
    expect(session.email, 'courier@example.test');
  });

  test('protected courier calls include the bearer token and v1 route',
      () async {
    final service = DeliveryApiService(
      accessToken: 'session-token',
      baseUrl: 'https://dispatch.example.test/v1/',
      client: MockClient((http.Request request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url,
          Uri.parse(
            'https://dispatch.example.test/v1/couriers/me/availability',
          ),
        );
        expect(request.headers['authorization'], 'Bearer session-token');
        expect(jsonDecode(request.body), <String, bool>{'isAvailable': true});
        return http.Response(
          jsonEncode(<String, dynamic>{
            'id': 'courier-1',
            'name': 'Alex Courier',
            'email': 'courier@example.test',
            'isAvailable': true,
          }),
          200,
        );
      }),
    );

    final profile = await service.updateCourierAvailability(isAvailable: true);

    expect(profile.name, 'Alex Courier');
    expect(profile.isAvailable, isTrue);
  });
}
