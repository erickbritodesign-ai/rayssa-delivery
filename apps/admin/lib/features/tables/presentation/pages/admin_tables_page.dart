import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final adminTablesProvider = StreamProvider<List<TableModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchTables();
});

final adminTableSessionProvider =
    StreamProvider.family<TableSessionModel?, String>((ref, tableId) {
  return ref.watch(adminFirestoreProvider).watchOpenTableSession(tableId);
});

class AdminTablesPage extends ConsumerWidget {
  const AdminTablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(adminTablesProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Mesas')),
      body: tablesAsync.when(
        data: (tables) => LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 760;
            final crossAxisCount =
                isMobile ? 2 : (constraints.maxWidth ~/ 240).clamp(3, 5);

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
              itemCount: tables.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount.toInt(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isMobile ? 0.82 : 1.08,
              ),
              itemBuilder: (context, index) {
                final table = tables[index];
                return _AdminTableCard(
                  table: table,
                  totalLabel: currency.format(table.currentTotal),
                  onTap: () => _showTableDialog(context, table),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }

  void _showTableDialog(
    BuildContext context,
    TableModel table,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => _AdminTableDialog(table: table),
    );
  }
}

class _AdminTableCard extends StatelessWidget {
  const _AdminTableCard({
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_restaurant, color: color),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: color.withOpacity(0.65),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                table.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              _StatusChip(label: table.status.label, color: color),
              const Spacer(),
              if (table.currentTotal > 0) ...[
                Text(
                  totalLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFB6462F),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AdminTableDialog extends ConsumerWidget {
  const _AdminTableDialog({required this.table});

  final TableModel table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(adminTableSessionProvider(table.id));
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.82;

    return SafeArea(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: SizedBox(
          width: 520,
          height: dialogHeight,
          child: sessionAsync.when(
            data: (session) => Column(
              children: [
                _DialogHeader(
                  title: table.name,
                  subtitle:
                      'Status: ${session?.status.label ?? table.status.label}',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                    child: session == null
                        ? const _EmptyTableState()
                        : _TableSessionContent(
                            session: session,
                            totalLabel: currency.format(session.total),
                            currency: currency,
                          ),
                  ),
                ),
                if (session != null)
                  _TableDialogActions(
                    onStatusSelected: (status) => _updateStatus(
                      context,
                      ref,
                      session,
                      status,
                    ),
                  ),
              ],
            ),
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Erro: $error'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    TableSessionModel session,
    TableSessionStatus status,
  ) async {
    try {
      await ref
          .read(adminFirestoreProvider)
          .updateTableSessionStatus(session, status);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesa atualizada para ${status.label}.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar mesa: $error')),
      );
    }
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Mesa livre, sem comanda aberta.',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TableSessionContent extends StatelessWidget {
  const _TableSessionContent({
    required this.session,
    required this.totalLabel,
    required this.currency,
  });

  final TableSessionModel session;
  final String totalLabel;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comanda',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        if (session.items.isEmpty)
          const Text('Esta comanda ainda não possui itens.')
        else
          for (final item in session.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    currency.format(item.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
        const Divider(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              totalLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFB6462F),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TableDialogActions extends StatelessWidget {
  const _TableDialogActions({
    required this.onStatusSelected,
  });

  final ValueChanged<TableSessionStatus> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEADFD6))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusButton(
              label: 'Aberta',
              onPressed: () => onStatusSelected(TableSessionStatus.open),
            ),
            _StatusButton(
              label: 'Em preparo',
              onPressed: () => onStatusSelected(TableSessionStatus.preparing),
            ),
            _StatusButton(
              label: 'Aguardando pagamento',
              onPressed: () =>
                  onStatusSelected(TableSessionStatus.waitingPayment),
            ),
            _StatusButton(
              label: 'Encerrar mesa',
              onPressed: () => onStatusSelected(TableSessionStatus.closed),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

Color _statusColor(TableStatus status) {
  switch (status) {
    case TableStatus.free:
      return const Color(0xFF2E7D4F);
    case TableStatus.open:
      return const Color(0xFF7B2E1F);
    case TableStatus.preparing:
      return const Color(0xFFE6A12A);
    case TableStatus.waitingPayment:
      return const Color(0xFFB6462F);
  }
}
