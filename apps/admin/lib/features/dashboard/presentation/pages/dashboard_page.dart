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
      body: ordersAsync.when(
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

          final pendingOrders = orders.where((order) {
            return order.status == OrderStatus.received ||
                order.status == OrderStatus.confirmed ||
                order.status == OrderStatus.preparing ||
                order.status == OrderStatus.outForDelivery;
          }).length;

          final deliveredToday = todayOrders
              .where((order) => order.status == OrderStatus.delivered)
              .length;

          final cancelledToday = todayOrders
              .where((order) => order.status == OrderStatus.cancelled)
              .length;

          final revenueToday = todayOrders
              .where((order) => order.status != OrderStatus.cancelled)
              .fold<double>(0, (sum, order) => sum + order.total);

          final stats = [
            _DashboardStat(
              title: 'Pedidos hoje',
              value: '${todayOrders.length}',
              icon: Icons.receipt_long,
            ),
            _DashboardStat(
              title: 'Faturamento hoje',
              value: currency.format(revenueToday),
              icon: Icons.payments,
            ),
            _DashboardStat(
              title: 'Pedidos em aberto',
              value: '$pendingOrders',
              icon: Icons.pending_actions,
            ),
            _DashboardStat(
              title: 'Entregues hoje',
              value: '$deliveredToday',
              icon: Icons.check_circle,
            ),
            _DashboardStat(
              title: 'Cancelados hoje',
              value: '$cancelledToday',
              icon: Icons.cancel,
            ),
            _DashboardStat(
              title: 'Total de pedidos',
              value: '${orders.length}',
              icon: Icons.list_alt,
            ),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final crossAxisCount = isMobile
                  ? 2
                  : (constraints.maxWidth ~/ 260).clamp(2, 4).toInt();

              return GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 14 : 24,
                  isMobile ? 14 : 24,
                  isMobile ? 14 : 24,
                  90,
                ),
                itemCount: stats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isMobile ? 1.12 : 1.75,
                ),
                itemBuilder: (context, index) {
                  final stat = stats[index];

                  return _StatCard(
                    title: stat.title,
                    value: stat.value,
                    icon: stat.icon,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }
}

class _DashboardStat {
  const _DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF4B3831),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4B3831),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF2B1D18),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
