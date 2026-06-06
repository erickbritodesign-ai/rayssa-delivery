import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/core/branding/ray_photos.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/core/widgets/ray_brand.dart';
import 'package:rayssa_client/features/cart/presentation/providers/cart_providers.dart';
import 'package:rayssa_client/features/menu/presentation/providers/menu_providers.dart';
import 'package:rayssa_core/rayssa_core.dart';

const _secondaryRay = Color(0xFFB6462F);
const _allFilter = 'Todos';

const _filterLabels = [
  _allFilter,
  'Pastéis',
  'Salgados',
  'Bebidas',
  'Caldo de Cana',
  'Doces',
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _menuKey = GlobalKey();
  String _selectedFilter = _allFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            titleSpacing: 20,
            title: const RayBrandMark(size: 36, showWordmark: true),
            actions: [
              IconButton(
                tooltip: 'Meus pedidos',
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () => context.push('/orders'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  tooltip: 'Sacola',
                  icon: Badge(
                    label: Text('$cartCount'),
                    isLabelVisible: cartCount > 0,
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  onPressed: () => context.push('/cart'),
                ),
              ),
            ],
          ),
          productsAsync.when(
            data: (products) => SliverList(
              delegate: SliverChildListDelegate.fixed([
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: _HeroPhoto(onViewMenu: _scrollToMenu),
                ),
                const SizedBox(height: 22),
                const _PromoCarousel(),
                Padding(
                  key: _menuKey,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: const _SectionHeader(
                    title: 'Mais pedidos da Ray',
                    subtitle: 'Os favoritos que saem quentinhos da cozinha.',
                  ),
                ),
                _FeaturedProductsCarousel(
                  products: _prioritizedProducts(products),
                  currency: currency,
                  onAdd: (product) => ref
                      .read(cartControllerProvider.notifier)
                      .addProduct(product),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  child: _StorySection(photo: RayPhotos.rayStory),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: _SectionHeader(
                    title: 'Cardápio Completo',
                    subtitle: 'Encontre seu favorito no cardápio real da Ray.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                _MenuFilters(
                  selected: _selectedFilter,
                  onSelected: (filter) {
                    setState(() => _selectedFilter = filter);
                  },
                ),
                _CompleteMenuSection(
                  products: _filteredProducts(products),
                  currency: currency,
                  onAdd: (product) => ref
                      .read(cartControllerProvider.notifier)
                      .addProduct(product),
                ),
              ]),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 420,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: _InlineMessage(message: 'Erro: $e'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 104)),
        ],
      ),
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('Sacola ($cartCount)'),
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: AppTheme.warmWhite,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            )
          : null,
    );
  }

  List<ProductModel> _filteredProducts(List<ProductModel> products) {
    final query = normalizedCatalogText(_searchController.text.trim());
    final filtered = products.where((product) {
      final categoryMatches = _selectedFilter == _allFilter ||
          _categoryLabelForProduct(product) == _selectedFilter;
      final text = normalizedCatalogText(
        '${product.name} ${product.description}',
      );
      final searchMatches = query.isEmpty || text.contains(query);
      return categoryMatches && searchMatches;
    }).toList();

    return _prioritizedProducts(filtered);
  }

  void _scrollToMenu() {
    final context = _menuKey.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }
}

List<ProductModel> _prioritizedProducts(List<ProductModel> products) {
  final sorted = [...products];
  sorted.sort((a, b) => _catalogPriority(a).compareTo(_catalogPriority(b)));
  return sorted;
}

int _catalogPriority(ProductModel product) {
  final text = normalizedCatalogText('${product.name} ${product.description}');
  const order = [
    'pastel',
    'salgado',
    'empada',
    'panqueca',
    'pizza',
    'lasanha',
    'caldo',
    'doce',
    'bolo',
    'pudim',
    'refrigerante',
    'refri',
    'agua',
    'suco',
  ];

  for (var index = 0; index < order.length; index++) {
    if (text.contains(order[index])) return index;
  }
  return order.length;
}

