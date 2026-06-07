import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('Acompanhar pedido')),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Pedido não encontrado'));
          }

          final currentStep = _statusIndex(order.status);
          final address = order.address;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _TrackingHero(
                order: order,
                total: currency.format(order.total),
              ),
              const SizedBox(height: 14),
              if (order.status == OrderStatus.cancelled)
                const _CancelledCard()
              else
                _TrackingTimeline(currentStep: currentStep),
              const SizedBox(height: 14),
              _InfoCard(
                icon: Icons.restaurant_menu,
                title: 'Itens do pedido',
                child: Column(
                  children: [
                    ...order.items.map(
                      (item) => _ItemRow(
                        label: '${item.quantity}x ${item.name}',
                        value: currency.format(item.subtotal),
                      ),
                    ),
                  ],
                ),
              ),
              _InfoCard(
                icon: Icons.payments_outlined,
                title: 'Resumo',
                child: Column(
                  children: [
                    _ItemRow(
                      label: 'Pagamento',
                      value: order.paymentMethod.label,
                    ),
                    const SizedBox(height: 8),
                    _ItemRow(
                      label: 'Status do pagamento',
                      value: order.paymentStatus.label,
                    ),
                    if (order.changeFor != null) ...[
                      const SizedBox(height: 8),
                      _ItemRow(
                        label: 'Troco para',
                        value: currency.format(order.changeFor),
                      ),
                    ],
                    const Divider(),
                    _ItemRow(
                      label: 'Subtotal',
                      value: currency.format(order.subtotal),
                    ),
                    const SizedBox(height: 8),
                    _ItemRow(
                      label: 'Taxa de entrega',
                      value: currency.format(order.deliveryFee),
                    ),
                    const Divider(),
                    _ItemRow(
                      label: 'Total',
                      value: currency.format(order.total),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              if (address != null)
                _InfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'Endereço de entrega',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${address.street}, ${address.number}'),
                      const SizedBox(height: 4),
                      Text(
                        '${address.neighborhood} • ${address.city} - ${address.state}',
                      ),
                      if ((address.complement ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Complemento: ${address.complement}'),
                      ],
                    ],
                  ),
                ),
              if ((order.notes ?? '').isNotEmpty)
                _InfoCard(
                  icon: Icons.edit_note,
                  title: 'Observações',
                  child: Text(order.notes!),
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

class _TrackingHero extends StatelessWidget {
  const _TrackingHero({required this.order, required this.total});

  final OrderModel order;
  final String total;

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: cancelled
              ? [AppTheme.muted, AppTheme.ink]
              : [AppTheme.chocolate, AppTheme.deepRed, AppTheme.primaryRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -18,
            child: Icon(
              Icons.bakery_dining,
              color: AppTheme.cream.withOpacity(0.1),
              size: 128,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pedido #${order.id.substring(0, 8)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.cream,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusHeadline(order.status),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.warmWhite,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _statusMessage(order.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.cream.withOpacity(0.82),
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroMeta(icon: Icons.pix, label: order.paymentStatus.label),
                  _HeroMeta(
                    icon: Icons.delivery_dining,
                    label: order.deliveryType.label,
                  ),
                  _HeroMeta(icon: Icons.payments_outlined, label: total),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusHeadline(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return 'Pedido recebido';
      case OrderStatus.confirmed:
        return 'Pedido confirmado';
      case OrderStatus.preparing:
        return 'A Ray está preparando';
      case OrderStatus.outForDelivery:
        return 'Saiu para entrega';
      case OrderStatus.delivered:
        return 'Pedido entregue';
      case OrderStatus.cancelled:
        return 'Pedido cancelado';
    }
  }

  String _statusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return 'A cozinha já recebeu seu pedido.';
      case OrderStatus.confirmed:
        return 'Agora é só aguardar o preparo começar.';
      case OrderStatus.preparing:
        return 'Seu pedido está ganhando aquele cuidado artesanal.';
      case OrderStatus.outForDelivery:
        return 'As delícias da Ray estão a caminho.';
      case OrderStatus.delivered:
        return 'Obrigada por pedir com a Lanchonete da Ray.';
      case OrderStatus.cancelled:
        return 'Este pedido não seguirá para preparo.';
    }
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.gold, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.warmWhite,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.currentStep});

  final int currentStep;

  static const _steps = [
    ('Recebido', 'A Ray recebeu seu pedido.'),
    ('Confirmado', 'Tudo certo para começar.'),
    ('Em preparo', 'Seu pedido está sendo feito.'),
    ('Saiu para entrega', 'Está a caminho de você.'),
    ('Entregue', 'Pedido finalizado.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var index = 0; index < _steps.length; index++)
              _TimelineStep(
                title: _steps[index].$1,
                subtitle: _steps[index].$2,
                active: index <= currentStep,
                last: index == _steps.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.last,
  });

  final String title;
  final String subtitle;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.primaryRed : AppTheme.line;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                active ? Icons.check : Icons.circle,
                size: active ? 16 : 8,
                color: active ? AppTheme.warmWhite : AppTheme.muted,
              ),
            ),
            if (!last)
              Container(
                width: 2,
                height: 42,
                color: color,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelledCard extends StatelessWidget {
  const _CancelledCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.line,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.cancel_outlined, color: AppTheme.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Este pedido foi cancelado.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppTheme.primaryRed, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.deepRed,
              fontWeight: FontWeight.w900,
            )
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 12),
        Text(value, style: style),
      ],
    );
  }
}
