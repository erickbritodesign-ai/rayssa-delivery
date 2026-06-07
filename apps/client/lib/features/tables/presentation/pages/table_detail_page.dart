import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/features/tables/presentation/providers/table_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';

class TableDetailPage extends ConsumerWidget {
  const TableDetailPage({required this.tableId, super.key});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(tableSessionProvider(tableId));
    final tablesAsync = ref.watch(tablesProvider);
    final table = tablesAsync.maybeWhen(
      data: (tables) => tables.firstWhere(
        (table) => table.id == tableId,
        orElse: () => TableModel.fallback(_tableNumberFromId(tableId)),
      ),
      orElse: () => TableModel.fallback(_tableNumberFromId(tableId)),
    );
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: Text(table.name)),
      body: sessionAsync.when(
        data: (session) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _TableHeader(
                tableName: table.name,
                statusLabel: session?.status.label ?? 'Livre',
                totalLabel: currency.format(session?.total ?? 0),
                hasSession: session != null,
              ),
              const SizedBox(height: 14),
              _CommandCard(session: session, currency: currency),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => context.push('/tables/$tableId/add'),
                icon: const Icon(Icons.add),
                label: Text(
                  session == null ? 'Abrir comanda' : 'Adicionar itens',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: session == null || session.items.isEmpty
                    ? null
                    : () => _markPreparing(context, ref, session),
                icon: const Icon(Icons.restaurant_menu_outlined),
                label: const Text('Enviar para preparo'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: session == null || session.items.isEmpty
                    ? null
                    : () => _markWaitingPayment(context, ref, session),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Aguardar pagamento'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: session == null || session.items.isEmpty
                    ? null
                    : () => _closeAccount(context, ref, session),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Fechar conta'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Falha ao carregar a comanda: $error'),
          ),
        ),
      ),
    );
  }

  Future<void> _markPreparing(
    BuildContext context,
    WidgetRef ref,
    TableSessionModel session,
  ) async {
    try {
      await ref.read(tableServiceProvider).markPreparing(session);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comanda enviada para preparo.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao enviar para preparo: $error')),
      );
    }
  }

  Future<void> _markWaitingPayment(
    BuildContext context,
    WidgetRef ref,
    TableSessionModel session,
  ) async {
    try {
      await ref.read(tableServiceProvider).markWaitingPayment(session);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesa aguardando pagamento.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar a mesa: $error')),
      );
    }
  }

  Future<void> _closeAccount(
    BuildContext context,
    WidgetRef ref,
    TableSessionModel session,
  ) async {
    final result = await showModalBottomSheet<_ClosePayment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CloseAccountSheet(session: session),
    );

    if (result == null) return;

    try {
      await ref.read(tableServiceProvider).closeSession(
            session: session,
            paymentMethod: result.method,
            changeFor: result.changeFor,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta fechada com sucesso. Mesa liberada.'),
        ),
      );
      context.go('/tables');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao fechar a conta: $error')),
      );
    }
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.tableName,
    required this.statusLabel,
    required this.totalLabel,
    required this.hasSession,
  });

  final String tableName;
  final String statusLabel;
  final String totalLabel;
  final bool hasSession;

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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.warmWhite.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.table_restaurant,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tableName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.warmWhite,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.cream,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          if (hasSession)
            Text(
              totalLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                  ),
            ),
        ],
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  const _CommandCard({
    required this.session,
    required this.currency,
  });

  final TableSessionModel? session;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final current = session;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: current == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesa livre',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Abra uma comanda para começar a adicionar itens.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comanda',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (current.items.isEmpty)
                    Text(
                      'Nenhum item nesta comanda.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    ...current.items.map(
                      (item) => _CommandItemRow(
                        label: '${item.quantity}x ${item.name}',
                        value: currency.format(item.subtotal),
                      ),
                    ),
                  const Divider(),
                  _CommandItemRow(
                    label: 'Total parcial',
                    value: currency.format(current.total),
                    emphasized: true,
                  ),
                ],
              ),
      ),
    );
  }
}

class _CommandItemRow extends StatelessWidget {
  const _CommandItemRow({
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
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w900,
            )
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ClosePayment {
  const _ClosePayment({required this.method, this.changeFor});

  final PaymentMethod method;
  final double? changeFor;
}

class _CloseAccountSheet extends StatefulWidget {
  const _CloseAccountSheet({required this.session});

  final TableSessionModel session;

  @override
  State<_CloseAccountSheet> createState() => _CloseAccountSheetState();
}

class _CloseAccountSheetState extends State<_CloseAccountSheet> {
  final _changeForController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  bool _needsChange = false;

  @override
  void dispose() {
    _changeForController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: colors.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.38 : 0.12,
              ),
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fechar conta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Total da mesa: ${currency.format(widget.session.total)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.78),
                    ),
              ),
              const SizedBox(height: 16),
              _PaymentChoice(
                label: 'Dinheiro',
                method: PaymentMethod.cash,
                selected: _method,
                onSelected: _selectMethod,
              ),
              _PaymentChoice(
                label: 'Cartão de crédito',
                method: PaymentMethod.creditCard,
                selected: _method,
                onSelected: _selectMethod,
              ),
              _PaymentChoice(
                label: 'Cartão de débito',
                method: PaymentMethod.debitCard,
                selected: _method,
                onSelected: _selectMethod,
              ),
              _PaymentChoice(
                label: 'Pix',
                method: PaymentMethod.pix,
                selected: _method,
                onSelected: _selectMethod,
              ),
              if (_method == PaymentMethod.cash) ...[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Precisa de troco?'),
                  value: _needsChange,
                  onChanged: (value) => setState(() => _needsChange = value),
                ),
                if (_needsChange)
                  TextField(
                    controller: _changeForController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Troco para quanto?',
                      prefixText: 'R\$ ',
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check),
                label: const Text('Confirmar pagamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMethod(PaymentMethod method) {
    setState(() => _method = method);
  }

  void _confirm() {
    double? changeFor;
    if (_method == PaymentMethod.cash && _needsChange) {
      changeFor = _parseMoney(_changeForController.text);
      if (changeFor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o valor para troco.')),
        );
        return;
      }
    }

    Navigator.of(context).pop(
      _ClosePayment(method: _method, changeFor: changeFor),
    );
  }
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    required this.label,
    required this.method,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final PaymentMethod method;
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RadioListTile<PaymentMethod>(
      contentPadding: EdgeInsets.zero,
      value: method,
      groupValue: selected,
      activeColor: colors.secondary,
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.secondary;
        return colors.onSurface.withOpacity(0.72);
      }),
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      title: Text(
        label,
        style: TextStyle(color: colors.onSurface),
      ),
    );
  }
}

int _tableNumberFromId(String tableId) {
  final match = RegExp(r'\d+').firstMatch(tableId);
  return int.tryParse(match?.group(0) ?? '') ?? 1;
}

double? _parseMoney(String text) {
  final normalized = text
      .replaceAll('R\$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();
  return double.tryParse(normalized);
}