String _categoryLabelForProduct(ProductModel product) {
  final id = normalizedCatalogText(product.categoryId);
  final text = normalizedCatalogText('${product.name} ${product.description}');

  if (id.contains('caldo') || text.contains('caldo') || text.contains('cana')) {
    return 'Caldo de Cana';
  }
  if (id.contains('doce') ||
      text.contains('doce') ||
      text.contains('pudim') ||
      text.contains('bolo') ||
      text.contains('truf') ||
      text.contains('tortinha') ||
      text.contains('crustoli')) {
    return 'Doces';
  }
  if (id.contains('bebida') ||
      text.contains('agua') ||
      text.contains('refrigerante') ||
      text.contains('refri') ||
      text.contains('suco') ||
      text.contains('h2oh') ||
      text.contains('pepsi')) {
    return 'Bebidas';
  }
  if (id.contains('salgado') ||
      text.contains('empada') ||
      text.contains('panqueca') ||
      text.contains('mini pizza') ||
      text.contains('pizza p') ||
      text.contains('lasanha') ||
      text.contains('torta') ||
      text.contains('chips') ||
      text.contains('assado')) {
    return 'Salgados';
  }
  return 'Pastéis';
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({required this.onViewMenu});

  final VoidCallback onViewMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 332,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: AppTheme.chocolate,
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.24),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: _PhotoSurface(
              photo: RayPhotos.pastelHero,
              dark: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.ink.withOpacity(0.86),
                    AppTheme.ink.withOpacity(0.32),
                    AppTheme.ink.withOpacity(0.08),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.28)),
                  ),
                  child: const Text(
                    'Feito com carinho em Pedro Canário',
                    style: TextStyle(
                      color: AppTheme.warmWhite,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lanchonete e Pastelaria da Ray',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.warmWhite,
                        fontSize: 34,
                        height: 1.02,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pastéis quentinhos, doces e carinho em cada pedido.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.cream,
                        fontWeight: FontWeight.w700,
                        height: 1.32,
                      ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onViewMenu,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.warmWhite,
                    foregroundColor: AppTheme.primaryRed,
                    minimumSize: const Size(136, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Ver Cardápio'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCarousel extends StatelessWidget {
  const _PromoCarousel();

  @override
  Widget build(BuildContext context) {
    final items = [
      _PromoItem(
        title: 'Pastéis',
        subtitle: 'Crocantes e bem recheados',
        photo: RayPhotos.pastel,
      ),
      _PromoItem(
        title: 'Salgados',
        subtitle: 'Receitas caseiras da Ray',
        photo: RayPhotos.panqueca,
      ),
      _PromoItem(
        title: 'Bebidas',
        subtitle: 'Para acompanhar seu pedido',
        photo: RayPhotos.caldoCana,
      ),
      _PromoItem(
        title: 'Doces',
        subtitle: 'Sobremesas com carinho',
        photo: RayPhotos.doce,
      ),
    ];

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _PromoCard(item: item);
        },
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.item});

  final _PromoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 222,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppTheme.chocolate,
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _PhotoSurface(photo: item.photo)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.ink.withOpacity(0.78),
                    AppTheme.ink.withOpacity(0.12),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.warmWhite,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.cream,
                        fontWeight: FontWeight.w700,
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

class _PromoItem {
  const _PromoItem({
    required this.title,
    required this.subtitle,
    required this.photo,
  });

  final String title;
  final String subtitle;
  final RayPhoto photo;
}

class _StorySection extends StatelessWidget {
  const _StorySection({required this.photo});

  final RayPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 218,
              width: double.infinity,
              child: _PhotoSurface(photo: photo),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Conheça a Ray',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O sonho da Ray virou sabor. Da primeira ideia à lanchonete, cada pastel, pizza e doce é preparado com o mesmo carinho de quem ama servir bem.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                        fontSize: 14,
                        height: 1.45,
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

class _FeaturedProductsCarousel extends StatelessWidget {
  const _FeaturedProductsCarousel({
    required this.products,
    required this.currency,
    required this.onAdd,
  });

  final List<ProductModel> products;
  final NumberFormat currency;
  final ValueChanged<ProductModel> onAdd;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _InlineMessage(
          message: 'A Ray está preparando os favoritos do dia.',
        ),
      );
    }

    final visibleProducts = products.take(4).toList();

    return SizedBox(
      height: 344,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: visibleProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = visibleProducts[index];

          return _FeaturedProductCard(
            product: product,
            price: currency.format(product.price),
            showBadge: index == 0 || _isPastelDeCarne(product),
            onAdd: () => onAdd(product),
          );
        },
      ),
    );
  }
}

class _FeaturedProductCard extends StatelessWidget {
  const _FeaturedProductCard({
    required this.product,
    required this.price,
    required this.showBadge,
    required this.onAdd,
  });

  final ProductModel product;
  final String price;
  final bool showBadge;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final available = product.isAvailable && product.isActive;
    final fallbackPhoto = RayPhotos.fallbackForProduct(product);

