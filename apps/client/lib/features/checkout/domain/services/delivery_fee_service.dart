import 'package:rayssa_core/rayssa_core.dart';

abstract final class DeliveryFeeService {
  static const double defaultDeliveryFee = 5.0;

  static double calculate({
    required DeliveryType type,
    required double configuredFee,
  }) {
    return type == DeliveryType.delivery ? configuredFee : 0;
  }
}