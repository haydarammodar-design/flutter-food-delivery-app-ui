import '../models/courier_profile.dart';
import '../models/delivery_offer.dart';
import '../services/courier_repository.dart';

class DemoDeliveryRepository implements CourierRepository {
  DemoDeliveryRepository({
    List<DeliveryOffer>? deliveries,
    CourierProfile? profile,
  })  : _deliveries = deliveries ?? _seededDeliveries(),
        _profile = profile ?? _seededProfile();

  final List<DeliveryOffer> _deliveries;
  CourierProfile _profile;

  @override
  Future<CourierProfile> fetchCourierProfile() async {
    return _profile;
  }

  @override
  Future<CourierProfile> updateCourierAvailability({
    required bool isAvailable,
  }) async {
    _profile = _profile.withAvailability(isAvailable);
    return _profile;
  }

  @override
  Future<List<DeliveryOffer>> fetchDeliveryOffers() async {
    return List<DeliveryOffer>.from(_deliveries);
  }

  @override
  Future<DeliveryOffer?> fetchActiveDelivery() async {
    for (final delivery in _deliveries) {
      if (delivery.isActive) {
        return delivery;
      }
    }
    return null;
  }

  @override
  Future<DeliveryOffer> updateDeliveryStatus({
    required DeliveryOffer delivery,
    required DeliveryStatus status,
  }) async {
    final index = _deliveries.indexWhere(
      (DeliveryOffer offer) => offer.id == delivery.id,
    );
    if (index == -1) {
      throw StateError('Delivery ${delivery.id} is no longer available.');
    }

    final updated = _deliveries[index].withStatus(status);
    _deliveries[index] = updated;
    return updated;
  }

  static List<DeliveryOffer> _seededDeliveries() {
    return <DeliveryOffer>[
      const DeliveryOffer(
        id: 'delivery-2048',
        reference: 'F-2048',
        merchantName: 'Harvest Table',
        pickupAddress: '154 Willow Lane',
        dropoffAddress: '22 Cedar Court',
        customerName: 'Jamie Reid',
        customerPhone: '+1 (555) 014-2088',
        earnings: 9.80,
        distanceKm: 3.4,
        etaMinutes: 11,
        status: DeliveryStatus.pickedUp,
        pickupNote: 'Ask for the courier shelf by the front desk.',
        dropoffNote: 'Use the side entrance beside the green gate.',
      ),
      const DeliveryOffer(
        id: 'delivery-2051',
        reference: 'F-2051',
        merchantName: 'Copper Kettle',
        pickupAddress: '8 Market Square',
        dropoffAddress: '91 Briar Street',
        customerName: 'Alex Morgan',
        customerPhone: '+1 (555) 014-3491',
        earnings: 8.40,
        distanceKm: 2.1,
        etaMinutes: 18,
        status: DeliveryStatus.offered,
        pickupNote: 'Collect the sealed bag from counter two.',
      ),
      const DeliveryOffer(
        id: 'delivery-2053',
        reference: 'F-2053',
        merchantName: 'Juniper Kitchen',
        pickupAddress: '77 Ash Avenue',
        dropoffAddress: '4 Linden Mews',
        customerName: 'Rowan Patel',
        customerPhone: '+1 (555) 014-7112',
        earnings: 11.60,
        distanceKm: 4.8,
        etaMinutes: 25,
        status: DeliveryStatus.offered,
      ),
      const DeliveryOffer(
        id: 'delivery-2041',
        reference: 'F-2041',
        merchantName: 'Morning Grain',
        pickupAddress: '19 River Walk',
        dropoffAddress: '300 Elm Street',
        customerName: 'Taylor Brooks',
        customerPhone: '+1 (555) 014-0189',
        earnings: 11.90,
        distanceKm: 2.7,
        etaMinutes: 0,
        status: DeliveryStatus.delivered,
      ),
    ];
  }

  static CourierProfile _seededProfile() {
    return const CourierProfile(
      id: 'demo-courier',
      name: 'Maya Chen',
      email: 'maya@example.test',
      phone: '+1 (555) 014-0100',
      isAvailable: true,
      vehicleType: 'Bike courier',
    );
  }
}
