import 'package:courier_app/main.dart';
import 'package:courier_app/services/auth_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('courier can pause dispatch and view available jobs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CourierApp(
        authService: AuthApiService(
          client: MockClient((_) async => http.Response('', 500)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to dispatch'), findsOneWidget);
    expect(find.text('Use local demo'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use local demo'));
    await tester.pumpAndSettle();

    expect(find.text('Courier desk'), findsOneWidget);
    expect(find.text('You are available'), findsOneWidget);
    expect(find.text('Harvest Table'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(find.text('You are paused'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.work_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delivery offers from live dispatch'), findsOneWidget);
    expect(find.text('Copper Kettle'), findsOneWidget);
    expect(find.text('Dispatch paused'), findsWidgets);
  });
}
