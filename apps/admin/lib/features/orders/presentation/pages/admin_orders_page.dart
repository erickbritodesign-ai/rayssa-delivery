import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchOrders();
});

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  static const _filters = [
    'Todos',
    'Recebidos',
    'Preparando',
    'Saiu para entrega',
    'Entregues',
    'Cancelados',
    'Delivery',
    'Retirada',
    'Presencial',
  ];

  final _searchController = TextEditingController();
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EB),
      appBar: AppBar(
        title: const Text('Pedidos'),
        surfaceTintColor: Colors.transparent,
      ),
      body: ordersAsync.when(
        data: (orders) {
          final visibleOrders = _filterOrders(orders);

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrdersSummary(orders: orders),
                      const SizedBox(height: 16),
                      _OrdersSearchField(controller: _searchController),
                      const SizedBox(height: 14),
                      _OrderFilterBar(
                        filters: _filters,
                        selectedFilter: _selectedFilter,
                        onSelected: (filter) {
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: visibleOrders.isEmpty
                            ? const _EmptyOrdersState()
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: visibleOrders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final order = visibleOrders[index];
                                  return _OrderAdminCard(
                                    order: order,
                                    currency: currency,
                                    onStatusChange: (status) {
                                      _updateOrderStatus(order, status);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    final query = _normalize(_searchController.text.trim());

    return orders.where((order) {
      final matchesFilter = _matchesStatusFilter(order);
      final matchesSearch =
          query.isEmpty || _searchableText(order).contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  bool _matchesStatusFilter(OrderModel order) {
    switch (_selectedFilter) {
      case 'Recebidos':
        return order.status == OrderStatus.received;
      case 'Preparando':
        return order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.preparing;
      case 'Saiu para entrega':
        return order.status == OrderStatus.outForDelivery;
      case 'Entregues':
        return order.status == OrderStatus.delivered;
      case 'Cancelados':
        return order.status == OrderStatus.cancelled;
      case 'Delivery':
        return order.deliveryType == DeliveryType.delivery;
      case 'Retirada':
        return order.deliveryType == DeliveryType.pickup;
      case 'Presencial':
        return order.deliveryType == DeliveryType.dineIn;
      case 'Todos':
      default:
        return true;
    }
  }

  String _searchableText(OrderModel order) {
    final address = order.address;
    final itemsText = order.items.map((item) => item.name).join(' ');

    return _normalize(
      [
        order.id,
        _shortOrderCode(order.id),
        itemsText,
        order.notes ?? '',
        address?.street ?? '',
        address?.neighborhood ?? '',
        address?.city ?? '',
        address?.reference ?? '',
        address?.complement ?? '',
        order.tableNumber == null ? '' : 'mesa ${order.tableNumber}',
        order.tableSessionId ?? '',
      ].join(' '),
    );
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  Future<void> _updateOrderStatus(
    OrderModel order,
    OrderStatus status,
  ) async {
    if (order.status == status) return;

    final awardedPoints = await ref
        .read(adminFirestoreProvider)
        .updateOrderStatus(order.id, status);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          awardedPoints > 0
              ? 'Pedido atualizado para ${_statusLabel(status)}. $awardedPoints pontos concedidos.'
              : 'Pedido atualizado para ${_statusLabel(status)}.',
        ),
      ),
    );
  }
}

class _OrdersSummary extends StatelessWidget {
  const _OrdersSummary({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final total = orders.length;
    final received =
        orders.where((order) => order.status == OrderStatus.received).length;
    final preparing = orders.where((order) {
      return order.status == OrderStatus.confirmed ||
          order.status == OrderStatus.preparing;
    }).length;
    final delivered =
        orders.where((order) => order.status == OrderStatus.delivered).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _SummaryTitle(total: total),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: '$received recebidos',
                icon: Icons.notifications_active_outlined,
                color: const Color(0xFFB6462F),
              ),
              _SummaryChip(
                label: '$preparing em preparo',
                icon: Icons.restaurant_menu_outlined,
                color: const Color(0xFFD7A552),
              ),
              _SummaryChip(
                label: '$delivered entregues',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2F7D46),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTitle extends StatelessWidget {
  const _SummaryTitle({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Operação da cozinha',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2B1D18),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$total pedidos no painel',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF7E6A62),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersSearchField extends StatelessWidget {
  const _OrdersSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar pedido, item, rua, bairro ou observação...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x11000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFB6462F), width: 1.4),
        ),
      ),
    );
  }
}

class _OrderFilterBar extends StatelessWidget {
  const _OrderFilterBar({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter == selectedFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            showCheckmark: false,
            selectedColor: const Color(0xFF7B2E1F),
            backgroundColor: Colors.white,
            side: BorderSide(
              color:
                  selected ? const Color(0xFF7B2E1F) : const Color(0xFFE6DCD1),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF4B3831),
              fontWeight: FontWeight.w800,
            ),
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _OrderAdminCard extends StatelessWidget {
  const _OrderAdminCard({
    required this.order,
    required this.currency,
    required this.onStatusChange,
  });

  final OrderModel order;
  final NumberFormat currency;
  final ValueChanged<OrderStatus> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final isNew = order.status == OrderStatus.received;

    return Container(
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFFFFBF8) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isNew ? const Color(0xFFD7A552) : const Color(0xFFEADFD4),
          width: isNew ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isNew ? const Color(0x1FD7A552) : const Color(0x12000000),
            blurRadius: isNew ? 22 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            if (isNew)
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _NewOrderStripe(),
              ),
            Padding(
              padding: EdgeInsets.only(left: isNew ? 6 : 0),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OrderHeader(order: order, isNew: isNew),
                    const SizedBox(height: 14),
                    _OrderMetaRow(order: order, currency: currency),
                    const SizedBox(height: 16),
                    _OrderItemsList(order: order, currency: currency),
                    _OrderNotes(notes: order.notes),
                    if (order.deliveryType == DeliveryType.delivery)
                      _OrderAddress(address: order.address),
                    if (order.deliveryType == DeliveryType.dineIn)
                      _OrderTableInfo(order: order),
                    const SizedBox(height: 16),
                    _OrderActions(
                      order: order,
                      onStatusChange: onStatusChange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewOrderStripe extends StatelessWidget {
  const _NewOrderStripe();

  @override
  Widget build(BuildContext context) {
    return Container(width: 6, color: const Color(0xFFD7A552));
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({
    required this.order,
    required this.isNew,
  });

  final OrderModel order;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pedido #${_shortOrderCode(order.id)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2B1D18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (isNew) ...[
                  const SizedBox(width: 8),
                  const _NewOrderBadge(),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _dateTimeLabel(order.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7E6A62),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        _StatusChip(status: order.status),
      ],
    );
  }
}

class _NewOrderBadge extends StatelessWidget {
  const _NewOrderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFE4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Novo',
        style: TextStyle(
          color: Color(0xFFB6462F),
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OrderMetaRow extends StatelessWidget {
  const _OrderMetaRow({
    required this.order,
    required this.currency,
  });

  final OrderModel order;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaPill(
          icon: _deliveryTypeIcon(order.deliveryType),
          label: _deliveryTypeLabel(order.deliveryType),
        ),
        _MetaPill(
          icon: Icons.payments_outlined,
          label: currency.format(order.total),
          emphasized: true,
        ),
        if (order.loyaltyRewardApplied &&
            order.loyaltyDiscountAmount > 0) ...[
          _MetaPill(
            icon: Icons.local_offer_outlined,
            label:
                'Desconto fidelidade: ${currency.format(order.loyaltyDiscountAmount)}',
          ),
          _MetaPill(
            icon: Icons.redeem_outlined,
            label: 'Pontos usados: ${order.loyaltyPointsRedeemed}',
          ),
        ],
        _MetaPill(
          icon: Icons.account_balance_wallet_outlined,
          label: _paymentMethodLabel(order.paymentMethod),
        ),
        _MetaPill(
          icon: Icons.verified_outlined,
          label: _paymentStatusLabel(order.paymentStatus),
        ),
        if (order.loyaltyPointsAwarded && order.loyaltyPoints > 0)
          _MetaPill(
            icon: Icons.workspace_premium_outlined,
            label: 'Pontos: ${order.loyaltyPoints}',
            emphasized: true,
          ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color =
        emphasized ? const Color(0xFF7B2E1F) : const Color(0xFF5C4840);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: emphasized ? const Color(0xFFFFF4E1) : const Color(0xFFF8F3EC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: color,
                  fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemsList extends StatelessWidget {
  const _OrderItemsList({
    required this.order,
    required this.currency,
  });

  final OrderModel order;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADFD4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itens do pedido',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF2B1D18),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (order.items.isEmpty)
            const Text(
              'Nenhum item registrado.',
              style: TextStyle(color: Color(0xFF7E6A62)),
            )
          else
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2E1F),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Color(0xFF2B1D18),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      currency.format(item.subtotal),
                      style: const TextStyle(
                        color: Color(0xFF7B2E1F),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderNotes extends StatelessWidget {
  const _OrderNotes({required this.notes});

  final String? notes;

  @override
  Widget build(BuildContext context) {
    final value = notes?.trim();
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _InfoBlock(
        icon: Icons.edit_note_outlined,
        title: 'Observações do cliente',
        body: value,
      ),
    );
  }
}

class _OrderAddress extends StatelessWidget {
  const _OrderAddress({required this.address});

  final AddressModel? address;

  @override
  Widget build(BuildContext context) {
    if (address == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: _InfoBlock(
          icon: Icons.location_off_outlined,
          title: 'Entrega',
          body: 'Endereço não informado.',
        ),
      );
    }

    final value = _fullAddress(address!);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _InfoBlock(
        icon: Icons.location_on_outlined,
        title: 'Endereço de entrega',
        body: value,
      ),
    );
  }
}

class _OrderTableInfo extends StatelessWidget {
  const _OrderTableInfo({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final tableLabel = order.tableNumber == null
        ? 'Mesa não informada'
        : 'Mesa ${order.tableNumber}';
    final sessionLabel = (order.tableSessionId ?? '').isEmpty
        ? ''
        : '\nComanda: ${order.tableSessionId}';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _InfoBlock(
        icon: Icons.table_restaurant_outlined,
        title: 'Consumo no local',
        body: '$tableLabel$sessionLabel',
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADFD4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7B2E1F), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF2B1D18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5C4840),
                    height: 1.35,
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

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.onStatusChange,
  });

  final OrderModel order;
  final ValueChanged<OrderStatus> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final closed = order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled;
    final canPrepare = order.status == OrderStatus.received ||
        order.status == OrderStatus.confirmed;
    final canSend = order.deliveryType == DeliveryType.delivery && !closed;
    final canDeliver = !closed;
    final canCancel = !closed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;

        return Column(
          crossAxisAlignment:
              compact ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: compact ? WrapAlignment.start : WrapAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: canPrepare
                      ? () => onStatusChange(OrderStatus.preparing)
                      : null,
                  icon: const Icon(Icons.restaurant_menu_outlined),
                  label: const Text('Aceitar / Preparar'),
                ),
                OutlinedButton.icon(
                  onPressed: canSend
                      ? () => onStatusChange(OrderStatus.outForDelivery)
                      : null,
                  icon: const Icon(Icons.delivery_dining_outlined),
                  label: const Text('Saiu para entrega'),
                ),
                OutlinedButton.icon(
                  onPressed: canDeliver
                      ? () => onStatusChange(OrderStatus.delivered)
                      : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Marcar entregue'),
                ),
                TextButton.icon(
                  onPressed: canCancel
                      ? () => onStatusChange(OrderStatus.cancelled)
                      : null,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB6462F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ManualStatusDropdown(
              value: order.status,
              onChanged: onStatusChange,
            ),
          ],
        );
      },
    );
  }
}

class _ManualStatusDropdown extends StatelessWidget {
  const _ManualStatusDropdown({
    required this.value,
    required this.onChanged,
  });

  final OrderStatus value;
  final ValueChanged<OrderStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADFD4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OrderStatus>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: OrderStatus.values
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(_statusLabel(status)),
                ),
              )
              .toList(),
          onChanged: (status) {
            if (status == null) return;
            onChanged(status);
          },
        ),
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEADFD4)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF7B2E1F),
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              'Nenhum pedido encontrado',
              style: TextStyle(
                color: Color(0xFF2B1D18),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ajuste a busca ou troque o filtro.',
              style: TextStyle(color: Color(0xFF7E6A62)),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortOrderCode(String id) {
  final value = id.trim();
  if (value.isEmpty) return 'SEM-ID';
  return (value.length <= 8 ? value : value.substring(0, 8)).toUpperCase();
}

String _dateTimeLabel(DateTime? value) {
  if (value == null) return 'Sem data registrada';
  final local = value.toLocal();
  final date = DateFormat('dd/MM/yyyy', 'pt_BR').format(local);
  final time = DateFormat('HH:mm', 'pt_BR').format(local);
  return '$date • $time';
}

String _fullAddress(AddressModel address) {
  final parts = [
    '${address.street}, ${address.number}',
    '${address.neighborhood} • ${address.city} - ${address.state}',
    if (address.zipCode.trim().isNotEmpty) 'CEP: ${address.zipCode}',
    if ((address.complement ?? '').trim().isNotEmpty)
      'Complemento: ${address.complement}',
    if ((address.reference ?? '').trim().isNotEmpty)
      'Referência: ${address.reference}',
  ];

  return parts.join('\n');
}

String _deliveryTypeLabel(DeliveryType type) {
  switch (type) {
    case DeliveryType.delivery:
      return 'Entrega';
    case DeliveryType.pickup:
      return 'Retirada';
    case DeliveryType.dineIn:
      return 'Presencial';
  }
}

IconData _deliveryTypeIcon(DeliveryType type) {
  switch (type) {
    case DeliveryType.delivery:
      return Icons.delivery_dining_outlined;
    case DeliveryType.pickup:
      return Icons.storefront_outlined;
    case DeliveryType.dineIn:
      return Icons.table_restaurant_outlined;
  }
}

String _paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.notSelected:
      return 'A definir';
    case PaymentMethod.pix:
      return 'PIX';
    case PaymentMethod.cash:
      return 'Dinheiro';
    case PaymentMethod.creditCard:
      return 'Crédito';
    case PaymentMethod.debitCard:
      return 'Débito';
    case PaymentMethod.pixOnDelivery:
      return 'Pix';
    case PaymentMethod.pixApp:
      return 'Pix app';
  }
}

String _paymentStatusLabel(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.pending:
      return 'Pendente';
    case PaymentStatus.paid:
      return 'Pago';
    case PaymentStatus.approved:
      return 'Aprovado';
    case PaymentStatus.rejected:
      return 'Recusado';
    case PaymentStatus.cancelled:
      return 'Cancelado';
  }
}

String _statusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.received:
      return 'Recebido';
    case OrderStatus.confirmed:
      return 'Confirmado';
    case OrderStatus.preparing:
      return 'Em preparo';
    case OrderStatus.outForDelivery:
      return 'Saiu para entrega';
    case OrderStatus.delivered:
      return 'Entregue';
    case OrderStatus.cancelled:
      return 'Cancelado';
  }
}

Color _statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.received:
      return const Color(0xFFB6462F);
    case OrderStatus.confirmed:
    case OrderStatus.preparing:
      return const Color(0xFFD7A552);
    case OrderStatus.outForDelivery:
      return const Color(0xFF2563EB);
    case OrderStatus.delivered:
      return const Color(0xFF2F7D46);
    case OrderStatus.cancelled:
      return const Color(0xFF8A3A3A);
  }
}
