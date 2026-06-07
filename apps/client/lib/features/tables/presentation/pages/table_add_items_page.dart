import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:rayssa_client/features/menu/presentation/providers/menu_providers.dart';
import 'package:rayssa_client/features/tables/presentation/providers/table_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';

class TableAddItemsPage extends ConsumerStatefulWidget {
  const TableAddItemsPage({required this.tableId, super.key});

  final String tableId;

  @override
  ConsumerState<TableAddItemsPage> createState() => _TableAddItemsPageState();
}

class _TableAddItemsPageState extends ConsumerState<TableAddItemsPage> {
  final _notesController = TextEditingController();
  final _quantities = <String, int>{};
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final tablesAsync = ref.watch(tablesProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final colors = Theme.of(context).colorScheme;
    final table = tablesAsync.maybeWhen(
      data: (tables) => tables.firstWhere(
        (table) => table.id == widget.tableId,
        orElse: () => TableModel.fallback(_tableNumberFromId(widget.tableId)),
      ),
      orElse: () => TableModel.fallback(_tableNumberFromId(widget.tableId)),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Adicionar na ${table.name}')),
      body: productsAsync.when(
        data: (products) {
          final activeProducts = products
              .where((product) => product.isActive && product.isAvailable)
              .toList();
          final selectedTotal = _selectedTotal(activeProducts);
          final selectedCount =
              _quantities.values.fold<int>(0, (sum, qty) => sum + qty);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _notesController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações da mesa',
                    hintText: 'Ex.: sem cebola, dividir por pessoa...',
                  ),
                ),
              ),
              Expanded(
                child: activeProducts.isEmpty
                    ? const Center(child: Text('Nenhum produto disponível.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                        itemCount: activeProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = activeProducts[index];
                          final quantity = _quantities[product.id] ?? 0;

                          return _ProductPickTile(
                            product: product,
                            quantity: quantity,
                            price: currency.format(product.price),
                            onDecrease: () => _setQuantity(
                              product.id,
                              quantity - 1,
                            ),
                            onIncrease: () => _setQuantity(
                              product.id,
                              quantity + 1,
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(top: BorderSide(color: colors.outlineVariant)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          Theme.of(context).brightness == Brightness.dark
                              ? 0.32
                              : 0.08,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$selectedCount item(ns)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            currency.format(selectedTotal),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colors.secondary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: selectedCount == 0 || _saving
                            ? null
                            : () => _sendToKitchen(activeProducts, table),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.restaurant_menu_outlined),
                        label: const Text('Enviar para preparo'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }

  void _setQuantity(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _quantities.remove(productId);
      } else {
        _quantities[productId] = quantity;
      }
    });
  }

  double _selectedTotal(List<ProductModel> products) {
    return products.fold<double>(0, (sum, product) {
      return sum + product.price * (_quantities[product.id] ?? 0);
    });
  }

  Future<void> _sendToKitchen(
    List<ProductModel> products,
    TableModel table,
  ) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para usar o atendimento.')),
      );
      return;
    }

    final selectedItems = products
        .where((product) => (_quantities[product.id] ?? 0) > 0)
        .map(
          (product) => CartItemModel(
            product: product,
            quantity: _quantities[product.id]!,
          ),
        )
        .toList();

    setState(() => _saving = true);
    try {
      await ref.read(tableServiceProvider).addItemsToTable(
            table: table,
            cartItems: selectedItems,
            openedByUserId: user.id,
            openedByName: user.name.trim().isEmpty ? 'Atendente' : user.name,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado para preparo.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar comanda: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProductPickTile extends StatelessWidget {
  const _ProductPickTile({
    required this.product,
    required this.quantity,
    required this.price,
    required this.onDecrease,
    required this.onIncrease,
  });

  final ProductModel product;
  final int quantity;
  final String price;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: dark ? AppTheme.darkCardSoft : AppTheme.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: product.imageUrl == null || product.imageUrl!.isEmpty
                  ? Icon(
                      Icons.restaurant_menu,
                      color: dark ? AppTheme.gold : colors.primary,
                    )
                  : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.restaurant_menu,
                        color: dark ? AppTheme.gold : colors.primary,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(price, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QtyButton(icon: Icons.remove, onPressed: onDecrease),
            SizedBox(
              width: 34,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            _QtyButton(icon: Icons.add, onPressed: onIncrease),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: dark ? AppTheme.darkCardSoft : AppTheme.cream,
          foregroundColor: dark ? AppTheme.gold : colors.primary,
        ),
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

int _tableNumberFromId(String tableId) {
  final match = RegExp(r'\d+').firstMatch(tableId);
  return int.tryParse(match?.group(0) ?? '') ?? 1;
}
