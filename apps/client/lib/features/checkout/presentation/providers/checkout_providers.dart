import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:rayssa_client/features/cart/presentation/providers/cart_providers.dart';
import 'package:rayssa_client/features/checkout/domain/models/delivery_area.dart';
import 'package:rayssa_client/features/checkout/domain/services/delivery_fee_service.dart';
import 'package:rayssa_client/features/orders/presentation/providers/order_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final deliveryTypeProvider =
    StateProvider<DeliveryType>((ref) => DeliveryType.delivery);

final selectedDeliveryAreaProvider =
    StateProvider<DeliveryArea?>((ref) => null);

final storeDeliveryFeeProvider = StreamProvider<double>((ref) {
  return FirebaseFirestore.instance
      .collection('configuracoes')
      .doc('store')
      .snapshots()
      .map((doc) {
    final data = doc.data();
    final value = data?['deliveryFee'];

    if (value is num) return value.toDouble();

    return DeliveryFeeService.defaultDeliveryFee;
  });
});

final deliveryFeeProvider = Provider<double>((ref) {
  final type = ref.watch(deliveryTypeProvider);
  final selectedArea = ref.watch(selectedDeliveryAreaProvider);
  final configuredFee = ref.watch(storeDeliveryFeeProvider).valueOrNull ??
      DeliveryFeeService.defaultDeliveryFee;

  if (type == DeliveryType.delivery && selectedArea?.deliveryFee != null) {
    return selectedArea!.deliveryFee!;
  }

  return DeliveryFeeService.calculate(
    type: type,
    configuredFee: configuredFee,
  );
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
    required PaymentMethod paymentMethod,
    int loyaltyPointsRedeemed = 0,
    double loyaltyDiscountAmount = 0,
    String? loyaltyRewardLabel,
    double? changeFor,
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
      final canApplyReward = deliveryType == DeliveryType.delivery ||
          deliveryType == DeliveryType.pickup;
      final discount = canApplyReward
          ? _clampDiscount(loyaltyDiscountAmount, subtotal)
          : 0.0;
      final pointsRedeemed =
          canApplyReward && discount > 0 ? loyaltyPointsRedeemed : 0;
      final rewardApplied = pointsRedeemed > 0;
      final subtotalAfterDiscount = subtotal - discount;

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
        total: subtotalAfterDiscount + deliveryFee,
        status: OrderStatus.received,
        deliveryType: deliveryType,
        paymentMethod: paymentMethod,
        paymentStatus: PaymentStatus.pending,
        address: deliveryType == DeliveryType.delivery ? address : null,
        notes: notes,
        changeFor: changeFor,
        loyaltyRewardApplied: rewardApplied,
        loyaltyPointsRedeemed: pointsRedeemed,
        loyaltyDiscountAmount: discount,
        loyaltyRewardLabel: rewardApplied ? loyaltyRewardLabel : null,
        subtotalBeforeDiscount: subtotal,
        subtotalAfterDiscount: subtotalAfterDiscount,
      );

      final orderId =
          await _ref.read(orderRepositoryProvider).createOrder(order);
      _ref.read(cartControllerProvider.notifier).clear();
      if (rewardApplied) {
        _ref.invalidate(currentUserProvider);
      }
      return orderId;
    });
    return state.valueOrNull;
  }
}

double _clampDiscount(double discount, double subtotal) {
  if (discount <= 0 || subtotal <= 0) return 0;
  return discount > subtotal ? subtotal : discount;
}
