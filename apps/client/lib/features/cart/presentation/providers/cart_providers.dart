import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_core/rayssa_core.dart';

final cartControllerProvider =
    StateNotifierProvider<CartController, List<CartItemModel>>((ref) {
  return CartController();
});

final cartSubtotalProvider = Provider<double>((ref) {
  return ref
      .watch(cartControllerProvider)
      .fold(0, (sum, item) => sum + item.subtotal);
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref
      .watch(cartControllerProvider)
      .fold(0, (sum, item) => sum + item.quantity);
});

class CartController extends StateNotifier<List<CartItemModel>> {
  CartController() : super(const []);

  void addProduct(ProductModel product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final updated = [...state];
      final current = updated[index];
      updated[index] = current.copyWith(quantity: current.quantity + 1);
      state = updated;
      return;
    }
    state = [...state, CartItemModel(product: product, quantity: 1)];
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() => state = const [];
}
