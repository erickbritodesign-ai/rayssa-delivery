import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:rayssa_client/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:rayssa_client/features/orders/data/repositories/order_repository_impl.dart';
import 'package:rayssa_client/features/orders/domain/repositories/order_repository.dart';
import 'package:rayssa_core/rayssa_core.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(OrderRemoteDatasource());
});

final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchUserOrders(user.id);
});

final orderDetailProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId);
});
