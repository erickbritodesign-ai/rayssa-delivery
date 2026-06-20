import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_admin/features/orders/utils/order_receipt_formatter.dart';
import 'package:rayssa_admin/features/orders/widgets/print_order_dialog.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final adminTablesProvider = StreamProvider<List<TableModel>>((ref) {
  final settings = ref.watch(storeSettingsForTablesProvider).valueOrNull;
  final count = ((settings?['tableCount'] as num?)?.toInt() ?? 10).clamp(1, 99);
  return ref.watch(adminFirestoreProvider).watchTables(count: count);
});

final storeSettingsForTablesProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminFirestoreProvider).watchStoreSettings();
});

final adminTableSessionProvider =
    StreamProvider.family<TableSessionModel?, String>((ref, tableId) {
  return ref.watch(adminFirestoreProvider).watchOpenTableSession(tableId);
});

final adminTableProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchProducts();
});

final adminTableCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchCategories();
});

class AdminTablesPage extends ConsumerStatefulWidget {
  const AdminTablesPage({super.key});

  @override
  ConsumerState<AdminTablesPage> createState() => _AdminTablesPageState();
}

class _AdminTablesPageState extends ConsumerState<AdminTablesPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      try {
        final settings = await ref.read(storeSettingsForTablesProvider.future);
        final count =
            ((settings['tableCount'] as num?)?.toInt() ?? 10).clamp(1, 99);
        await ref
            .read(adminFirestoreProvider)
            .ensureDefaultTables(count: count);
      } catch (_) {
        // As mesas fallback continuam disponíveis mesmo sem essa gravação.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(adminTablesProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Mesas')),
      body: tablesAsync.when(
        data: (tables) => LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final columns =
                compact ? 2 : (constraints.maxWidth ~/ 240).clamp(3, 5);
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
              itemCount: tables.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns.toInt(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: compact ? 0.82 : 1.08,
              ),
              itemBuilder: (context, index) {
                final table = tables[index];
                return _TableCard(
                  table: table,
                  totalLabel: currency.format(table.currentTotal),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => _TableDialog(table: table),
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Carregando mesas...'),
            ],
          ),
        ),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }
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
                    color: color.withValues(alpha: .65),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                table.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              _StatusChip(label: table.status.label, color: color),
              const Spacer(),
              if (table.currentTotal > 0)
                Text(
                  totalLabel,
                  style: const TextStyle(
                    color: Color(0xFFB6462F),
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TableDialog extends ConsumerWidget {
  const _TableDialog({required this.table});

  final TableModel table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(adminTableSessionProvider(table.id));
    final products =
        ref.watch(adminTableProductsProvider).valueOrNull ?? const [];
    final categories =
        ref.watch(adminTableCategoriesProvider).valueOrNull ?? const [];
    final height = MediaQuery.sizeOf(context).height * .9;

    return SafeArea(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: SizedBox(
          width: 720,
          height: height,
          child: sessionAsync.when(
            data: (session) => session == null
                ? _OpenTableView(
                    table: table,
                    products: products,
                    categories: categories,
                  )
                : _OpenSessionView(
                    table: table,
                    session: session,
                    products: products,
                    categories: categories,
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erro: $error')),
          ),
        ),
      ),
    );
  }
}

class _OpenTableView extends ConsumerStatefulWidget {
  const _OpenTableView({
    required this.table,
    required this.products,
    required this.categories,
  });

  final TableModel table;
  final List<ProductModel> products;
  final List<CategoryModel> categories;

  @override
  ConsumerState<_OpenTableView> createState() => _OpenTableViewState();
}

class _OpenTableViewState extends ConsumerState<_OpenTableView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DialogHeader(
          title: widget.table.name,
          subtitle: 'Mesa livre',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.table_restaurant_outlined,
                  size: 54,
                  color: Color(0xFF2E7D4F),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do cliente (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _openTable,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: const Text('Abrir mesa'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openTable() async {
    setState(() => _saving = true);
    try {
      final session = await ref.read(adminFirestoreProvider).openTable(
            table: widget.table,
            guestName: _nameController.text,
            guestPhone: _phoneController.text,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _OrderEditorDialog(
          session: session,
          products: widget.products,
          categories: widget.categories,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao abrir mesa: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _OpenSessionView extends ConsumerWidget {
  const _OpenSessionView({
    required this.table,
    required this.session,
    required this.products,
    required this.categories,
  });

  final TableModel table;
  final TableSessionModel session;
  final List<ProductModel> products;
  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Column(
      children: [
        _DialogHeader(
          title: table.name,
          subtitle:
              'Pedido #${OrderReceiptFormatter.shortOrderCode(_orderId)} · ${session.status.label}',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.person_outline,
                    label: _displayValue(session.guestName),
                  ),
                  _InfoPill(
                    icon: Icons.phone_outlined,
                    label: _displayValue(session.guestPhone),
                  ),
                  _InfoPill(
                    icon: Icons.receipt_long_outlined,
                    label: '${session.items.length} produto(s)',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (session.items.isEmpty)
                const _EmptyItemsCard()
              else
                ...session.items.map(
                  (item) => _SessionItemCard(
                    item: item,
                    price: currency.format(item.subtotal),
                  ),
                ),
              if ((session.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _NotesCard(notes: session.notes!.trim()),
              ],
              const SizedBox(height: 16),
              _TotalCard(
                subtotal: currency.format(session.subtotal),
                total: currency.format(session.total),
              ),
            ],
          ),
        ),
        _SessionActions(
          canPrint: session.items.isNotEmpty,
          canClose: session.items.isNotEmpty,
          onEdit: () => showDialog<void>(
            context: context,
            builder: (_) => _OrderEditorDialog(
              session: session,
              products: products,
              categories: categories,
            ),
          ),
          onPrint: () => _print(context, ref),
          onClose: () => _close(context, ref),
        ),
      ],
    );
  }

  String get _orderId =>
      session.orderIds.isEmpty ? session.id : session.orderIds.first;

  Future<void> _print(BuildContext context, WidgetRef ref) async {
    UserModel? registeredCustomer;
    if ((session.guestName ?? '').trim().isEmpty &&
        (session.openedByUserId ?? '').trim().isNotEmpty) {
      try {
        final user = await ref
            .read(adminFirestoreProvider)
            .getUser(session.openedByUserId!);
        if (user?.role == UserRole.customer) registeredCustomer = user;
      } catch (_) {
        registeredCustomer = null;
      }
    }
    if (!context.mounted) return;
    await PrintOrderDialog.show(
      context,
      order: _orderFromSession(session),
      customerName: session.guestName ?? registeredCustomer?.name,
      customerPhone: session.guestPhone ?? registeredCustomer?.phone,
    );
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_ClosePayment>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CloseAccountSheet(session: session),
    );
    if (result == null) return;
    try {
      await ref.read(adminFirestoreProvider).closeTable(
            session: session,
            paymentMethod: result.method,
            changeFor: result.changeFor,
          );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta fechada e mesa liberada.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao fechar conta: $error')),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _EmptyItemsCard extends StatelessWidget {
  const _EmptyItemsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('Mesa aberta. Adicione os primeiros itens.'),
      ),
    );
  }
}

class _SessionItemCard extends StatelessWidget {
  const _SessionItemCard({required this.item, required this.price});

  final OrderItemModel item;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.quantity}x',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name),
                  if ((item.notes ?? '').trim().isNotEmpty)
                    Text(
                      'Obs: ${item.notes}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.edit_note_outlined),
            const SizedBox(width: 10),
            Expanded(child: Text(notes)),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.subtotal, required this.total});

  final String subtotal;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _AmountRow(label: 'Subtotal', value: subtotal),
          const SizedBox(height: 8),
          _AmountRow(label: 'Total', value: total, emphasized: true),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
      fontSize: emphasized ? 18 : 14,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _SessionActions extends StatelessWidget {
  const _SessionActions({
    required this.canPrint,
    required this.canClose,
    required this.onEdit,
    required this.onPrint,
    required this.onClose,
  });

  final bool canPrint;
  final bool canClose;
  final VoidCallback onEdit;
  final VoidCallback onPrint;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEADFD6))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.add_shopping_cart_outlined),
            label: const Text('Adicionar / Editar'),
          ),
          OutlinedButton.icon(
            onPressed: canPrint ? onPrint : null,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Imprimir'),
          ),
          OutlinedButton.icon(
            onPressed: canClose ? onClose : null,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Fechar conta'),
          ),
        ],
      ),
    );
  }
}

