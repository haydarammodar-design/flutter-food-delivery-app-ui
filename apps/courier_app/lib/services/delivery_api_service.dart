import 'package:http/http.dart' as http;

import '../models/courier_profile.dart';
import '../models/delivery_offer.dart';
import 'api_exception.dart';
import 'api_http_client.dart';
import 'courier_repository.dart';

class DeliveryApiService implements CourierRepository {
  DeliveryApiService({
    required String accessToken,
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  })  : _accessToken = accessToken,
        _api = ApiHttpClient(
          client: client,
          baseUrl: baseUrl,
          timeout: timeout,
        );

  final String _accessToken;
  final ApiHttpClient _api;

  @override
  Future<CourierProfile> fetchCourierProfile() async {
    final payload = await _api.getJson(
      'couriers/me',
      accessToken: _token,
    );
    final record =
        _objectRecord(payload, const <String>['courier', 'profile', 'data']);
    if (record == null) {
      throw const ApiException('The courier profile response was invalid.');
    }
    return CourierProfile.fromJson(record);
  }

  @override
  Future<CourierProfile> updateCourierAvailability({
    required bool isAvailable,
  }) async {
    final payload = await _api.patchJson(
      'couriers/me/availability',
      accessToken: _token,
      body: <String, dynamic>{'isAvailable': isAvailable},
    );
    final record =
        _objectRecord(payload, const <String>['courier', 'profile', 'data']);
    if (record == null) {
      throw const ApiException(
          'The courier availability response was invalid.');
    }
    return CourierProfile.fromJson(record);
  }

  @override
  Future<List<DeliveryOffer>> fetchDeliveryOffers() async {
    final payload = await _api.getJson(
      'deliveries/offers',
      accessToken: _token,
    );
    final records = _deliveryRecords(payload);
    if (records == null) {
      throw const ApiException(
        'The delivery service returned an unexpected offers response.',
      );
    }

    final offers = <DeliveryOffer>[];
    for (final record in records) {
      if (record is! Map) {
        continue;
      }
      try {
        offers.add(DeliveryOffer.fromJson(ApiHttpClient.toStringMap(record)));
      } on FormatException {
        // One malformed offer should not hide the rest of a valid dispatch list.
      }
    }

    if (records.isNotEmpty && offers.isEmpty) {
      throw const ApiException(
        'The delivery service did not return any usable offers.',
      );
    }
    return offers;
  }

  @override
  Future<DeliveryOffer?> fetchActiveDelivery() async {
    final payload = await _api.getJson(
      'deliveries/active',
      accessToken: _token,
    );
    final records = _deliveryRecords(payload);
    if (records != null) {
      for (final record in records) {
        if (record is! Map) {
          continue;
        }
        try {
          return DeliveryOffer.fromJson(ApiHttpClient.toStringMap(record));
        } on FormatException {
          // Try the next active delivery record if a response is malformed.
        }
      }
      return null;
    }

    final record = _deliveryRecord(payload);
    if (record == null) {
      return null;
    }
    try {
      return DeliveryOffer.fromJson(record);
    } on FormatException {
      throw const ApiException(
        'The delivery service returned an invalid active delivery.',
      );
    }
  }

  @override
  Future<DeliveryOffer> updateDeliveryStatus({
    required DeliveryOffer delivery,
    required DeliveryStatus status,
  }) async {
    final payload = await _api.patchJson(
      'deliveries/${Uri.encodeComponent(delivery.id)}/status',
      accessToken: _token,
      body: <String, dynamic>{'status': deliveryStatusApiValue(status)},
    );
    if (payload == null) {
      return delivery.withStatus(status);
    }

    final record = _deliveryRecord(payload);
    if (record == null) {
      return delivery.withStatus(status);
    }

    try {
      final updated = DeliveryOffer.fromJson(record, fallback: delivery);
      return _hasStatus(record) ? updated : updated.withStatus(status);
    } on FormatException {
      return delivery.withStatus(status);
    }
  }

  String get _token {
    final token = _accessToken.trim();
    if (token.isEmpty) {
      throw const ApiException(
          'A courier session is required for this request.');
    }
    return token;
  }

  List<dynamic>? _deliveryRecords(dynamic payload) {
    if (payload is List) {
      return List<dynamic>.from(payload);
    }
    if (payload is! Map) {
      return null;
    }

    final map = ApiHttpClient.toStringMap(payload);
    for (final key in const <String>[
      'offers',
      'deliveries',
      'items',
      'results',
      'data',
    ]) {
      final value = map[key];
      if (value is List) {
        return List<dynamic>.from(value);
      }
      if (value is Map) {
        final nested = _deliveryRecords(value);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _objectRecord(
    dynamic payload,
    List<String> wrappers,
  ) {
    if (payload is! Map) {
      return null;
    }
    final map = ApiHttpClient.toStringMap(payload);
    for (final key in wrappers) {
      final nested = map[key];
      if (nested is Map) {
        return _objectRecord(nested, wrappers) ??
            ApiHttpClient.toStringMap(nested);
      }
    }
    return map;
  }

  Map<String, dynamic>? _deliveryRecord(dynamic payload) {
    if (payload is! Map) {
      return null;
    }

    final map = ApiHttpClient.toStringMap(payload);
    if (_looksLikeDelivery(map)) {
      return map;
    }

    for (final key in const <String>['delivery', 'offer', 'result', 'data']) {
      final value = map[key];
      if (value is Map) {
        final nested = _deliveryRecord(value);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  bool _looksLikeDelivery(Map<String, dynamic> value) {
    return value.containsKey('id') ||
        value.containsKey('deliveryId') ||
        value.containsKey('delivery_id') ||
        value.containsKey('status');
  }

  bool _hasStatus(Map<String, dynamic> value) {
    return value.containsKey('status') ||
        value.containsKey('deliveryStatus') ||
        value.containsKey('delivery_status') ||
        value.containsKey('state');
  }
}