    return SizedBox(
      width: 294,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.warmWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.line),
          boxShadow: [
            BoxShadow(
              color: AppTheme.chocolate.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 218,
                  width: double.infinity,
                  child: _PhotoSurface(
                    imageUrl: product.imageUrl,
                    photo: fallbackPhoto,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.ink.withOpacity(0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                if (showBadge)
                  Positioned(
                    left: 14,
                    top: 14,
                    child: _GoldBadge(label: 'Mais pedido'),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.description.isEmpty
                        ? 'Favorito da cozinha da Ray.'
                        : product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: _secondaryRay,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      FilledButton(
                        onPressed: available ? onAdd : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: AppTheme.warmWhite,
                          disabledBackgroundColor: AppTheme.line,
                          disabledForegroundColor: AppTheme.muted,
                          minimumSize: const Size(102, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text('Adicionar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar produto...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _MenuFilters extends StatelessWidget {
  const _MenuFilters({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = _filterLabels[index];
          final isSelected = selected == label;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(label),
            showCheckmark: false,
            selectedColor: AppTheme.primaryRed,
            backgroundColor: AppTheme.warmWhite,
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.warmWhite : AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryRed : AppTheme.line,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _CompleteMenuSection extends StatelessWidget {
  const _CompleteMenuSection({
    required this.products,
    required this.currency,
    required this.onAdd,
  });

  final List<ProductModel> products;
  final NumberFormat currency;
  final ValueChanged<ProductModel> onAdd;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: _InlineMessage(
          message: 'Nenhum produto encontrado com essa busca.',
        ),
      );
    }

    final groups = <String, List<ProductModel>>{};
    for (final label in _filterLabels.skip(1)) {
      groups[label] = [];
    }
    for (final product in products) {
      groups[_categoryLabelForProduct(product)]?.add(product);
    }

    final children = <Widget>[];
    for (final label in _filterLabels.skip(1)) {
      final groupProducts = groups[label] ?? [];
      if (groupProducts.isEmpty) continue;

      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(20, children.isEmpty ? 20 : 26, 20, 10),
          child: _MenuGroupHeader(
            title: label,
            count: groupProducts.length,
          ),
        ),
      );

      for (final product in groupProducts) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _MenuProductTile(
              product: product,
              price: currency.format(product.price),
              onAdd: () => onAdd(product),
            ),
          ),
        );
      }
    }

    return Column(children: children);
  }
}

class _MenuGroupHeader extends StatelessWidget {
  const _MenuGroupHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Text(
          '$count itens',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _MenuProductTile extends StatelessWidget {
  const _MenuProductTile({
    required this.product,
    required this.price,
    required this.onAdd,
  });

  final ProductModel product;
  final String price;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final available = product.isAvailable && product.isActive;
    final fallbackPhoto = RayPhotos.fallbackForProduct(product);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 96,
              height: 108,
              child: _PhotoSurface(
                imageUrl: product.imageUrl,
                photo: fallbackPhoto,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 108,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.description.isEmpty
                        ? 'Preparado com carinho na cozinha da Ray.'
                        : product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: _secondaryRay,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: IconButton.filled(
                          tooltip: 'Adicionar',
                          onPressed: available ? onAdd : null,
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: AppTheme.warmWhite,
                            disabledBackgroundColor: AppTheme.line,
                            disabledForegroundColor: AppTheme.muted,
                          ),
                          icon: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isPastelDeCarne(ProductModel product) {
  final text = normalizedCatalogText('${product.name} ${product.description}');
  return text.contains('pastel') && text.contains('carne');
}

class _GoldBadge extends StatelessWidget {
  const _GoldBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withOpacity(0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _PhotoSurface extends StatelessWidget {
  const _PhotoSurface({
    this.imageUrl,
    this.photo,
    this.dark = false,
  });

  final String? imageUrl;
  final RayPhoto? photo;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? photo?.url;

    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _LocalPhotoOrEmpty(
          assetPath: photo?.assetPath,
          dark: dark,
        ),
      );
    }

    return _LocalPhotoOrEmpty(assetPath: photo?.assetPath, dark: dark);
  }
}

class _LocalPhotoOrEmpty extends StatelessWidget {
  const _LocalPhotoOrEmpty({required this.assetPath, required this.dark});

  final String? assetPath;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path != null && path.isNotEmpty) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PhotoEmpty(dark: dark),
      );
    }

    return _PhotoEmpty(dark: dark);
  }
}

class _PhotoEmpty extends StatelessWidget {
  const _PhotoEmpty({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [AppTheme.primaryRed, AppTheme.ink]
              : [AppTheme.cream, AppTheme.blush],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
