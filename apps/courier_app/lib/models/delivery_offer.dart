enum DeliveryStatus {
  offered,
  assigned,
  accepted,
  arrived,
  pickedUp,
  delivered,
  cancelled,
  unknown,
}

class DeliveryOffer {
  const DeliveryOffer({
    required this.id,
    required this.reference,
    required this.merchantName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerName,
    required this.customerPhone,
    required this.earnings,
    required this.distanceKm,
    required this.etaMinutes,
    required this.status,
    this.pickupNote,
    this.dropoffNote,
  });

  final String id;
  final String reference;
  final String merchantName;
  final String pickupAddress;
  final String dropoffAddress;
  final String customerName;
  final String customerPhone;
  final double earnings;
  final double distanceKm;
  final int etaMinutes;
  final DeliveryStatus status;
  final String? pickupNote;
  final String? dropoffNote;

  bool get isAvailable => status == DeliveryStatus.offered;

  bool get isActive {
    return status == DeliveryStatus.assigned ||
        status == DeliveryStatus.accepted ||
        status == DeliveryStatus.arrived ||
        status == DeliveryStatus.pickedUp;
  }

  DeliveryOffer withStatus(DeliveryStatus nextStatus) {
    return DeliveryOffer(
      id: id,
      reference: reference,
      merchantName: merchantName,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      customerName: customerName,
      customerPhone: customerPhone,
      earnings: earnings,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      status: nextStatus,
      pickupNote: pickupNote,
      dropoffNote: dropoffNote,
    );
  }

