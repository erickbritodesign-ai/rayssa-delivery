import 'package:rayssa_core/rayssa_core.dart';

abstract class OrderRepository {
  Stream<List<OrderModel>> watchUserOrders(String userId);
  Stream<OrderModel?> watchOrder(String orderId);
  Future<String> createOrder(OrderModel order);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}
