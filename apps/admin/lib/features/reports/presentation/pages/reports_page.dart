import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final reportsOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchOrders();
});

enum _ReportPeriod { today, yesterday, sevenDays, thirtyDays, custom }

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  _ReportPeriod _period = _ReportPeriod.today;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(reportsOrdersProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: ordersAsync.when(
        data: (orders) {
          final range = _selectedRange();
          final report = _ReportData.fromOrders(orders, range);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 24,
                  104,
                ),
                children: [
                  _HeroReportCard(rangeLabel: _rangeLabel(range)),
                  const SizedBox(height: 16),
                  _PeriodSelector(
                    selected: _period,
                    onSelected: (period) async {
                      if (period == _ReportPeriod.custom) {
                        await _pickCustomRange();
                      }
                      if (!mounted) return;
                      setState(() => _period = period);
                    },
                    customLabel: _customRangeLabel(),
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Resumo financeiro'),
                  const SizedBox(height: 10),
                  _SummaryGrid(
                    isMobile: isMobile,
                    items: [
                      _SummaryItem(
                        title: 'Faturamento',
                        value: currency.format(report.revenue),
                        icon: Icons.payments_outlined,
                        tone: _CardTone.primary,
                      ),
                      _SummaryItem(
                        title: 'Pedidos',
                        value: '${report.orders.length}',
                        icon: Icons.receipt_long_outlined,
                      ),
                      _SummaryItem(
                        title: 'Finalizados',
                        value: '${report.finishedOrders.length}',
                        icon: Icons.check_circle_outline,
                      ),
                      _SummaryItem(
                        title: 'Em aberto',
                        value: '${report.openOrders.length}',
                        icon: Icons.pending_actions_outlined,
                      ),
                      _SummaryItem(
                        title: 'Cancelados',
                        value: '${report.cancelledOrders.length}',
                        icon: Icons.cancel_outlined,
                        tone: _CardTone.warning,
                      ),
                      _SummaryItem(
                        title: 'Ticket médio',
                        value: currency.format(report.averageTicket),
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Vendas por tipo'),
                  const SizedBox(height: 10),
                  _SalesTypeSection(report: report, currency: currency),
                  const SizedBox(height: 22),
                  const _SectionTitle('Formas de pagamento'),
                  const SizedBox(height: 10),
                  _PaymentSection(report: report, currency: currency),
                  const SizedBox(height: 22),
                  const _SectionTitle('Produtos mais vendidos'),
                  const SizedBox(height: 10),
                  _BestProductsSection(report: report, currency: currency),
                  const SizedBox(height: 22),
                  const _SectionTitle('Mesas e presencial'),
                  const SizedBox(height: 10),
                  _TablesSection(report: report, currency: currency),
                  const SizedBox(height: 22),
                  const _SectionTitle('Pedidos do período'),
                  const SizedBox(height: 10),
                  _OrdersList(orders: report.orders, currency: currency),
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

  _DateRange _selectedRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (_period) {
      _ReportPeriod.today => _DateRange(today, today.add(const Duration(days: 1))),
      _ReportPeriod.yesterday => _DateRange(
          today.subtract(const Duration(days: 1)),
          today,
        ),
      _ReportPeriod.sevenDays => _DateRange(
          today.subtract(const Duration(days: 6)),
          today.add(const Duration(days: 1)),
        ),
      _ReportPeriod.thirtyDays => _DateRange(
          today.subtract(const Duration(days: 29)),
          today.add(const Duration(days: 1)),
        ),
      _ReportPeriod.custom => _DateRange(
          _startOfDay(_customStart ?? today),
          _startOfDay(_customEnd ?? today).add(const Duration(days: 1)),
        ),
    };
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialStart = _customStart ?? now;
    final start = await showDatePicker(
      context: context,
      initialDate: initialStart,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      helpText: 'Data inicial',
    );
    if (start == null || !mounted) return;

    final initialEnd = _customEnd != null && !_customEnd!.isBefore(start)
        ? _customEnd!
        : start;
    final end = await showDatePicker(
      context: context,
      initialDate: initialEnd,
      firstDate: start,
      lastDate: DateTime(now.year + 1),
      helpText: 'Data final',
    );
    if (end == null) return;

    setState(() {
      _customStart = start;
      _customEnd = end;
    });
  }

  String _customRangeLabel() {
    if (_customStart == null || _customEnd == null) return 'Personalizado';
    final formatter = DateFormat('dd/MM');
    return '${formatter.format(_customStart!)} a ${formatter.format(_customEnd!)}';
  }

  String _rangeLabel(_DateRange range) {
    final formatter = DateFormat('dd/MM/yyyy');
    final inclusiveEnd = range.endExclusive.subtract(const Duration(days: 1));
    if (_isSameDay(range.start, inclusiveEnd)) {
      return formatter.format(range.start);
    }
    return '${formatter.format(range.start)} a ${formatter.format(inclusiveEnd)}';
  }
}

class _DateRange {
  const _DateRange(this.start, this.endExclusive);

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime? value) {
    if (value == null) return false;
    return !value.isBefore(start) && value.isBefore(endExclusive);
  }
}

class _ReportData {
  const _ReportData({
    required this.orders,
    required this.finishedOrders,
    required this.openOrders,
    required this.cancelledOrders,
    required this.revenue,
    required this.averageTicket,
    required this.byType,
    required this.byPayment,
    required this.products,
    required this.tableStats,
  });

  final List<OrderModel> orders;
  final List<OrderModel> finishedOrders;
  final List<OrderModel> openOrders;
  final List<OrderModel> cancelledOrders;
  final double revenue;
  final double averageTicket;
  final Map<DeliveryType, _OrderGroup> byType;
  final Map<String, _OrderGroup> byPayment;
  final List<_ProductStat> products;
  final _TableStats tableStats;

  factory _ReportData.fromOrders(List<OrderModel> allOrders, _DateRange range) {
    final orders = allOrders.where((order) => range.contains(order.createdAt)).toList();
    final finished = orders.where(_isFinishedOrder).toList();
    final open = orders.where(_isOpenOrder).toList();
    final cancelled = orders.where((order) => order.status == OrderStatus.cancelled).toList();
    final revenue = finished.fold<double>(0, (sum, order) => sum + order.total);
    final averageTicket = finished.isEmpty ? 0.0 : revenue / finished.length;

    final byType = <DeliveryType, _OrderGroup>{
      DeliveryType.delivery: _OrderGroup.empty(),
      DeliveryType.pickup: _OrderGroup.empty(),
      DeliveryType.dineIn: _OrderGroup.empty(),
    };
    for (final order in finished) {
      byType[order.deliveryType] = byType[order.deliveryType]!.add(order);
    }

    final byPayment = <String, _OrderGroup>{};
    for (final order in finished) {
      final label = _paymentLabel(order.paymentMethod);
      byPayment[label] = (byPayment[label] ?? _OrderGroup.empty()).add(order);
    }

    return _ReportData(
      orders: orders,
      finishedOrders: finished,
      openOrders: open,
      cancelledOrders: cancelled,
      revenue: revenue,
      averageTicket: averageTicket,
      byType: byType,
      byPayment: byPayment,
      products: _buildProductRanking(finished),
      tableStats: _TableStats.fromOrders(finished),
    );
  }
}

class _OrderGroup {
  const _OrderGroup({required this.orders, required this.total});

  factory _OrderGroup.empty() => const _OrderGroup(orders: [], total: 0);

  final List<OrderModel> orders;
  final double total;

  _OrderGroup add(OrderModel order) {
    return _OrderGroup(
      orders: [...orders, order],
      total: total + order.total,
    );
  }
}

class _ProductStat {
  const _ProductStat({
    required this.name,
    required this.quantity,
    required this.total,
  });

  final String name;
  final int quantity;
  final double total;
}

class _TableStats {
  const _TableStats({
    required this.orders,
    required this.revenue,
    required this.averageTicket,
    required this.bestTableLabel,
  });

  final int orders;
  final double revenue;
  final double averageTicket;
  final String bestTableLabel;

  factory _TableStats.fromOrders(List<OrderModel> finishedOrders) {
    final dineIn = finishedOrders
        .where((order) => order.deliveryType == DeliveryType.dineIn)
        .toList();
    final revenue = dineIn.fold<double>(0, (sum, order) => sum + order.total);
    final average = dineIn.isEmpty ? 0.0 : revenue / dineIn.length;
    final totalsByTable = <String, double>{};

    for (final order in dineIn) {
      final label = order.tableNumber == null
          ? 'Mesa não informada'
          : 'Mesa ${order.tableNumber}';
      totalsByTable[label] = (totalsByTable[label] ?? 0) + order.total;
    }

    var bestLabel = 'Sem mesas no período';
    var bestTotal = 0.0;
    totalsByTable.forEach((label, total) {
      if (total > bestTotal) {
        bestLabel = label;
        bestTotal = total;
      }
    });

    return _TableStats(
      orders: dineIn.length,
      revenue: revenue,
      averageTicket: average,
      bestTableLabel: bestTotal > 0 ? bestLabel : 'Sem mesas no período',
    );
  }
}

class _HeroReportCard extends StatelessWidget {
  const _HeroReportCard({required this.rangeLabel});

  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF7B2E1F),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.query_stats, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatório financeiro',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rangeLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFF8F3EC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onSelected,
    required this.customLabel,
  });

  final _ReportPeriod selected;
  final ValueChanged<_ReportPeriod> onSelected;
  final String customLabel;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_ReportPeriod.today, 'Hoje'),
      (_ReportPeriod.yesterday, 'Ontem'),
      (_ReportPeriod.sevenDays, '7 dias'),
      (_ReportPeriod.thirtyDays, '30 dias'),
      (_ReportPeriod.custom, customLabel),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          ChoiceChip(
            label: Text(item.$2),
            selected: selected == item.$1,
            onSelected: (_) => onSelected(item.$1),
            showCheckmark: false,
            selectedColor: const Color(0xFF7B2E1F),
            labelStyle: TextStyle(
              color: selected == item.$1 ? Colors.white : const Color(0xFF2B1D18),
              fontWeight: FontWeight.w900,
            ),
            side: BorderSide(
              color: selected == item.$1
                  ? const Color(0xFF7B2E1F)
                  : const Color(0xFFE9DCD3),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

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
  const _SummaryGrid({required this.items, required this.isMobile});

  final List<_SummaryItem> items;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 1.1 : 1.55,
      ),
      itemBuilder: (context, index) => _SummaryCard(item: items[index]),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    this.tone = _CardTone.neutral,
  });

  final String title;
  final String value;
  final IconData icon;
  final _CardTone tone;
}

