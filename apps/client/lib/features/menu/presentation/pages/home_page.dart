import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/features/cart/presentation/providers/cart_providers.dart';
import 'package:rayssa_client/features/menu/presentation/providers/menu_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            title: const Text('Rayssa Delivery'),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long),
                onPressed: () => context.push('/orders'),
              ),
              IconButton(
                icon: Badge(
                  label: Text('$cartCount'),
                  isLabelVisible: cartCount > 0,
                  child: const Icon(Icons.shopping_cart),
                ),
                onPressed: () => context.push('/cart'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comida quentinha, feita com carinho ❤️',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Escolha seus favoritos e receba em casa.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                'Categorias',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: categoriesAsync.when(
                data: (categories) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _CategoryChip(
                      label: 'Todos',
                      selected: selectedCategoryId == null,
                      onTap: () =>
                          ref.read(selectedCategoryIdProvider.notifier).state =
                              null,
                    ),
                    ...categories.map(
                      (category) => _CategoryChip(
                        label: category.name,
                        selected: selectedCategoryId == category.id,
                        onTap: () => ref
                            .read(selectedCategoryIdProvider.notifier)
                            .state = category.id,
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                'Cardápio',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Nenhum produto disponível')),
                );
              }

              return SliverList.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ProductCard(
                      product: product,
                      price: currency.format(product.price),
                      onAdd: () => ref
                          .read(cartControllerProvider.notifier)
                          .addProduct(product),
                    ),
                  );
                },
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erro: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              icon: const Icon(Icons.shopping_cart),
              label: Text('Carrinho ($cartCount)'),
            )
          : null,
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.price,
    required this.onAdd,
  });

  final ProductModel product;
  final String price;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0DC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: product.imageUrl == null || product.imageUrl!.isEmpty
                  ? const Icon(Icons.fastfood, color: Color(0xFFE53935))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(product.imageUrl!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFFE53935),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}