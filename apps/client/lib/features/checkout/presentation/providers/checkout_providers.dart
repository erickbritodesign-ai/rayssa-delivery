import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:rayssa_client/features/cart/presentation/providers/cart_providers.dart';
import 'package:rayssa_client/features/checkout/domain/services/delivery_fee_service.dart';
import 'package:rayssa_client/features/orders/presentation/providers/order_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';

final deliveryTypeProvider =
    StateProvider<DeliveryType>((ref) => DeliveryType.delivery);

final deliveryFeeProvider = Provider<double>((ref) {
  final type = ref.watch(deliveryTypeProvider);
  return DeliveryFeeService.calculate(type);
});

final checkoutTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final fee = ref.watch(deliveryFeeProvider);
  return subtotal + fee;
});

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, AsyncValue<String?>>((ref) {
  return CheckoutController(ref);
});

class CheckoutController extends StateNotifier<AsyncValue<String?>> {
  CheckoutController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<String?> placeOrder({
    required AddressModel? address,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw StateError('Usuário não autenticado');

      final cart = _ref.read(cartControllerProvider);
      if (cart.isEmpty) throw StateError('Carrinho vazio');

      final deliveryType = _ref.read(deliveryTypeProvider);
      final subtotal = _ref.read(cartSubtotalProvider);
      final deliveryFee = _ref.read(deliveryFeeProvider);

      final items = cart
          .map(
            (item) => OrderItemModel(
              productId: item.product.id,
              name: item.product.name,
              unitPrice: item.product.price,
              quantity: item.quantity,
              imageUrl: item.product.imageUrl,
            ),
          )
          .toList();

      final order = OrderModel(
        id: '',
        userId: user.id,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: subtotal + deliveryFee,
        status: OrderStatus.received,
        deliveryType: deliveryType,
        paymentMethod: PaymentMethod.pix,
        paymentStatus: PaymentStatus.pending,
        address: deliveryType == DeliveryType.delivery ? address : null,
        notes: notes,
      );

      final orderId =
          await _ref.read(orderRepositoryProvider).createOrder(order);
      _ref.read(cartControllerProvider.notifier).clear();
      return orderId;
    });
    return state.valueOrNull;
  }
}