class _OrderEditorDialog extends ConsumerStatefulWidget {
  const _OrderEditorDialog({
    required this.session,
    required this.products,
    required this.categories,
  });

  final TableSessionModel session;
  final List<ProductModel> products;
  final List<CategoryModel> categories;

  @override
  ConsumerState<_OrderEditorDialog> createState() => _OrderEditorDialogState();
}

class _OrderEditorDialogState extends ConsumerState<_OrderEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  late List<OrderItemModel> _items;
  bool _saving = false;
  bool _loadingCatalog = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.guestName);
    _phoneController = TextEditingController(text: widget.session.guestPhone);
    _notesController = TextEditingController(text: widget.session.notes);
    _items = [...widget.session.items];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final total = _currentTotal;
    final screen = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: screen.height * .96,
          minWidth: screen.width < 560 ? screen.width - 20 : 520,
        ),
        child: Column(
          children: [
            _DialogHeader(
              title: 'Editar comanda',
              subtitle:
                  'Mesa ${widget.session.tableNumber} · sem taxa e sem fidelidade',
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final sideBySide = constraints.maxWidth >= 620;
                      final name = TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do cliente (opcional)',
                        ),
                      );
                      final phone = TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefone (opcional)',
                        ),
                      );
                      if (!sideBySide) {
                        return Column(
                          children: [
                            name,
                            const SizedBox(height: 10),
                            phone,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: name),
                          const SizedBox(width: 12),
                          Expanded(child: phone),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Itens',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving || _loadingCatalog
                          ? null
                          : _openProductCatalog,
                      icon: _loadingCatalog
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text('Adicionar item'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    const _EmptyEditorItems()
                  else
                    for (var index = 0; index < _items.length; index++)
                      _EditableItemCard(
                        item: _items[index],
                        price: currency.format(_items[index].subtotal),
                        onDecrease: () => _changeQuantity(index, -1),
                        onIncrease: () => _changeQuantity(index, 1),
                        onQuantityTap: () => _editQuantity(index),
                        onNotes: () => _editItemNotes(index),
                        onRemove: () => setState(() => _items.removeAt(index)),
                      ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observação geral',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TotalCard(
                    subtotal: currency.format(total),
                    total: currency.format(total),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEADFD6))),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Salvar comanda'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving || _items.isEmpty ? null : _saveAndPrint,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Imprimir'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving || _items.isEmpty ? null : _closeAccount,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Fechar conta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _currentTotal {
    return _items.fold<double>(0, (value, item) => value + item.subtotal);
  }

  Future<void> _openProductCatalog() async {
    setState(() => _loadingCatalog = true);
    var products =
        ref.read(adminTableProductsProvider).valueOrNull ?? widget.products;
    var categories =
        ref.read(adminTableCategoriesProvider).valueOrNull ?? widget.categories;
    try {
      if (products.isEmpty) {
        products = await ref.read(adminTableProductsProvider.future);
      }
      if (categories.isEmpty) {
        categories = await ref.read(adminTableCategoriesProvider.future);
      }
    } catch (_) {
      // O catálogo ainda abre com os dados já carregados.
    } finally {
      if (mounted) setState(() => _loadingCatalog = false);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ProductCatalogDialog(
        products: products,
        categories: categories,
        onAdd: _addProduct,
      ),
    );
  }

  void _addProduct(ProductModel product) {
    final existingIndex =
        _items.indexWhere((item) => item.productId == product.id);
    setState(() {
      if (existingIndex >= 0) {
        final current = _items[existingIndex];
        _items[existingIndex] = _copyItem(
          current,
          quantity: current.quantity + 1,
        );
      } else {
        _items.add(
          OrderItemModel(
            productId: product.id,
            name: product.name,
            unitPrice: product.price,
            quantity: 1,
            imageUrl: product.imageUrl,
          ),
        );
      }
    });
  }

  void _changeQuantity(int index, int delta) {
    final current = _items[index];
    final next = current.quantity + delta;
    setState(() {
      if (next <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _copyItem(current, quantity: next);
      }
    });
  }

  Future<void> _editQuantity(int index) async {
    final controller = TextEditingController(
      text: _items[index].quantity.toString(),
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar quantidade'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantidade'),
          onSubmitted: (text) {
            Navigator.of(context).pop(int.tryParse(text));
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(int.tryParse(controller.text));
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value < 1 || !mounted) return;
    setState(() {
      _items[index] = _copyItem(_items[index], quantity: value);
    });
  }

  Future<void> _editItemNotes(int index) async {
    final controller = TextEditingController(text: _items[index].notes);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observação do item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    setState(() {
      _items[index] = _copyItem(
        _items[index],
        notes: value.trim().isEmpty ? null : value.trim(),
        replaceNotes: true,
      );
    });
  }

  Future<bool> _save({bool showMessage = true}) async {
    setState(() => _saving = true);
    try {
      await ref.read(adminFirestoreProvider).saveTableOrder(
            session: widget.session,
            items: _items,
            guestName: _nameController.text,
            guestPhone: _phoneController.text,
            notes: _notesController.text,
          );
      if (!mounted) return false;
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comanda salva.')),
        );
      }
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar comanda: $error')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAndPrint() async {
    if (!await _save(showMessage: false) || !mounted) return;
    final draft = _draftSession();
    await PrintOrderDialog.show(
      context,
      order: _orderFromSession(draft),
      customerName: _nameController.text,
      customerPhone: _phoneController.text,
    );
  }

  Future<void> _closeAccount() async {
    final draft = _draftSession();
    final payment = await showModalBottomSheet<_ClosePayment>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CloseAccountSheet(session: draft),
    );
    if (payment == null || !mounted) return;
    if (!await _save(showMessage: false) || !mounted) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminFirestoreProvider).closeTable(
            session: draft,
            paymentMethod: payment.method,
            changeFor: payment.changeFor,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Conta fechada e mesa liberada.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao fechar conta: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  TableSessionModel _draftSession() {
    final total = _currentTotal;
    return TableSessionModel(
      id: widget.session.id,
      tableId: widget.session.tableId,
      tableNumber: widget.session.tableNumber,
      status: _items.isEmpty
          ? TableSessionStatus.open
          : TableSessionStatus.preparing,
      items: [..._items],
      subtotal: total,
      serviceFee: 0,
      discount: 0,
      total: total,
      paymentMethod: widget.session.paymentMethod,
      paymentStatus: widget.session.paymentStatus,
      changeFor: widget.session.changeFor,
      guestName: _nameController.text.trim(),
      guestPhone: _phoneController.text.trim(),
      notes: _notesController.text.trim(),
      openedAt: widget.session.openedAt,
      closedAt: widget.session.closedAt,
      updatedAt: DateTime.now(),
      openedByName: widget.session.openedByName,
      waiterName: widget.session.waiterName,
      openedByUserId: widget.session.openedByUserId,
      dailyOrderNumber: widget.session.dailyOrderNumber,
      orderDateKey: widget.session.orderDateKey,
      orderIds: widget.session.orderIds,
    );
  }
}

