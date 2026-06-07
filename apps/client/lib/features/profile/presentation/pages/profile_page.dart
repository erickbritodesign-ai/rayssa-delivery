import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/core/theme/theme_mode_controller.dart';
import 'package:rayssa_client/core/widgets/ray_brand.dart';
import 'package:rayssa_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:rayssa_client/features/orders/presentation/providers/order_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({this.showAccessDeniedMessage = false, super.key});

  final bool showAccessDeniedMessage;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _accessMessageShown = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado.'));
          }

          _showAccessDeniedMessageIfNeeded();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: 14),
              const _ThemeModeCard(),
              const SizedBox(height: 14),
              _RayLoyaltyCard(
                points: user.loyaltyPoints,
                onRefresh: () => _refreshLoyaltyPoints(context),
              ),
              if (user.canAccessTableService) ...[
                const SizedBox(height: 14),
                _ServiceModeCard(onTap: () => context.push('/tables')),
              ],
              const SizedBox(height: 14),
              _OrdersHistory(
                ordersAsync: ordersAsync,
                onOpenOrder: (orderId) => context.push('/orders/$orderId'),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Não foi possível carregar sua conta: $error'),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) context.go('/login');
  }

  void _showAccessDeniedMessageIfNeeded() {
    if (!widget.showAccessDeniedMessage || _accessMessageShown) return;
    _accessMessageShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acesso restrito a funcionários.')),
      );
    });
  }

  void _refreshLoyaltyPoints(BuildContext context) {
    ref.invalidate(currentUserProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pontos atualizados.')),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final name = user.name.trim().isEmpty ? 'Cliente da Ray' : user.name.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.chocolate,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const RayBrandMark(size: 56, onDark: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.warmWhite,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                if (user.email.trim().isNotEmpty)
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.cream,
                        ),
                  ),
                if (user.phone.trim().isNotEmpty)
                  Text(
                    user.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.cream,
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

class _ThemeModeCard extends ConsumerWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(darkThemeEnabledProvider);

    return Card(
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: enabled ? AppTheme.darkCardSoft : AppTheme.cream,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            enabled ? Icons.dark_mode : Icons.light_mode,
            color: enabled ? AppTheme.gold : AppTheme.primaryRed,
          ),
        ),
        title: const Text('Tema escuro'),
        subtitle: const Text('Visual premium para usar à noite.'),
        value: enabled,
        onChanged: (value) {
          ref.read(darkThemeEnabledProvider.notifier).state = value;
        },
      ),
    );
  }
}

class _ServiceModeCard extends StatelessWidget {
  const _ServiceModeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.table_restaurant_outlined,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo Atendimento',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Abrir mesas, montar comandas e fechar conta.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RayLoyaltyCard extends StatelessWidget {
  const _RayLoyaltyCard({
    required this.points,
    required this.onRefresh,
  });

  final int points;
  final VoidCallback onRefresh;

  static const _rewards = [
    _RayReward(
      points: 50,
      title: '50 pontos',
      benefit: 'R\$ 3,00 de desconto ou brinde definido pela Ray',
    ),
    _RayReward(
      points: 100,
      title: '100 pontos',
      benefit: 'R\$ 5,00 de desconto no próximo pedido',
    ),
    _RayReward(
      points: 150,
      title: '150 pontos',
      benefit: 'Salgado simples grátis',
    ),
    _RayReward(
      points: 200,
      title: '200 pontos',
      benefit: 'R\$ 10,00 de desconto',
    ),
    _RayReward(
      points: 300,
      title: '300 pontos',
      benefit: 'Pastel selecionado grátis',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? colors.secondary : AppTheme.deepRed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: dark ? AppTheme.darkCardSoft : AppTheme.cream,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: colors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fidelidade da Ray',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Válido para Delivery e Retirada.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$points pts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, size: 15),
                      label: const Text('Atualizar'),
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Você tem $points pontos.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'A cada R\$ 1,00 em pedidos pelo app, você ganha 1 ponto.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            for (final reward in _rewards) ...[
              _RayRewardTile(points: points, reward: reward),
              if (reward != _rewards.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark ? AppTheme.darkCardSoft : AppTheme.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                'Resgate em breve pelo app. Benefícios serão confirmados pela Ray.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.76),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RayReward {
  const _RayReward({
    required this.points,
    required this.title,
    required this.benefit,
  });

  final int points;
  final String title;
  final String benefit;
}

class _RayRewardTile extends StatelessWidget {
  const _RayRewardTile({required this.points, required this.reward});

  final int points;
  final _RayReward reward;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final available = points >= reward.points;
    final missing = reward.points - points;
    final accent = dark ? colors.secondary : AppTheme.deepRed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: available
            ? (dark ? AppTheme.darkCardSoft : AppTheme.blush)
            : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: available ? accent.withOpacity(0.42) : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: available ? accent : colors.outlineVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              available ? Icons.check : Icons.lock_outline,
              color: available
                  ? (dark ? AppTheme.ink : AppTheme.warmWhite)
                  : colors.onSurface.withOpacity(0.6),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward.benefit,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            available ? 'Disponível' : 'Faltam $missing',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: available ? accent : colors.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class LegacyLoyaltyCard extends StatelessWidget {
  const LegacyLoyaltyCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fidelidade',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$points pts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.deepRed,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              points == 0
                  ? 'Seu carinho pela Ray vai aparecer aqui em pontos quando a fidelidade for configurada.'
                  : 'Continue pedindo pelo app para acompanhar seus benefícios.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            _RewardHint(
              icon: Icons.local_offer_outlined,
              text: 'Benefícios definidos pela Ray no Admin.',
            ),
            const SizedBox(height: 6),
            _RewardHint(
              icon: Icons.favorite_border,
              text: 'TODO: configurar regras como 1 ponto a cada R\$ X.',
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardHint extends StatelessWidget {
  const _RewardHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryRed, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _OrdersHistory extends StatelessWidget {
  const _OrdersHistory({
    required this.ordersAsync,
    required this.onOpenOrder,
  });

  final AsyncValue<List<OrderModel>> ordersAsync;
  final ValueChanged<String> onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Histórico de pedidos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return Text(
                    'Seus pedidos pelo app vão aparecer aqui.',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }

                return Column(
                  children: [
                    for (final order in orders)
                      _HistoryOrderTile(
                        order: order,
                        total: currency.format(order.total),
                        onTap: () => onOpenOrder(order.id),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                'Não foi possível carregar o histórico agora. Tente novamente em alguns instantes.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryOrderTile extends StatelessWidget {
  const _HistoryOrderTile({
    required this.order,
    required this.total,
    required this.onTap,
  });

  final OrderModel order;
  final String total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppTheme.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${_shortOrderId(order.id)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDate(order.createdAt)} • ${order.status.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.deepRed,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortOrderId(String id) {
  if (id.length <= 6) return id;
  return id.substring(0, 6);
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Data em processamento';

  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
}