enum _CardTone { neutral, primary, warning }

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final accent = switch (item.tone) {
      _CardTone.primary => const Color(0xFF7B2E1F),
      _CardTone.warning => const Color(0xFFB6462F),
      _CardTone.neutral => const Color(0xFF4B3831),
    };
    final background = switch (item.tone) {
      _CardTone.primary => const Color(0xFFFFF7EE),
      _CardTone.warning => const Color(0xFFFFF3F0),
      _CardTone.neutral => Colors.white,
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
          Icon(item.icon, size: 19, color: accent),
          const Spacer(),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4B3831),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              maxLines: 1,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF2B1D18),
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesTypeSection extends StatelessWidget {
  const _SalesTypeSection({required this.report, required this.currency});

  final _ReportData report;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final entries = [
      (DeliveryType.delivery, Icons.delivery_dining, 'Delivery'),
      (DeliveryType.pickup, Icons.storefront, 'Retirada'),
      (DeliveryType.dineIn, Icons.table_restaurant, 'Presencial'),
    ];

    return Column(
      children: [
        for (final entry in entries) ...[
          _ReportListCard(
            icon: entry.$2,
            title: entry.$3,
            subtitle: '${report.byType[entry.$1]?.orders.length ?? 0} pedidos',
            trailing: currency.format(report.byType[entry.$1]?.total ?? 0),
            onTap: () => _showOrdersBottomSheet(
              context,
              title: entry.$3,
              orders: report.byType[entry.$1]?.orders ?? const [],
              currency: currency,
            ),
          ),
          if (entry != entries.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.report, required this.currency});

  final _ReportData report;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final entries = report.byPayment.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    if (entries.isEmpty) return const _EmptyCard('Nenhum pagamento finalizado no período.');

    return Column(
      children: [
        for (final entry in entries) ...[
          _ReportListCard(
            icon: Icons.account_balance_wallet_outlined,
            title: entry.key,
            subtitle: '${entry.value.orders.length} pedidos',
            trailing: currency.format(entry.value.total),
            onTap: () => _showOrdersBottomSheet(
              context,
              title: entry.key,
              orders: entry.value.orders,
              currency: currency,
            ),
          ),
          if (entry != entries.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BestProductsSection extends StatelessWidget {
  const _BestProductsSection({required this.report, required this.currency});

  final _ReportData report;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final products = report.products.take(10).toList();
    if (products.isEmpty) return const _EmptyCard('Nenhum produto vendido no período.');

    return Column(
      children: [
        for (var index = 0; index < products.length; index++) ...[
          _ProductRankingCard(
            position: index + 1,
            product: products[index],
            currency: currency,
          ),
          if (index != products.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ProductRankingCard extends StatelessWidget {
  const _ProductRankingCard({
    required this.position,
    required this.product,
    required this.currency,
  });

  final int position;
  final _ProductStat product;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF7B2E1F),
            foregroundColor: Colors.white,
            child: Text('$position'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.quantity} unidades',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F5A52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            currency.format(product.total),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF7B2E1F),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TablesSection extends StatelessWidget {
  const _TablesSection({required this.report, required this.currency});

  final _ReportData report;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final stats = report.tableStats;
    return Column(
      children: [
        _ReportListCard(
          icon: Icons.table_restaurant,
          title: 'Mesas atendidas',
          subtitle: '${stats.orders} pedidos presenciais',
          trailing: currency.format(stats.revenue),
        ),
        const SizedBox(height: 10),
        _ReportListCard(
          icon: Icons.trending_up,
          title: 'Ticket médio presencial',
          subtitle: stats.bestTableLabel,
          trailing: currency.format(stats.averageTicket),
        ),
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders, required this.currency});

  final List<OrderModel> orders;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const _EmptyCard('Nenhum pedido encontrado no período.');
    final sorted = [...orders]..sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return Column(
      children: [
        for (final order in sorted.take(30)) ...[
          _OrderTile(order: order, currency: currency),
          if (order != sorted.take(30).last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ReportListCard extends StatelessWidget {
  const _ReportListCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F3EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF7B2E1F)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F5A52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              trailing,
              maxLines: 1,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF2B1D18),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.currency});

  final OrderModel order;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt == null
        ? 'Sem data'
        : DateFormat('dd/MM HH:mm').format(order.createdAt!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedido #${_shortId(order.id)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency.format(order.total),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF7B2E1F),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MiniPill(label: date),
              _MiniPill(label: order.deliveryType.label),
              _MiniPill(label: _paymentLabel(order.paymentMethod)),
              _MiniPill(label: order.status.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF7B2E1F),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6F5A52),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE9DCD3)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
    ],
  );
}

void _showOrdersBottomSheet(
  BuildContext context, {
  required String title,
  required List<OrderModel> orders,
  required NumberFormat currency,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text('${orders.length} pedidos'),
              const SizedBox(height: 14),
              Flexible(
                child: orders.isEmpty
                    ? const _EmptyCard('Nenhum pedido nesta categoria.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _OrderTile(order: orders[index], currency: currency);
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

List<_ProductStat> _buildProductRanking(List<OrderModel> orders) {
  final byName = <String, _ProductStat>{};

  for (final order in orders) {
    for (final item in order.items) {
      final name = item.name.trim().isEmpty ? 'Produto sem nome' : item.name.trim();
      final current = byName[name];
      byName[name] = _ProductStat(
        name: name,
        quantity: (current?.quantity ?? 0) + item.quantity,
        total: (current?.total ?? 0) + item.subtotal,
      );
    }
  }

  final values = byName.values.toList()
    ..sort((a, b) {
      final quantity = b.quantity.compareTo(a.quantity);
      if (quantity != 0) return quantity;
      return b.total.compareTo(a.total);
    });
  return values;
}

bool _isFinishedOrder(OrderModel order) => order.status == OrderStatus.delivered;

bool _isOpenOrder(OrderModel order) {
  return order.status == OrderStatus.received ||
      order.status == OrderStatus.confirmed ||
      order.status == OrderStatus.preparing ||
      order.status == OrderStatus.outForDelivery;
}

DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _paymentLabel(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cash => 'Dinheiro',
    PaymentMethod.creditCard => 'Crédito',
    PaymentMethod.debitCard => 'Débito',
    PaymentMethod.pixOnDelivery => 'Pix na entrega',
    PaymentMethod.pixApp => 'Pix pelo app',
    PaymentMethod.pix => 'Pix',
    PaymentMethod.notSelected => 'Não informado',
  };
}

String _shortId(String id) {
  if (id.length <= 7) return id;
  return id.substring(0, 7);
}