class _EditableItemCard extends StatelessWidget {
  const _EditableItemCard({
    required this.item,
    required this.price,
    required this.onDecrease,
    required this.onIncrease,
    required this.onQuantityTap,
    required this.onNotes,
    required this.onRemove,
  });

  final OrderItemModel item;
  final String price;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onQuantityTap;
  final VoidCallback onNotes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  price,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            if ((item.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'Obs: ${item.notes}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Diminuir',
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove),
                ),
                InkWell(
                  onTap: onQuantityTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Aumentar',
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add),
                ),
                TextButton.icon(
                  onPressed: onNotes,
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text('Observação'),
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyEditorItems extends StatelessWidget {
  const _EmptyEditorItems();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Nenhum item adicionado. Toque em “Adicionar item” para abrir o catálogo.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ProductCatalogDialog extends StatefulWidget {
  const _ProductCatalogDialog({
    required this.products,
    required this.categories,
    required this.onAdd,
  });

  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final ValueChanged<ProductModel> onAdd;

  @override
  State<_ProductCatalogDialog> createState() => _ProductCatalogDialogState();
}

class _ProductCatalogDialogState extends State<_ProductCatalogDialog> {
  final _searchController = TextEditingController();
  String? _categoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final query = _searchController.text.trim().toLowerCase();
    final products = widget.products.where((product) {
      if (!product.isActive || !product.isAvailable) return false;
      if (_categoryId != null && product.categoryId != _categoryId) {
        return false;
      }
      return query.isEmpty || product.name.toLowerCase().contains(query);
    }).toList();
    final activeCategories = widget.categories
        .where((category) => category.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: Column(
          children: [
            const _DialogHeader(
              title: 'Adicionar item',
              subtitle: 'Pesquise e adicione produtos do catálogo',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar produto',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (activeCategories.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          child: Text('Todas as categorias'),
                        ),
                        ...activeCategories.map(
                          (category) => DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _categoryId = value);
                      },
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhum produto encontrado.'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _CatalogProductCard(
                          product: product,
                          price: currency.format(product.price),
                          onAdd: () => _addProduct(product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _addProduct(ProductModel product) {
    widget.onAdd(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} adicionado.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _CatalogProductCard extends StatelessWidget {
  const _CatalogProductCard({
    required this.product,
    required this.price,
    required this.onAdd,
  });

  final ProductModel product;
  final String price;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            final details = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F5A52),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            );

            if (compact) {
              return Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    details,
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onAdd,
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 116,
                    child: FilledButton(
                      onPressed: onAdd,
                      child: const Text('Adicionar'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
  final _changeController = TextEditingController();
  PaymentMethod _method = PaymentMethod.debitCard;
  bool _needsChange = false;

  @override
  void dispose() {
    _changeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return SafeArea(
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
            const Text(
              'Fechar conta',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text('Total: ${currency.format(widget.session.total)}'),
            const SizedBox(height: 14),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento',
              ),
              items: const [
                DropdownMenuItem(
                  value: PaymentMethod.cash,
                  child: Text('Dinheiro'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.creditCard,
                  child: Text('Crédito'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.debitCard,
                  child: Text('Débito'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.pix,
                  child: Text('Pix'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.notSelected,
                  child: Text('A definir'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _method = value);
              },
            ),
            if (_method == PaymentMethod.cash) ...[
              SwitchListTile.adaptive(
                value: _needsChange,
                title: const Text('Precisa de troco?'),
                onChanged: (value) => setState(() => _needsChange = value),
              ),
              if (_needsChange)
                TextField(
                  controller: _changeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Troco para'),
                ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _confirmClose,
              icon: const Icon(Icons.check),
              label: const Text('Finalizar e liberar mesa'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClose() {
    double? changeFor;
    if (_method == PaymentMethod.cash && _needsChange) {
      changeFor = _parseMoney(_changeController.text);
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

OrderModel _orderFromSession(TableSessionModel session) {
  final id = session.orderIds.isEmpty ? session.id : session.orderIds.first;
  return OrderModel(
    id: id,
    userId: session.openedByUserId ?? '',
    items: session.items,
    subtotal: session.subtotal,
    deliveryFee: 0,
    total: session.total,
    status: session.status == TableSessionStatus.closed
        ? OrderStatus.delivered
        : OrderStatus.preparing,
    deliveryType: DeliveryType.dineIn,
    paymentMethod: session.paymentMethod ?? PaymentMethod.notSelected,
    paymentStatus: session.paymentStatus,
    notes: session.notes,
    changeFor: session.changeFor,
    guestName: session.guestName,
    guestPhone: session.guestPhone,
    tableId: session.tableId,
    tableNumber: session.tableNumber,
    tableSessionId: session.id,
    dineInStatus: session.status.value,
    dailyOrderNumber: session.dailyOrderNumber,
    orderDateKey: session.orderDateKey,
    createdAt: session.openedAt,
    updatedAt: session.updatedAt,
  );
}

OrderItemModel _copyItem(
  OrderItemModel item, {
  int? quantity,
  String? notes,
  bool replaceNotes = false,
}) {
  return OrderItemModel(
    productId: item.productId,
    name: item.name,
    unitPrice: item.unitPrice,
    quantity: quantity ?? item.quantity,
    imageUrl: item.imageUrl,
    notes: replaceNotes ? notes : notes ?? item.notes,
  );
}

String _displayValue(String? value) {
  final clean = value?.trim();
  return clean == null || clean.isEmpty ? 'N/I' : clean;
}

double? _parseMoney(String value) {
  return double.tryParse(
    value.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim(),
  );
}

Color _statusColor(TableStatus status) {
  return switch (status) {
    TableStatus.free => const Color(0xFF2E7D4F),
    TableStatus.open => const Color(0xFF7B2E1F),
    TableStatus.preparing => const Color(0xFFE6A12A),
    TableStatus.waitingPayment => const Color(0xFFB6462F),
  };
}
