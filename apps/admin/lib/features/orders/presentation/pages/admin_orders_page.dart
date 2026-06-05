import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchOrders();
});

class AdminOrdersPage extends ConsumerWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: ordersAsync.when(
        data: (orders) => ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Pedido #${order.id.substring(0, 8)}'),
                subtitle: Text(
                  '${order.status.label} · ${currency.format(order.total)}',
                ),
                trailing: DropdownButton<OrderStatus>(
                  value: order.status,
                  items: OrderStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (status) {
                    if (status == null) return;
                    ref.read(adminFirestoreProvider).updateOrderStatus(
                          order.id,
                          status,
                        );
                  },
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}
