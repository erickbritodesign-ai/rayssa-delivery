import 'package:rayssa_core/rayssa_core.dart';

/// Taxa de entrega fixa para MVP (Pedro Canário).
/// V2: distância, zonas e Google Maps.
abstract final class DeliveryFeeService {
  static const double defaultDeliveryFee = 5.0;

  static double calculate(DeliveryType type) {
    return type == DeliveryType.delivery ? defaultDeliveryFee : 0;
  }
}
