import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final dashboardOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchOrders();
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(dashboardOrdersProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ordersAsync.when(
          data: (orders) {
            final now = DateTime.now();

            bool isToday(OrderModel order) {
              final createdAt = order.createdAt;
              if (createdAt == null) return false;
              return createdAt.year == now.year &&
                  createdAt.month == now.month &&
                  createdAt.day == now.day;
            }

            final todayOrders = orders.where(isToday).toList();

            final pendingOrders = orders
                .where(
                  (o) =>
                      o.status == OrderStatus.received ||
                      o.status == OrderStatus.confirmed ||
                      o.status == OrderStatus.preparing ||
                      o.status == OrderStatus.outForDelivery,
                )
                .length;

            final deliveredToday = todayOrders
                .where((o) => o.status == OrderStatus.delivered)
                .length;

            final cancelledToday = todayOrders
                .where((o) => o.status == OrderStatus.cancelled)
                .length;

            final revenueToday = todayOrders
                .where((o) => o.status != OrderStatus.cancelled)
                .fold<double>(0, (sum, order) => sum + order.total);

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  title: 'Pedidos hoje',
                  value: '${todayOrders.length}',
                  icon: Icons.receipt_long,
                ),
                _StatCard(
                  title: 'Faturamento hoje',
                  value: currency.format(revenueToday),
                  icon: Icons.payments,
                ),
                _StatCard(
                  title: 'Pedidos em aberto',
                  value: '$pendingOrders',
                  icon: Icons.pending_actions,
                ),
                _StatCard(
                  title: 'Entregues hoje',
                  value: '$deliveredToday',
                  icon: Icons.check_circle,
                ),
                _StatCard(
                  title: 'Cancelados hoje',
                  value: '$cancelledToday',
                  icon: Icons.cancel,
                ),
                _StatCard(
                  title: 'Total de pedidos',
                  value: '${orders.length}',
                  icon: Icons.list_alt,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erro: $e'),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 240,
        height: 130,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const Spacer(),
              Text(title),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}