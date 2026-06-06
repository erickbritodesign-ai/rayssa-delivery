import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/core/widgets/ray_brand.dart';
import 'package:rayssa_client/features/orders/presentation/providers/order_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Meus pedidos')),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const _EmptyOrders()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderCard(
                    order: order,
                    total: currency.format(order.total),
                    onTap: () => context.push('/orders/${order.id}'),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.total,
    required this.onTap,
  });

  final OrderModel order;
  final String total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == OrderStatus.cancelled;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: cancelled ? AppTheme.line : AppTheme.cream,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  cancelled
                      ? Icons.cancel_outlined
                      : Icons.bakery_dining,
                  color: cancelled ? AppTheme.muted : AppTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${order.id.substring(0, 6)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${order.items.length} item(ns) • ${order.deliveryType.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    _OrderStatusPill(status: order.status),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.deepRed,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right, color: AppTheme.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusPill extends StatelessWidget {
  const _OrderStatusPill({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final cancelled = status == OrderStatus.cancelled;
    final delivered = status == OrderStatus.delivered;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cancelled
            ? AppTheme.line
            : delivered
                ? AppTheme.success.withOpacity(0.12)
                : AppTheme.blush,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cancelled
                  ? AppTheme.muted
                  : delivered
                      ? AppTheme.success
                      : AppTheme.deepRed,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RayBrandMark(size: 84),
            const SizedBox(height: 18),
            Text(
              'Nenhum pedido ainda',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Quando você fizer seu primeiro pedido, o cuidado da Ray aparece aqui etapa por etapa.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ver cardápio'),
            ),
          ],
        ),
      ),
    );
  }
}
