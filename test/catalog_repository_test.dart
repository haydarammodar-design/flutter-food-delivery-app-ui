import 'dart:convert';

import 'package:flutter_app/models/catalog.dart';
import 'package:flutter_app/services/catalog_api_service.dart';
import 'package:flutter_app/services/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('maps public catalog envelopes into the existing customer models',
      () async {
    final List<String> requestedPaths = <String>[];
    final MockClient client = MockClient((http.Request request) async {
      requestedPaths.add(request.url.path);

      if (request.url.path == '/v1/categories') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <dynamic>[
              <String, dynamic>{
                'id': 'category-burgers',
                'name': 'Burgers',
                'slug': 'burgers',
              },
              'not a category',
            ],
          }),
          200,
        );
      }
      if (request.url.path == '/v1/merchants') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <dynamic>[
              <String, dynamic>{
                'id': 'merchant-harbor',
                'name': 'Harbor Kitchen',
                'slug': 'harbor-kitchen',
                'type': 'RESTAURANT',
                'description': 'Comfort food made for delivery.',
                'coverImageUrl': 'https://images.example.test/harbor.jpg',
                'deliveryFee': '2.99',
                'estimatedDeliveryMinutes': '31',
              },
              <String, dynamic>{'name': 'Malformed merchant'},
            ],
          }),
          200,
        );
      }
      if (request.url.path == '/v1/merchants/harbor-kitchen/products') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'merchant': <String, dynamic>{'slug': 'harbor-kitchen'},
            'data': <dynamic>[
              <String, dynamic>{
                'id': 'burger-classic',
                'name': 'Classic Harbor Burger',
                'description': 'Beef, pickles, and house sauce.',
                'imageUrl': 'https://images.example.test/burger.jpg',
                'price': '12.99',
                'category': <String, dynamic>{'id': 'category-burgers'},
              },
              <String, dynamic>{'name': 'Malformed product'},
            ],
          }),
          200,
        );
      }

      return http.Response('Not found', 404);
    });
    final CatalogRepository repository = CatalogRepository(
      apiService: CatalogApiService(
        client: client,
        baseUrl: 'https://api.example.test',
      ),
    );

    final List<Restaurant> restaurants = await repository.loadRestaurants();

    expect(restaurants, hasLength(1));
    expect(restaurants.single.name, 'Harbor Kitchen');
    expect(restaurants.single.cuisine, 'Burgers');
    expect(restaurants.single.deliveryMinutes, 31);
    expect(restaurants.single.deliveryFee, 2.99);
    expect(restaurants.single.menu, hasLength(1));
    expect(restaurants.single.menu.single.badge, 'Burgers');
    expect(restaurants.single.menu.single.price, 12.99);
    expect(
      requestedPaths.where((String path) => path.contains('/admin/')),
      isEmpty,
    );
  });
}
