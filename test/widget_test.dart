import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('customer can place a local demo order',
      (WidgetTester tester) async {
    await tester.pumpWidget(DeliveryApp());
    await tester.pumpAndSettle();

    expect(find.text('Your neighborhood,\non demand.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('restaurant-fire-and-bun')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester
        .ensureVisible(find.byKey(const Key('restaurant-fire-and-bun')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restaurant-fire-and-bun')));
    await tester.pumpAndSettle();
    expect(find.text('Fire & Bun'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('menu-smoky-stack')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('menu-smoky-stack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-smoky-stack')));
    await tester.pumpAndSettle();
    expect(find.text('Smoky Stack'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-to-basket')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your basket'), findsWidgets);
    expect(find.text('Smoky Stack'), findsOneWidget);

    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pumpAndSettle();
    expect(find.text('Order confirmed'), findsOneWidget);

    await tester.tap(find.byKey(const Key('return-to-restaurants')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-orders')));
    await tester.pumpAndSettle();
    expect(find.text('MOST RECENT'), findsOneWidget);
  });

  testWidgets('marketplace home fits a phone viewport',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(390, 844);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

    await tester.pumpWidget(DeliveryApp());
    await tester.pumpAndSettle();

    expect(find.text('Your neighborhood,\non demand.'), findsOneWidget);
    expect(find.byKey(const Key('tab-browse')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
