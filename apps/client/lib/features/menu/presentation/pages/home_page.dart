import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  'Past\u00e9is',
  'Salgados',
  'Bebidas',
  'Caldo de Cana',
  'Doces',
];

typedef _AddProductCallback = void Function(
  ProductModel product,
  Offset? origin,
);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _menuKey = GlobalKey();
  String _selectedFilter = _allFilter;
  bool _cartPulse = false;
  bool _toastVisible = false;
  String _toastMessage = 'Adicionado Ã  sacola';
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                titleSpacing: 12,
                title: Row(
                  children: [
                    const RayBrandMark(size: 34, showWordmark: false),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Lanchonete da Ray',
                              maxLines: 1,
                              softWrap: false,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color:
                                    isDark ? AppTheme.darkText : AppTheme.ink,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Pastelaria artesanal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppTheme.darkMuted
                                  : AppTheme.muted,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Conta',
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => context.push('/profile'),
                  ),
                  IconButton(
                    tooltip: 'Meus pedidos',
                    icon: const Icon(Icons.receipt_long_outlined),
                    onPressed: () => context.push('/orders'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: IconButton(
                      tooltip: 'Sacola',
                      icon: AnimatedScale(
                        scale: _cartPulse ? 1.18 : 1,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutBack,
                        child: Badge(
                          label: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Text(
                              '$cartCount',
                              key: ValueKey(cartCount),
                            ),
                          ),
                          isLabelVisible: cartCount > 0,
                          child: const Icon(Icons.shopping_bag_outlined),
                        ),
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
                      child: _CategoryCarousel(onSelected: _selectCategory),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: const _SectionHeader(
                        title: 'Mais pedidos da Ray',
                        subtitle:
                            'Os favoritos que saem quentinhos da cozinha.',
                      ),
                    ),
                    _FeaturedProductsCarousel(
                      products: _prioritizedProducts(products),
                      currency: currency,
                      onAdd: _addProduct,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                      child: _StorySection(photo: RayPhotos.rayStory),
                    ),
                    Padding(
                      key: _menuKey,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: const _SectionHeader(
                        title: 'Card\u00e1pio Completo',
                        subtitle:
                            'Encontre seu favorito no card\u00e1pio real da Ray.',
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
                      onAdd: _addProduct,
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
          Positioned(
            left: 20,
            right: 20,
            bottom: cartCount > 0 ? 92 : 24,
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                reverseDuration: const Duration(milliseconds: 140),
                child: _toastVisible
                    ? _CartMiniToast(
                        key: ValueKey(_toastMessage),
                        message: _toastMessage,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: cartCount > 0
          ? AnimatedScale(
              scale: _cartPulse ? 1.08 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/cart'),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    key: ValueKey(cartCount),
                  ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    'Sacola ($cartCount)',
                    key: ValueKey('cart-$cartCount'),
                  ),
                ),
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: AppTheme.warmWhite,
                elevation: _cartPulse ? 18 : 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
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

  void _selectCategory(String filter) {
    setState(() => _selectedFilter = filter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMenu());
  }

  void _addProduct(ProductModel product, Offset? origin) {
    ref.read(cartControllerProvider.notifier).addProduct(product);
    _showFlyingCartCue(origin);
    _showCartToast('Adicionado à sacola');

    setState(() => _cartPulse = true);
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() => _cartPulse = false);
    });
  }

  void _showCartToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastVisible = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _toastVisible = false);
    });
  }

  void _showFlyingCartCue(Offset? origin) {
    final overlay = Overlay.of(context);
    final size = MediaQuery.sizeOf(context);
    final appWidth = size.width > 520 ? 520.0 : size.width;
    final appLeft = (size.width - appWidth) / 2;
    final start = origin ?? Offset(appLeft + appWidth - 74, size.height - 120);
    final target = Offset(appLeft + appWidth - 86, size.height - 86);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingCartCue(start: start, target: target),
    );
    overlay.insert(entry);
    Timer(const Duration(milliseconds: 760), entry.remove);
  }
}

