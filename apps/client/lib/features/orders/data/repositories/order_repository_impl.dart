import 'package:rayssa_client/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:rayssa_client/features/orders/domain/repositories/order_repository.dart';
import 'package:rayssa_core/rayssa_core.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._datasource);

  final OrderRemoteDatasource _datasource;

  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) =>
      _datasource.watchUserOrders(userId);

  @override
  Stream<OrderModel?> watchOrder(String orderId) =>
      _datasource.watchOrder(orderId);

  @override
  Future<String> createOrder(OrderModel order) =>
      _datasource.createOrder(order);

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) {
    throw UnimplementedError('Status updates are admin-only in MVP');
  }
}
