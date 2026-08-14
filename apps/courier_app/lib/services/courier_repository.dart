import '../models/courier_profile.dart';
import '../models/delivery_offer.dart';

abstract class CourierRepository {
  Future<CourierProfile> fetchCourierProfile();

  Future<CourierProfile> updateCourierAvailability({
    required bool isAvailable,
  });

  Future<List<DeliveryOffer>> fetchDeliveryOffers();

  Future<DeliveryOffer?> fetchActiveDelivery();

  Future<DeliveryOffer> updateDeliveryStatus({
    required DeliveryOffer delivery,
    required DeliveryStatus status,
  });
}