class _CartMiniToast extends StatelessWidget {
  const _CartMiniToast({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? AppTheme.darkCardSoft : AppTheme.ink,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: dark ? AppTheme.darkLine : AppTheme.ink.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.34 : 0.16),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppTheme.gold,
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppTheme.warmWhite,
                  fontSize: 13,
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

class _FlyingCartCue extends StatelessWidget {
  const _FlyingCartCue({required this.start, required this.target});

  final Offset start;
  final Offset target;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 680),
      curve: Curves.easeInOutCubic,
      builder: (context, progress, child) {
        final position = Offset.lerp(start, target, progress) ?? target;
        final opacity = progress < 0.78 ? 1.0 : (1 - progress) / 0.22;
        final scale = 1 + (0.18 * (1 - progress));

        return Positioned(
          left: position.dx - 18,
          top: position.dy - 18,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
                height: 1,
              ),
              child: Text(
                '+1',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
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
  return 'Past\u00e9is';
}

class _CategoryCarousel extends StatefulWidget {
  const _CategoryCarousel({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  State<_CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<_CategoryCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  static final _items = [
    _CategoryCarouselItem(
      filter: 'Past\u00e9is',
      title: 'Past\u00e9is',
      subtitle: 'Crocantes e bem recheados',
      photo: RayPhotos.pastel,
    ),
    _CategoryCarouselItem(
      filter: 'Salgados',
      title: 'Salgados',
      subtitle: 'Receitas caseiras',
      photo: RayPhotos.panqueca,
    ),
    _CategoryCarouselItem(
      filter: 'Bebidas',
      title: 'Bebidas',
      subtitle: 'Geladinhas para acompanhar',
      photo: RayPhotos.caldoCana,
    ),
    _CategoryCarouselItem(
      filter: 'Doces',
      title: 'Doces',
      subtitle: 'Um carinho depois do salgado',
      photo: RayPhotos.doce,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 158,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final item = _items[index];
              return _CategorySlideCard(
                item: item,
                onTap: () => widget.onSelected(item.filter),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _CarouselDots(count: _items.length, activeIndex: _page),
      ],
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = dark ? AppTheme.gold : AppTheme.primaryRed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: index == activeIndex ? 18 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: index == activeIndex
                  ? activeColor
                  : activeColor.withOpacity(0.24),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _CategorySlideCard extends StatelessWidget {
  const _CategorySlideCard({required this.item, required this.onTap});

  final _CategoryCarouselItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
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
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.warmWhite,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.cream,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCarouselItem {
  const _CategoryCarouselItem({
    required this.filter,
    required this.title,
    required this.subtitle,
    required this.photo,
  });

  final String filter;
  final String title;
  final String subtitle;
  final RayPhoto photo;
}

class _StorySection extends StatelessWidget {
  const _StorySection({required this.photo});

  final RayPhoto photo;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkCard : AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: dark ? AppTheme.darkLine : AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(dark ? 0.22 : 0.08),
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
                  'Conhe\u00e7a a Ray',
                  style: GoogleFonts.playfairDisplay(
                    color: dark ? AppTheme.darkText : AppTheme.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O sonho da Ray virou sabor. Da primeira ideia \u00e0 lanchonete, cada pastel, pizza e doce \u00e9 preparado com o mesmo carinho de quem ama servir bem.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: dark ? AppTheme.darkMuted : AppTheme.muted,
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

class _FeaturedProductsCarousel extends StatefulWidget {
  const _FeaturedProductsCarousel({
    required this.products,
    required this.currency,
    required this.onAdd,
  });

  final List<ProductModel> products;
  final NumberFormat currency;
  final _AddProductCallback onAdd;

  @override
  State<_FeaturedProductsCarousel> createState() =>
      _FeaturedProductsCarouselState();
}

class _FeaturedProductsCarouselState extends State<_FeaturedProductsCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _InlineMessage(
          message: 'A Ray est\u00e1 preparando os favoritos do dia.',
        ),
      );
    }

    final visibleProducts = widget.products.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            height: 404,
            child: PageView.builder(
              controller: _controller,
              itemCount: visibleProducts.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                final product = visibleProducts[index];

                return _FeaturedProductCard(
                  product: product,
                  price: widget.currency.format(product.price),
                  showBadge: index == 0 || _isPastelDeCarne(product),
                  onAdd: (origin) => widget.onAdd(product, origin),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _CarouselDots(count: visibleProducts.length, activeIndex: _page),
        ],
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
  final ValueChanged<Offset?> onAdd;

  @override
  Widget build(BuildContext context) {
    final available = product.isAvailable && product.isActive;
    final fallbackPhoto = RayPhotos.fallbackForProduct(product);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkCard : AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: dark ? AppTheme.darkLine : AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(dark ? 0.24 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 232,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
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
                    child: _GoldBadge(label: '\u{1F525} Mais pedido'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: dark ? AppTheme.darkText : AppTheme.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description.isEmpty
                        ? 'Favorito da cozinha da Ray.'
                        : product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.25,
                        ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: dark ? AppTheme.gold : _secondaryRay,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      _AddToCartButton(
                        enabled: available,
                        onAdd: onAdd,
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
    final dark = Theme.of(context).brightness == Brightness.dark;

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
            backgroundColor: dark ? AppTheme.darkCard : AppTheme.warmWhite,
            labelStyle: TextStyle(
              color: isSelected
                  ? AppTheme.warmWhite
                  : dark
                      ? AppTheme.darkText
                      : AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryRed
                  : dark
                      ? AppTheme.darkLine
                      : AppTheme.line,
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
  final _AddProductCallback onAdd;

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
              onAdd: (origin) => onAdd(product, origin),
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: dark ? AppTheme.darkText : AppTheme.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '$count itens',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: dark ? AppTheme.darkMuted : AppTheme.muted,
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
  final ValueChanged<Offset?> onAdd;

  @override
  Widget build(BuildContext context) {
    final available = product.isAvailable && product.isActive;
    final fallbackPhoto = RayPhotos.fallbackForProduct(product);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width < 380;
    final imageWidth = compact ? 82.0 : 96.0;
    final imageHeight = compact ? 96.0 : 108.0;
    final addButtonSize = compact ? 40.0 : 42.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkCard : AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? AppTheme.darkLine : AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(dark ? 0.2 : 0.06),
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
              width: imageWidth,
              height: imageHeight,
              child: _PhotoSurface(
                imageUrl: product.imageUrl,
                photo: fallbackPhoto,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: imageHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: dark ? AppTheme.darkText : AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 15 : null,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.description.isEmpty
                        ? 'Preparado com carinho na cozinha da Ray.'
                        : product.description,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: dark ? AppTheme.gold : _secondaryRay,
                                    fontWeight: FontWeight.w900,
                                    fontSize: compact ? 15 : null,
                                  ),
                        ),
                      ),
                      SizedBox(
                        width: addButtonSize,
                        height: addButtonSize,
                        child: _AddIconButton(
                          enabled: available,
                          onAdd: onAdd,
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

class _AddToCartButton extends StatefulWidget {
  const _AddToCartButton({required this.enabled, required this.onAdd});

  final bool enabled;
  final ValueChanged<Offset?> onAdd;

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  bool _pressed = false;
  Offset? _tapOrigin;

  void _handleTap() {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    widget.onAdd(_tapOrigin ?? _centerOrigin());
    Future<void>.delayed(const Duration(milliseconds: 130), () {
      if (!mounted) return;
      setState(() => _pressed = false);
    });
  }

  Offset _centerOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _tapOrigin = details.globalPosition,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: FilledButton.icon(
          onPressed: widget.enabled ? _handleTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: AppTheme.warmWhite,
            disabledBackgroundColor: AppTheme.line,
            disabledForegroundColor: AppTheme.muted,
            minimumSize: const Size(118, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'Adicionar',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _AddIconButton extends StatefulWidget {
  const _AddIconButton({required this.enabled, required this.onAdd});

  final bool enabled;
  final ValueChanged<Offset?> onAdd;

  @override
  State<_AddIconButton> createState() => _AddIconButtonState();
}

class _AddIconButtonState extends State<_AddIconButton> {
  bool _pressed = false;
  Offset? _tapOrigin;

  void _handleTap() {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    widget.onAdd(_tapOrigin ?? _centerOrigin());
    Future<void>.delayed(const Duration(milliseconds: 130), () {
      if (!mounted) return;
      setState(() => _pressed = false);
    });
  }

  Offset _centerOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _tapOrigin = details.globalPosition,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: IconButton.filled(
          tooltip: 'Adicionar',
          onPressed: widget.enabled ? _handleTap : null,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: AppTheme.warmWhite,
            disabledBackgroundColor: AppTheme.line,
            disabledForegroundColor: AppTheme.muted,
          ),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _GoldBadge extends StatelessWidget {
  const _GoldBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3D37A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withOpacity(0.48)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withOpacity(0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 12,
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: dark ? AppTheme.darkText : AppTheme.ink,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: dark ? AppTheme.darkMuted : AppTheme.muted,
              ),
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
