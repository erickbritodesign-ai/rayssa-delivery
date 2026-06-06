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

const _catalog = [
  _CatalogItem('Pastéis', 'pastel'),
  _CatalogItem('Pizzas', 'pizza'),
  _CatalogItem('Panquecas', 'panqueca'),
  _CatalogItem('Doces', 'doce brigadeiro sobremesa'),
  _CatalogItem('Bebidas', 'refrigerante refri'),
  _CatalogItem('Caldo de Cana', 'caldo cana'),
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            data: (_) => SliverList(
              delegate: SliverChildListDelegate.fixed([
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: const _HeroPhoto(),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: _SectionHeader(
                    title: 'Lanchonete e Pastelaria da Ray',
                    subtitle: 'Feito com carinho em Pedro Canário.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StorySection(photo: RayPhotos.rayStory),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: _SectionHeader(
                    title: 'Cardápio da Ray',
                    subtitle: 'O catálogo real da lanchonete.',
                  ),
                ),
                const _CatalogStrip(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: _SectionHeader(
                    title: 'Hoje saindo da cozinha da Ray',
                    subtitle: 'Produtos disponíveis para pedir pelo app.',
                  ),
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
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyMenuState(),
                );
              }

              final sortedProducts = _prioritizedProducts(products);

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: sortedProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final product = sortedProducts[index];

                    return _PhotoProductCard(
                      product: product,
                      price: currency.format(product.price),
                      onAdd: () => ref
                          .read(cartControllerProvider.notifier)
                          .addProduct(product),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(),
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
            )
          : null,
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
    'pizza',
    'panqueca',
    'doce',
    'bolo',
    'refrigerante',
    'refri',
    'caldo',
    'lasanha',
  ];

  for (var index = 0; index < order.length; index++) {
    if (text.contains(order[index])) return index;
  }
  return order.length;
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 286,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: AppTheme.chocolate,
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: _PhotoSurface(
              photo: RayPhotos.facadeHero,
              dark: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.ink.withOpacity(0.74),
                    AppTheme.ink.withOpacity(0.18),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
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
                    'Delivery artesanal',
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
                        fontSize: 30,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Feito com carinho em Pedro Canário.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.cream,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Scrollable.of(context).position.animateTo(
                          560,
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                        );
                  },
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

class _StorySection extends StatelessWidget {
  const _StorySection({required this.photo});

  final RayPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 116,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _PhotoSurface(
                photo: photo,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nossa história',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'O sonho da Ray começou muito antes da inauguração. Hoje cada pastel, pizza, doce e refeição é preparado com o mesmo carinho do primeiro dia.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
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

class _CatalogStrip extends StatelessWidget {
  const _CatalogStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _catalog.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _catalog[index];

          return _CatalogPhotoCard(
            title: item.title,
            photo: RayPhotos.catalogForKey(item.key),
          );
        },
      ),
    );
  }
}

class _CatalogPhotoCard extends StatelessWidget {
  const _CatalogPhotoCard({required this.title, required this.photo});

  final String title;
  final RayPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: _PhotoSurface(
              photo: photo,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.ink.withOpacity(0.62),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.warmWhite,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoProductCard extends StatelessWidget {
  const _PhotoProductCard({
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
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 184,
            width: double.infinity,
            child: _PhotoSurface(
              imageUrl: product.imageUrl,
              photo: fallbackPhoto,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description.isEmpty
                            ? 'Preparado com carinho na cozinha da Ray.'
                            : product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        price,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _secondaryRay,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 44,
                  height: 44,
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
          ),
        ],
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

class _EmptyMenuState extends StatelessWidget {
  const _EmptyMenuState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RayBrandMark(size: 82),
          const SizedBox(height: 18),
          Text(
            'Cardápio em preparo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Assim que a Ray ativar as fotos e produtos do dia, eles aparecem aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
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

class _CatalogItem {
  const _CatalogItem(this.title, this.key);

  final String title;
  final String key;
}
