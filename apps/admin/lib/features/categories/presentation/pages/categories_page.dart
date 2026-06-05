import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final adminCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchCategories();
});

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) => DataTable(
          columns: const [
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('Ordem')),
            DataColumn(label: Text('Ativa')),
            DataColumn(label: Text('Ações')),
          ],
          rows: categories
              .map(
                (category) => DataRow(
                  cells: [
                    DataCell(Text(category.name)),
                    DataCell(Text('${category.sortOrder}')),
                    DataCell(Icon(
                      category.isActive ? Icons.check : Icons.close,
                    )),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showCategoryDialog(
                              context,
                              ref,
                              category: category,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => ref
                                .read(adminFirestoreProvider)
                                .deleteCategory(category.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    CategoryModel? category,
  }) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final orderController = TextEditingController(
      text: '${category?.sortOrder ?? 0}',
    );
    var isActive = category?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? 'Nova categoria' : 'Editar categoria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(labelText: 'Ordem'),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: const Text('Ativa'),
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final model = CategoryModel(
                  id: category?.id ?? '',
                  name: nameController.text.trim(),
                  sortOrder: int.tryParse(orderController.text) ?? 0,
                  isActive: isActive,
                );
                await ref.read(adminFirestoreProvider).upsertCategory(model);
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
