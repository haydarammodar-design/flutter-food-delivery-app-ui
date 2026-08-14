import 'dart:async';
import 'dart:convert';

import 'package:flutter_app/config/app_config.dart';
import 'package:http/http.dart' as http;

class CatalogApiException implements Exception {
  final String message;

  CatalogApiException(this.message);

  @override
  String toString() => message;
}

class CatalogApiData {
  final List<Map<String, dynamic>> categories;
  final List<CatalogMerchantData> merchants;

  CatalogApiData({this.categories, this.merchants});
}

class CatalogMerchantData {
  final Map<String, dynamic> merchant;
  final List<Map<String, dynamic>> products;

  CatalogMerchantData({this.merchant, this.products});
}

class CatalogApiService {
  final http.Client _client;
  final String _baseUrl;
  final bool _ownsClient;

  CatalogApiService({http.Client client, String baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = _normaliseBaseUrl(baseUrl ?? AppConfig.apiBaseUrl),
        _ownsClient = client == null;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<CatalogApiData> fetchCatalog() async {
    if (!isConfigured) {
      throw CatalogApiException('API_BASE_URL is not configured.');
    }

    final Future<List<Map<String, dynamic>>> categoriesRequest =
        _getOptionalCollection('/categories');
    final List<Map<String, dynamic>> merchants = await _getCollection(
      '/merchants',
      queryParameters: const <String, String>{'limit': '100'},
    );
    final List<Map<String, dynamic>> categories = await categoriesRequest;
    final List<CatalogMerchantData> merchantCatalogs =
        await Future.wait<CatalogMerchantData>(
      merchants.map(_getMerchantCatalog),
    );

    return CatalogApiData(
      categories: categories,
      merchants: merchantCatalogs,
    );
  }

  Future<CatalogMerchantData> _getMerchantCatalog(
      Map<String, dynamic> merchant) async {
    final String slug = _stringValue(merchant['slug']);
    if (slug.isEmpty) {
      return CatalogMerchantData(
        merchant: merchant,
        products: <Map<String, dynamic>>[],
      );
    }

    final List<Map<String, dynamic>> products = await _getOptionalCollection(
      '/merchants/$slug/products',
      queryParameters: const <String, String>{'limit': '100'},
    );
    return CatalogMerchantData(merchant: merchant, products: products);
  }

  Future<List<Map<String, dynamic>>> _getOptionalCollection(
    String resource, {
    Map<String, String> queryParameters,
  }) async {
    try {
      return await _getCollection(
        resource,
        queryParameters: queryParameters,
      );
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> _getCollection(
    String resource, {
    Map<String, String> queryParameters,
  }) async {
    final http.Response response = await _client.get(
      _endpoint(resource, queryParameters: queryParameters),
      headers: const <String, String>{'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CatalogApiException('Catalog request failed.');
    }

    dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw CatalogApiException('Catalog response is invalid.');
    }

    return _extractCollection(payload);
  }

  Uri _endpoint(
    String resource, {
    Map<String, String> queryParameters,
  }) {
    final Uri base = Uri.tryParse(_baseUrl);
    if (base == null || !base.hasScheme || base.host.isEmpty) {
      throw CatalogApiException('API_BASE_URL must be an absolute URL.');
    }

    String path = base.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (!path.endsWith('/v1')) {
      path += '/v1';
    }

    return base.replace(
      path: '$path$resource',
      queryParameters: queryParameters,
    );
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static String _normaliseBaseUrl(String value) {
    String result = (value ?? '').trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static List<Map<String, dynamic>> _extractCollection(dynamic payload) {
    dynamic collection = payload;
    if (payload is Map) {
      collection = payload['data'] ?? payload['items'] ?? payload['results'];
    }
    if (collection is! List) {
      return <Map<String, dynamic>>[];
    }

    return collection
        .whereType<Map>()
        .map<Map<String, dynamic>>(_normaliseMap)
        .toList();
  }

  static Map<String, dynamic> _normaliseMap(Map value) {
    final Map<String, dynamic> result = <String, dynamic>{};
    value.forEach((dynamic key, dynamic field) {
      if (key is String) {
        result[key] = field;
      }
    });
    return result;
  }

  static String _stringValue(dynamic value) {
    return value == null ? '' : value.toString().trim();
  }
}
