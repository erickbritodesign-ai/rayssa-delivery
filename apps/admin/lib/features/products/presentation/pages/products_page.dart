import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final adminProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchProducts();
});

final adminCategoriesForProductsProvider =
    StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchCategories();
});

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(context, ref),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('Preço')),
              DataColumn(label: Text('Categoria')),
              DataColumn(label: Text('Disponível')),
              DataColumn(label: Text('Ações')),
            ],
            rows: products
                .map(
                  (product) => DataRow(
                    cells: [
                      DataCell(Text(product.name)),
                      DataCell(Text(currency.format(product.price))),
                      DataCell(Text(product.categoryId)),
                      DataCell(Icon(
                        product.isAvailable ? Icons.check : Icons.close,
                      )),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showProductDialog(
                                context,
                                ref,
                                product: product,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => ref
                                  .read(adminFirestoreProvider)
                                  .deleteProduct(product.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context,
    WidgetRef ref, {
    ProductModel? product,
  }) async {
    final categories =
        await ref.read(adminCategoriesForProductsProvider.future);
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController =
        TextEditingController(text: product?.description ?? '');
    final priceController =
        TextEditingController(text: '${product?.price ?? 0}');
    var categoryId = product?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : '');
    var isAvailable = product?.isAvailable ?? true;
    var isActive = product?.isActive ?? true;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(product == null ? 'Novo produto' : 'Editar produto'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Preço'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: categoryId.isEmpty ? null : categoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => categoryId = value ?? ''),
                ),
                SwitchListTile(
                  title: const Text('Disponível'),
                  value: isAvailable,
                  onChanged: (v) => setState(() => isAvailable = v),
                ),
                SwitchListTile(
                  title: const Text('Ativo'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final model = ProductModel(
                  id: product?.id ?? '',
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  price: double.tryParse(priceController.text) ?? 0,
                  categoryId: categoryId,
                  isAvailable: isAvailable,
                  isActive: isActive,
                );
                await ref.read(adminFirestoreProvider).upsertProduct(model);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
