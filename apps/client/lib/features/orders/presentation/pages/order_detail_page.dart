import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _leaveOrderDetail(context),
        ),
        title: const Text('Acompanhar pedido'),
      ),
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
                _TrackingTimeline(
                  currentStep: currentStep,
                  deliveryType: order.deliveryType,
                ),
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
              if (order.deliveryType == DeliveryType.dineIn)
                _InfoCard(
                  icon: Icons.table_restaurant_outlined,
                  title: 'Consumo no local',
                  child: Text(
                    order.tableNumber == null
                        ? 'Mesa não informada'
                        : 'Mesa ${order.tableNumber}',
                  ),
                ),
              if ((order.notes ?? '').isNotEmpty)
                _InfoCard(
                  icon: Icons.edit_note,
                  title: 'Observações',
                  child: Text(order.notes!),
                ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.restaurant_menu_outlined),
                label: const Text('Voltar ao card\u00e1pio'),
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

void _leaveOrderDetail(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  context.go('/');
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
                _statusHeadline(order),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.warmWhite,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _statusMessage(order),
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
                    icon: _deliveryTypeIcon(order.deliveryType),
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

  IconData _deliveryTypeIcon(DeliveryType deliveryType) {
    switch (deliveryType) {
      case DeliveryType.delivery:
        return Icons.delivery_dining;
      case DeliveryType.pickup:
        return Icons.storefront;
      case DeliveryType.dineIn:
        return Icons.table_restaurant;
    }
  }

  String _statusHeadline(OrderModel order) {
    switch (order.status) {
      case OrderStatus.received:
        return 'Pedido recebido';
      case OrderStatus.confirmed:
        return 'Pedido confirmado';
      case OrderStatus.preparing:
        return 'A Ray está preparando';
      case OrderStatus.outForDelivery:
        if (order.deliveryType == DeliveryType.pickup) {
          return 'Pronto para retirada';
        }
        if (order.deliveryType == DeliveryType.dineIn) {
          return 'Servido na mesa';
        }
        return 'Saiu para entrega';
      case OrderStatus.delivered:
        if (order.deliveryType == DeliveryType.pickup) {
          return 'Pedido retirado';
        }
        if (order.deliveryType == DeliveryType.dineIn) {
          return 'Atendimento finalizado';
        }
        return 'Pedido entregue';
      case OrderStatus.cancelled:
        return 'Pedido cancelado';
    }
  }

  String _statusMessage(OrderModel order) {
    switch (order.status) {
      case OrderStatus.received:
        return 'A cozinha já recebeu seu pedido.';
      case OrderStatus.confirmed:
        return 'Agora é só aguardar o preparo começar.';
      case OrderStatus.preparing:
        return 'Seu pedido está ganhando aquele cuidado artesanal.';
      case OrderStatus.outForDelivery:
        if (order.deliveryType == DeliveryType.pickup) {
          return 'Pode buscar seu pedido na Lanchonete da Ray.';
        }
        if (order.deliveryType == DeliveryType.dineIn) {
          return 'Seu pedido foi levado at\u00e9 a mesa.';
        }
        return 'As delícias da Ray estão a caminho.';
      case OrderStatus.delivered:
        if (order.deliveryType == DeliveryType.pickup) {
          return 'Obrigada por retirar seu pedido com a Ray.';
        }
        if (order.deliveryType == DeliveryType.dineIn) {
          return 'Obrigada por consumir na Lanchonete da Ray.';
        }
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
  const _TrackingTimeline({
    required this.currentStep,
    required this.deliveryType,
  });

  final int currentStep;
  final DeliveryType deliveryType;

  @override
  Widget build(BuildContext context) {
    final steps = _trackingStepsFor(deliveryType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var index = 0; index < steps.length; index++)
              _TimelineStep(
                title: steps[index].$1,
                subtitle: steps[index].$2,
                active: index <= currentStep,
                last: index == steps.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

List<(String, String)> _trackingStepsFor(DeliveryType deliveryType) {
  switch (deliveryType) {
    case DeliveryType.delivery:
      return const [
        ('Recebido', 'A Ray recebeu seu pedido.'),
        ('Confirmado', 'Tudo certo para come\u00e7ar.'),
        ('Em preparo', 'Seu pedido est\u00e1 sendo feito.'),
        ('Saiu para entrega', 'Est\u00e1 a caminho de voc\u00ea.'),
        ('Entregue', 'Pedido finalizado.'),
      ];
    case DeliveryType.pickup:
      return const [
        ('Recebido', 'A Ray recebeu seu pedido.'),
        ('Confirmado', 'Tudo certo para come\u00e7ar.'),
        ('Em preparo', 'Seu pedido est\u00e1 sendo feito.'),
        ('Pronto para retirada', 'Pode buscar na Lanchonete da Ray.'),
        ('Retirado', 'Pedido finalizado.'),
      ];
    case DeliveryType.dineIn:
      return const [
        ('Recebido', 'A Ray recebeu seu pedido.'),
        ('Confirmado', 'Tudo certo para come\u00e7ar.'),
        ('Em preparo', 'Seu pedido est\u00e1 sendo feito.'),
        ('Servido na mesa', 'Seu pedido foi levado at\u00e9 a mesa.'),
        ('Finalizado', 'Atendimento conclu\u00eddo.'),
      ];
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