  factory DeliveryOffer.fromJson(
    Map<String, dynamic> json, {
    DeliveryOffer? fallback,
  }) {
    final merchant = _asMap(json['merchant']);
    final restaurant = _asMap(json['restaurant']);
    final pickup = _asMap(json['pickup']);
    final dropoff = _asMap(json['dropoff']);
    final destination = _asMap(json['destination']);
    final customer = _asMap(json['customer']);
    final recipient = _asMap(json['recipient']);
    final route = _asMap(json['route']);
    final payout = _asMap(json['payout']);

    final id = _firstText(<dynamic>[
          json['id'],
          json['deliveryId'],
          json['delivery_id'],
          json['orderId'],
          json['order_id'],
        ]) ??
        fallback?.id;

    if (id == null || id.isEmpty) {
      throw const FormatException(
          'A delivery offer is missing its identifier.');
    }

    final rawStatus = _firstText(<dynamic>[
      json['status'],
      json['deliveryStatus'],
      json['delivery_status'],
      json['state'],
    ]);

    final meterDistance = _firstNumber(<dynamic>[
      json['distanceMeters'],
      json['distance_meters'],
      route['distanceMeters'],
      route['distance_meters'],
    ]);

    return DeliveryOffer(
      id: id,
      reference: _firstText(<dynamic>[
            json['reference'],
            json['orderNumber'],
            json['order_number'],
            json['code'],
          ]) ??
          fallback?.reference ??
          id,
      merchantName: _firstText(<dynamic>[
            json['merchantName'],
            json['merchant_name'],
            merchant['name'],
            restaurant['name'],
            pickup['name'],
          ]) ??
          fallback?.merchantName ??
          'Pickup location',
      pickupAddress: _address(pickup) ??
          _firstText(
              <dynamic>[json['pickupAddress'], json['pickup_address']]) ??
          fallback?.pickupAddress ??
          'Pickup address pending',
      dropoffAddress: _address(dropoff) ??
          _address(destination) ??
          _firstText(
              <dynamic>[json['dropoffAddress'], json['dropoff_address']]) ??
          fallback?.dropoffAddress ??
          'Drop-off address pending',
      customerName: _firstText(<dynamic>[
            json['customerName'],
            json['customer_name'],
            customer['name'],
            recipient['name'],
          ]) ??
          fallback?.customerName ??
          'Customer',
      customerPhone: _firstText(<dynamic>[
            json['customerPhone'],
            json['customer_phone'],
            customer['phone'],
            recipient['phone'],
          ]) ??
          fallback?.customerPhone ??
          '',
      earnings: _firstNumber(<dynamic>[
            json['earnings'],
            json['deliveryFee'],
            json['delivery_fee'],
            json['fee'],
            payout['amount'],
            payout['value'],
          ]) ??
          fallback?.earnings ??
          0,
      distanceKm: _firstNumber(<dynamic>[
            json['distanceKm'],
            json['distance_km'],
            route['distanceKm'],
            route['distance_km'],
            json['distance'],
          ]) ??
          (meterDistance == null ? null : meterDistance / 1000) ??
          fallback?.distanceKm ??
          0,
      etaMinutes: _firstInteger(<dynamic>[
            json['etaMinutes'],
            json['eta_minutes'],
            json['estimatedMinutes'],
            json['estimated_minutes'],
            route['etaMinutes'],
            route['eta_minutes'],
          ]) ??
          fallback?.etaMinutes ??
          0,
      status: rawStatus == null
          ? (fallback?.status ?? DeliveryStatus.offered)
          : deliveryStatusFromJson(rawStatus),
      pickupNote: _firstText(<dynamic>[
            json['pickupNote'],
            json['pickup_note'],
            pickup['note'],
          ]) ??
          fallback?.pickupNote,
      dropoffNote: _firstText(<dynamic>[
            json['dropoffNote'],
            json['dropoff_note'],
            dropoff['note'],
            destination['note'],
          ]) ??
          fallback?.dropoffNote,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
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

  static String? _address(Map<String, dynamic> location) {
    final address = _asMap(location['address']);
    return _firstText(<dynamic>[
      location['formattedAddress'],
      location['formatted_address'],
      location['address'] is String ? location['address'] : null,
      address['formattedAddress'],
      address['formatted_address'],
      address['line1'],
      address['street'],
      location['street'],
      location['label'],
    ]);
  }

  static String? _firstText(List<dynamic> values) {
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

  static double? _firstNumber(List<dynamic> values) {
    for (final value in values) {
      final number = _number(value);
      if (number != null) {
        return number;
      }
    }
    return null;
  }

  static int? _firstInteger(List<dynamic> values) {
    return _firstNumber(values)?.round();
  }

  static double? _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }
}

DeliveryStatus deliveryStatusFromJson(String rawStatus) {
  final value =
      rawStatus.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');

  switch (value) {
    case 'offered':
    case 'available':
    case 'pending':
      return DeliveryStatus.offered;
    case 'assigned':
      return DeliveryStatus.assigned;
    case 'accepted':
    case 'confirmed':
      return DeliveryStatus.accepted;
    case 'arrived':
    case 'atpickup':
      return DeliveryStatus.arrived;
    case 'pickedup':
    case 'collected':
    case 'intransit':
      return DeliveryStatus.pickedUp;
    case 'delivered':
    case 'completed':
      return DeliveryStatus.delivered;
    case 'cancelled':
    case 'canceled':
      return DeliveryStatus.cancelled;
    default:
      return DeliveryStatus.unknown;
  }
}

String deliveryStatusApiValue(DeliveryStatus status) {
  switch (status) {
    case DeliveryStatus.offered:
      return 'offered';
    case DeliveryStatus.assigned:
      return 'assigned';
    case DeliveryStatus.accepted:
      return 'accepted';
    case DeliveryStatus.arrived:
      return 'arrived';
    case DeliveryStatus.pickedUp:
      return 'picked_up';
    case DeliveryStatus.delivered:
      return 'delivered';
    case DeliveryStatus.cancelled:
      return 'cancelled';
    case DeliveryStatus.unknown:
      return 'unknown';
  }
}

String deliveryStatusLabel(DeliveryStatus status) {
  switch (status) {
    case DeliveryStatus.offered:
      return 'Available';
    case DeliveryStatus.assigned:
      return 'Assigned';
    case DeliveryStatus.accepted:
      return 'Heading to pickup';
    case DeliveryStatus.arrived:
      return 'At pickup';
    case DeliveryStatus.pickedUp:
      return 'On the way';
    case DeliveryStatus.delivered:
      return 'Delivered';
    case DeliveryStatus.cancelled:
      return 'Cancelled';
    case DeliveryStatus.unknown:
      return 'Status pending';
  }
}
