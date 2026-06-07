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

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  static const _filters = [
    'Todos',
    'Pastéis',
    'Salgados',
    'Bebidas',
    'Caldo de Cana',
    'Doces',
  ];

  final _searchController = TextEditingController();
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final categoriesAsync = ref.watch(adminCategoriesForProductsProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EB),
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 156,
              child: FilledButton.icon(
                onPressed: () => _showProductDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Novo produto'),
              ),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final categories = categoriesAsync.maybeWhen(
            data: (value) => value,
            orElse: () => const <CategoryModel>[],
          );
          final categoriesById = {
            for (final category in categories) category.id: category,
          };
          final visibleProducts = _filterProducts(products, categoriesById);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductsOverview(
                    totalProducts: products.length,
                    visibleProducts: visibleProducts.length,
                    activeProducts:
                        products.where((product) => product.isActive).length,
                  ),
                  const SizedBox(height: 16),
                  _ProductsSearchField(controller: _searchController),
                  const SizedBox(height: 14),
                  _CategoryFilterBar(
                    filters: _filters,
                    selectedFilter: _selectedFilter,
                    onSelected: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: visibleProducts.isEmpty
                        ? const _EmptyProductsState()
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: visibleProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final product = visibleProducts[index];
                              return _ProductAdminCard(
                                product: product,
                                categoryName:
                                    _categoryLabel(product, categoriesById),
                                currency: currency,
                                onEdit: () => _showProductDialog(
                                  context,
                                  product: product,
                                ),
                                onDelete: () => _confirmDeleteProduct(product),
                                onToggleActive: () =>
                                    _toggleProductActive(product),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  List<ProductModel> _filterProducts(
    List<ProductModel> products,
    Map<String, CategoryModel> categoriesById,
  ) {
    final query = _normalize(_searchController.text.trim());
    final filtered = products.where((product) {
      final matchesSearch =
          query.isEmpty || _normalize(product.name).contains(query);
      final category = _categoryLabel(product, categoriesById);
      final matchesCategory =
          _selectedFilter == 'Todos' || category == _selectedFilter;

      return matchesSearch && matchesCategory;
    }).toList();

    filtered.sort((a, b) {
      final categoryComparison = _categoryOrder(_categoryLabel(a, categoriesById))
          .compareTo(_categoryOrder(_categoryLabel(b, categoriesById)));
      if (categoryComparison != 0) return categoryComparison;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  int _categoryOrder(String category) {
    final index = _filters.indexOf(category);
    return index == -1 ? _filters.length : index;
  }

  String _categoryLabel(
    ProductModel product,
    Map<String, CategoryModel> categoriesById,
  ) {
    final registeredName = categoriesById[product.categoryId]?.name.trim();
    if (registeredName != null && registeredName.isNotEmpty) {
      return _canonicalCategory(registeredName) ?? registeredName;
    }

    return _inferCategory(product);
  }

  String _inferCategory(ProductModel product) {
    final text = _normalize(
      '${product.categoryId} ${product.name} ${product.description}',
    );

    if (text.contains('caldo') || text.contains('cana')) {
      return 'Caldo de Cana';
    }
    if (text.contains('doce') ||
        text.contains('pudim') ||
        text.contains('bolo') ||
        text.contains('trufad') ||
        text.contains('bombom') ||
        text.contains('banoffee')) {
      return 'Doces';
    }
    if (text.contains('bebida') ||
        text.contains('refri') ||
        text.contains('refrigerante') ||
        text.contains('agua') ||
        text.contains('h2oh') ||
        text.contains('pepsi') ||
        text.contains('guarana') ||
        text.contains('coca') ||
        text.contains('suco')) {
      return 'Bebidas';
    }
    if (text.contains('salg') ||
        text.contains('empada') ||
        text.contains('panqueca') ||
        text.contains('pizza') ||
        text.contains('lasanha') ||
        text.contains('torta') ||
        text.contains('chips') ||
        text.contains('assado')) {
      return 'Salgados';
    }
    if (text.contains('past')) {
      return 'Pastéis';
    }

    return 'Sem categoria';
  }

  String? _canonicalCategory(String value) {
    final text = _normalize(value);

    if (text.contains('caldo') || text.contains('cana')) {
      return 'Caldo de Cana';
    }
    if (text.contains('doce')) return 'Doces';
    if (text.contains('bebida')) return 'Bebidas';
    if (text.contains('salg')) return 'Salgados';
    if (text.contains('past')) return 'Pastéis';

    return null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  Future<void> _toggleProductActive(ProductModel product) async {
    final nextActive = !product.isActive;
    await ref
        .read(adminFirestoreProvider)
        .upsertProduct(product.copyWith(isActive: nextActive));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nextActive ? 'Produto ativado.' : 'Produto desativado.'),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(ProductModel product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Deseja excluir "${product.name}" do cardápio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await ref.read(adminFirestoreProvider).deleteProduct(product.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produto excluído.')),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context, {
    ProductModel? product,
  }) async {
    final categories = await ref.read(adminCategoriesForProductsProvider.future);
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController =
        TextEditingController(text: product?.description ?? '');
    final priceController =
        TextEditingController(text: '${product?.price ?? 0}');
    final imageUrlController =
        TextEditingController(text: product?.imageUrl ?? '');
    var categoryId =
        product?.categoryId ?? (categories.isNotEmpty ? categories.first.id : '');
    var imageUrl = imageUrlController.text.trim();
    var isAvailable = product?.isAvailable ?? true;
    var isActive = product?.isActive ?? true;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(product == null ? 'Novo produto' : 'Editar produto'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProductImageEditor(
                    imageUrl: imageUrl,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL da imagem',
                      hintText: 'Cole aqui a URL da foto do produto',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      setState(() => imageUrl = value.trim());
                    },
                  ),
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
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => categoryId = value ?? '');
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Disponível'),
                    value: isAvailable,
                    onChanged: (value) {
                      setState(() => isAvailable = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Ativo'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final cleanedImageUrl = imageUrlController.text.trim();
                final model = ProductModel(
                  id: product?.id ?? '',
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  price: double.tryParse(
                        priceController.text.replaceAll(',', '.'),
                      ) ??
                      0,
                  categoryId: categoryId,
                  imageUrl: cleanedImageUrl.isEmpty ? null : cleanedImageUrl,
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

class _ProductImageEditor extends StatelessWidget {
  const _ProductImageEditor({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADFD4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (trimmedUrl == null || trimmedUrl.isEmpty)
                    const _ProductImageEditorPlaceholder()
                  else
                    Image.network(
                      trimmedUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _ProductImageEditorPlaceholder(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Imagem do produto',
                  style: TextStyle(
                    color: Color(0xFF2B1D18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cole uma URL publica no campo abaixo para atualizar o preview.',
                  style: TextStyle(
                    color: Color(0xFF7E6A62),
                    height: 1.25,
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

class _ProductImageEditorPlaceholder extends StatelessWidget {
  const _ProductImageEditorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3E0), Color(0xFFECC9B2)],
        ),
      ),
      child: const Icon(
        Icons.add_photo_alternate_outlined,
        color: Color(0xFF7B2E1F),
        size: 36,
      ),
    );
  }
}

class _ProductsOverview extends StatelessWidget {
  const _ProductsOverview({
    required this.totalProducts,
    required this.visibleProducts,
    required this.activeProducts,
  });

  final int totalProducts;
  final int visibleProducts;
  final int activeProducts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cardápio da Ray',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2B1D18),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalProducts produtos cadastrados',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7E6A62),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: '$activeProducts ativos',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2F7D46),
              ),
              _MetricChip(
                label: '$visibleProducts no filtro',
                icon: Icons.tune,
                color: const Color(0xFF7B2E1F),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsSearchField extends StatelessWidget {
  const _ProductsSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar produto...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x11000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFB6462F), width: 1.4),
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter == selectedFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            showCheckmark: false,
            selectedColor: const Color(0xFF7B2E1F),
            backgroundColor: Colors.white,
            side: BorderSide(
              color:
                  selected ? const Color(0xFF7B2E1F) : const Color(0xFFE6DCD1),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF4B3831),
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _ProductAdminCard extends StatelessWidget {
  const _ProductAdminCard({
    required this.product,
    required this.categoryName,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final ProductModel product;
  final String categoryName;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADFD4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final imageSize = compact ? 92.0 : 124.0;
          final image = _ProductImage(product: product, size: imageSize);
          final details = _ProductDetails(
            product: product,
            categoryName: categoryName,
            currency: currency,
          );
          final actions = _ProductActions(
            isActive: product.isActive,
            onEdit: onEdit,
            onDelete: onDelete,
            onToggleActive: onToggleActive,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              const SizedBox(width: 16),
              Expanded(child: details),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.product,
    required this.size,
  });

  final ProductModel product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl == null || imageUrl.isEmpty
            ? _ImagePlaceholder(product: product)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImagePlaceholder(
                  product: product,
                ),
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3E0), Color(0xFFECC9B2)],
        ),
      ),
      child: Icon(
        _placeholderIcon(product),
        color: const Color(0xFF7B2E1F),
        size: 34,
      ),
    );
  }

  IconData _placeholderIcon(ProductModel product) {
    final text =
        '${product.categoryId} ${product.name} ${product.description}'
            .toLowerCase();

    if (text.contains('bebida') ||
        text.contains('refri') ||
        text.contains('caldo') ||
        text.contains('agua')) {
      return Icons.local_drink_outlined;
    }
    if (text.contains('doce') ||
        text.contains('bolo') ||
        text.contains('pudim')) {
      return Icons.cake_outlined;
    }
    if (text.contains('pizza')) return Icons.local_pizza_outlined;
    return Icons.restaurant_menu;
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({
    required this.product,
    required this.categoryName,
    required this.currency,
  });

  final ProductModel product;
  final String categoryName;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = product.description.trim().isEmpty
        ? 'Sem descrição cadastrada.'
        : product.description.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CategoryPill(label: categoryName),
            _StatusPill(
              label: product.isActive ? 'Ativo' : 'Inativo',
              color: product.isActive
                  ? const Color(0xFF2F7D46)
                  : const Color(0xFF8A8A8A),
            ),
            _StatusPill(
              label: product.isAvailable ? 'Disponível' : 'Indisponível',
              color: product.isAvailable
                  ? const Color(0xFFD7A552)
                  : const Color(0xFFB6462F),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF2B1D18),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6F5C54),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          currency.format(product.price),
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF7B2E1F),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7B2E1F),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ProductActions extends StatelessWidget {
  const _ProductActions({
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onToggleActive,
          icon: Icon(
            isActive
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
          ),
          label: Text(isActive ? 'Desativar' : 'Ativar'),
        ),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFB6462F),
          ),
        ),
      ],
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEADFD4)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              color: Color(0xFF7B2E1F),
              size: 38,
            ),
            SizedBox(height: 12),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(
                color: Color(0xFF2B1D18),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ajuste a busca ou troque o filtro.',
              style: TextStyle(color: Color(0xFF7E6A62)),
            ),
          ],
        ),
      ),
    );
  }
}
