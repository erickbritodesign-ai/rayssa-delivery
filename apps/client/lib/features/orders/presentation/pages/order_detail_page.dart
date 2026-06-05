import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/features/orders/presentation/providers/order_providers.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do pedido')),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Pedido não encontrado'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Status: ${order.status.label}'),
              Text('Pagamento: ${order.paymentStatus.label}'),
              Text('Total: ${currency.format(order.total)}'),
              const Divider(),
              ...order.items.map(
                (item) => ListTile(
                  title: Text('${item.quantity}x ${item.name}'),
                  trailing: Text(currency.format(item.subtotal)),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}
