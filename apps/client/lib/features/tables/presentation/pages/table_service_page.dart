import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/core/widgets/ray_brand.dart';
import 'package:rayssa_client/features/tables/presentation/providers/table_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';

class TableServicePage extends ConsumerWidget {
  const TableServicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _leaveServiceMode(context),
        ),
        title: const Text('Atendimento presencial'),
        actions: [
          TextButton.icon(
            onPressed: () => _leaveServiceMode(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sair'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: tablesAsync.when(
        data: (tables) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const _ServiceIntro(),
              const SizedBox(height: 16),
              Text(
                'Mesas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tables.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return _TableCard(
                    table: table,
                    totalLabel: currency.format(table.currentTotal),
                    onTap: () => context.push('/tables/${table.id}'),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'Não foi possível carregar as mesas: $error',
        ),
      ),
    );
  }
}

class _ServiceIntro extends StatelessWidget {
  const _ServiceIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.chocolate,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const RayBrandMark(size: 52, onDark: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo Atendimento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.warmWhite,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Abra comandas, envie pedidos para preparo e acompanhe o total de cada mesa.',
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

void _leaveServiceMode(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  context.go('/profile');
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.table,
    required this.totalLabel,
    required this.onTap,
  });

  final TableModel table;
  final String totalLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(table.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.table_restaurant, color: color),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppTheme.muted),
                ],
              ),
              const Spacer(),
              Text(
                table.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                table.status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              if (table.currentTotal > 0) ...[
                const SizedBox(height: 6),
                Text(
                  totalLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.deepRed,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

Color _statusColor(TableStatus status) {
  switch (status) {
    case TableStatus.free:
      return AppTheme.success;
    case TableStatus.open:
      return AppTheme.primaryRed;
    case TableStatus.preparing:
      return AppTheme.warning;
    case TableStatus.waitingPayment:
      return AppTheme.deepRed;
  }
}
