import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/features/orders/presentation/providers/order_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final String orderId;

  int _statusIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }

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

          final currentStep = _statusIndex(order.status);
          final address = order.address;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Pedido #${order.id.substring(0, 8)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Status: ${order.status.label}'),
              Text('Pagamento: ${order.paymentStatus.label}'),
              Text('Tipo: ${order.deliveryType.label}'),
              Text('Total: ${currency.format(order.total)}'),
              const SizedBox(height: 16),

              if (order.status == OrderStatus.cancelled)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.cancel),
                    title: Text('Pedido cancelado'),
                  ),
                )
              else
                Stepper(
                  currentStep: currentStep < 0 ? 0 : currentStep,
                  controlsBuilder: (_, __) => const SizedBox.shrink(),
                  steps: const [
                    Step(
                      title: Text('Recebido'),
                      content: Text('Seu pedido foi recebido.'),
                    ),
                    Step(
                      title: Text('Confirmado'),
                      content: Text('Seu pedido foi confirmado.'),
                    ),
                    Step(
                      title: Text('Em preparo'),
                      content: Text('Seu pedido está sendo preparado.'),
                    ),
                    Step(
                      title: Text('Saiu para entrega'),
                      content: Text('Seu pedido saiu para entrega.'),
                    ),
                    Step(
                      title: Text('Entregue'),
                      content: Text('Pedido finalizado.'),
                    ),
                  ],
                ),

              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Itens',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...order.items.map(
                (item) => ListTile(
                  title: Text('${item.quantity}x ${item.name}'),
                  trailing: Text(currency.format(item.subtotal)),
                ),
              ),

              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Resumo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Subtotal: ${currency.format(order.subtotal)}'),
              Text('Taxa de entrega: ${currency.format(order.deliveryFee)}'),
              Text(
                'Total: ${currency.format(order.total)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              if (address != null) ...[
  const Divider(),
  const SizedBox(height: 8),
  Text(
    'Endereço de entrega',
    style: Theme.of(context).textTheme.titleMedium,
  ),
  const SizedBox(height: 8),
  Text('Rua: ${address.street}'),
  Text('Número: ${address.number}'),
  Text('Bairro: ${address.neighborhood}'),
  Text('Cidade: ${address.city} - ${address.state}'),
  if ((address.complement ?? '').isNotEmpty)
    Text('Complemento: ${address.complement}'),
],

              if ((order.notes ?? '').isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Observações',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(order.notes!),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}