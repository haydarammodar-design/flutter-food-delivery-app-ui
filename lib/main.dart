import 'package:flutter/material.dart';
import 'package:flutter_app/pages/HomePage.dart';
import 'package:flutter_app/state/cart_store.dart';

void main() {
  runApp(DeliveryApp());
}

class DeliveryApp extends StatefulWidget {
  @override
  _DeliveryAppState createState() => _DeliveryAppState();
}

class _DeliveryAppState extends State<DeliveryApp> {
  final CartStore _cart = CartStore();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deliver Now',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF1F2A24),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1F2A24),
          secondary: Color(0xFFE6663F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5F0),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(cart: _cart),
    );
  }
}
