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
          // TODO: quando todos os fluxos tiverem pagamento padronizado,
          // filtrar por paymentStatus pago/aprovado.
          final billableOrders = todayOrders
              .where((order) => order.status != OrderStatus.cancelled)
              .toList();
          final deliveryOrders = billableOrders
              .where((order) => order.deliveryType == DeliveryType.delivery)
              .toList();
          final pickupOrders = billableOrders
              .where((order) => order.deliveryType == DeliveryType.pickup)
              .toList();
          final dineInOrders = billableOrders
              .where((order) => order.deliveryType == DeliveryType.dineIn)
              .toList();

          double totalOf(List<OrderModel> values) {
            return values.fold<double>(0, (sum, order) => sum + order.total);
          }

          final summaryStats = [
            _DashboardStat(
              title: 'Faturamento hoje',
              value: currency.format(revenueToday),
              icon: Icons.payments,
              tone: _StatTone.primary,
            ),
            _DashboardStat(
              title: 'Pedidos hoje',
              value: '${todayOrders.length}',
              icon: Icons.receipt_long,
            ),
            _DashboardStat(
              title: 'Em aberto',
              value: '$pendingOrders',
              icon: Icons.pending_actions,
            ),
            _DashboardStat(
              title: 'Cancelados',
              value: '$cancelledToday',
              icon: Icons.cancel_outlined,
              tone: _StatTone.warning,
            ),
          ];

          final salesByType = [
            _SalesTypeStat(
              title: 'Delivery',
              subtitle: '${deliveryOrders.length} pedidos',
              value: currency.format(totalOf(deliveryOrders)),
              icon: Icons.delivery_dining,
            ),
            _SalesTypeStat(
              title: 'Retirada',
              subtitle: '${pickupOrders.length} pedidos',
              value: currency.format(totalOf(pickupOrders)),
              icon: Icons.storefront,
            ),
            _SalesTypeStat(
              title: 'Presencial',
              subtitle: '${dineInOrders.length} pedidos',
              value: currency.format(totalOf(dineInOrders)),
              icon: Icons.table_restaurant,
            ),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 24,
                  96,
                ),
                children: [
                  const _DashboardSectionTitle('Resumo de hoje'),
                  const SizedBox(height: 10),
                  _SummaryGrid(stats: summaryStats, isMobile: isMobile),
                  const SizedBox(height: 22),
                  const _DashboardSectionTitle('Vendas por tipo'),
                  const SizedBox(height: 10),
                  _SalesByTypeList(stats: salesByType),
                  const SizedBox(height: 22),
                  _TotalCard(
                    value: currency.format(revenueToday),
                    ordersLabel: '${orders.length} pedidos no histórico',
                    deliveredLabel: '$deliveredToday entregues hoje',
                  ),
                ],
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
    this.tone = _StatTone.neutral,
  });

  final String title;
  final String value;
  final IconData icon;
  final _StatTone tone;
}

enum _StatTone { neutral, primary, warning }

class _SalesTypeStat {
  const _SalesTypeStat({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
}

class _DashboardSectionTitle extends StatelessWidget {
  const _DashboardSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF2B1D18),
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats, required this.isMobile});

  final List<_DashboardStat> stats;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 1.18 : 1.5,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _StatCard(
          title: stat.title,
          value: stat.value,
          icon: stat.icon,
          tone: stat.tone,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String value;
  final IconData icon;
  final _StatTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (tone) {
      _StatTone.primary => const Color(0xFF7B2E1F),
      _StatTone.warning => const Color(0xFFB6462F),
      _StatTone.neutral => const Color(0xFF4B3831),
    };
    final background = switch (tone) {
      _StatTone.primary => const Color(0xFFFFF7EE),
      _StatTone.warning => const Color(0xFFFFF3F0),
      _StatTone.neutral => Colors.white,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.08)),
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
            color: accent,
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
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesByTypeList extends StatelessWidget {
  const _SalesByTypeList({required this.stats});

  final List<_SalesTypeStat> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final stat in stats) ...[
          _SalesTypeCard(stat: stat),
          if (stat != stats.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SalesTypeCard extends StatelessWidget {
  const _SalesTypeCard({required this.stat});

  final _SalesTypeStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F3EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(stat.icon, color: const Color(0xFF7B2E1F)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stat.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F5A52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.value,
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF2B1D18),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.value,
    required this.ordersLabel,
    required this.deliveredLabel,
  });

  final String value;
  final String ordersLabel;
  final String deliveredLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1D18),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total geral',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFFF8F3EC),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TotalPill(label: ordersLabel),
              _TotalPill(label: deliveredLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalPill extends StatelessWidget {
  const _TotalPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFF8F3EC),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
