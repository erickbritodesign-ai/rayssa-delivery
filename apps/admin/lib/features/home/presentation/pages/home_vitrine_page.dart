import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final adminHomeBannersProvider = StreamProvider<List<HomeBannerModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchHomeBanners();
});

final adminHomeCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchCategories();
});

final adminHomeProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchProducts();
});

class HomeVitrinePage extends ConsumerWidget {
  const HomeVitrinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminHomeBannersProvider);
    final categoriesAsync = ref.watch(adminHomeCategoriesProvider);
    final productsAsync = ref.watch(adminHomeProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EB),
      appBar: AppBar(
        title: const Text('Vitrine'),
        actions: [
          IconButton(
            tooltip: 'Novo banner extra',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => _showBannerDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IntroCard(
                title: 'Home do aplicativo',
                subtitle:
                    'Controle o carrossel principal, campanhas extras e os produtos em destaque usando URLs de imagem.',
                icon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Carrossel principal da Home',
                subtitle:
                    'Controle os cards principais: Pastéis, Salgados, Bebidas e Doces.',
                child: categoriesAsync.when(
                  data: (categories) {
                    final sorted = [...categories]
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                    return sorted.isEmpty
                        ? const _EmptyMessage(
                            message: 'Nenhuma categoria cadastrada.',
                          )
                        : Column(
                            children: [
                              for (final category in sorted)
                                _CategoryHomeTile(
                                  category: category,
                                  onEdit: () => _showCategoryHomeDialog(
                                    context,
                                    ref,
                                    category,
                                  ),
                                ),
                            ],
                          );
                  },
                  loading: () => const _LoadingLine(),
                  error: (e, _) => _EmptyMessage(message: 'Erro: $e'),
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Banners extras / campanhas',
                subtitle: 'Use apenas para promoções ou avisos especiais.',
                actionLabel: 'Adicionar campanha',
                onAction: () => _showBannerDialog(context, ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BannerUsageNotice(),
                    const SizedBox(height: 12),
                    bannersAsync.when(
                      data: (banners) => banners.isEmpty
                          ? const _EmptyMessage(
                              message: 'Nenhum banner extra cadastrado ainda.',
                            )
                          : Column(
                              children: [
                                for (final banner in banners)
                                  _BannerAdminTile(
                                    banner: banner,
                                    onEdit: () => _showBannerDialog(
                                      context,
                                      ref,
                                      banner: banner,
                                    ),
                                    onToggle: () => ref
                                        .read(adminFirestoreProvider)
                                        .upsertHomeBanner(
                                          banner.copyWith(
                                            isActive: !banner.isActive,
                                          ),
                                        ),
                                    onDelete: () => ref
                                        .read(adminFirestoreProvider)
                                        .deleteHomeBanner(banner.id),
                                  ),
                              ],
                            ),
                      loading: () => const _LoadingLine(),
                      error: (e, _) => _EmptyMessage(message: 'Erro: $e'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Mais pedidos',
                subtitle: 'Produtos que aparecem como destaque no client',
                child: productsAsync.when(
                  data: (products) {
                    final sorted = [...products]..sort((a, b) {
                        if (a.isFeatured != b.isFeatured) {
                          return a.isFeatured ? -1 : 1;
                        }
                        final order =
                            a.featuredOrder.compareTo(b.featuredOrder);
                        if (order != 0) return order;
                        return a.name.compareTo(b.name);
                      });
                    return sorted.isEmpty
                        ? const _EmptyMessage(
                            message: 'Nenhum produto cadastrado.',
                          )
                        : Column(
                            children: [
                              for (final product in sorted)
                                _FeaturedProductTile(
                                  product: product,
                                  onEdit: () => _showFeaturedProductDialog(
                                    context,
                                    ref,
                                    product,
                                  ),
                                ),
                            ],
                          );
                  },
                  loading: () => const _LoadingLine(),
                  error: (e, _) => _EmptyMessage(message: 'Erro: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBannerDialog(
    BuildContext context,
    WidgetRef ref, {
    HomeBannerModel? banner,
  }) async {
    final titleController = TextEditingController(text: banner?.title ?? '');
    final subtitleController =
        TextEditingController(text: banner?.subtitle ?? '');
    final imageController = TextEditingController(text: banner?.imageUrl ?? '');
    final targetIdController =
        TextEditingController(text: banner?.targetId ?? '');
    final orderController = TextEditingController(
      text: '${banner?.order ?? 0}',
    );
    var targetType = banner?.targetType ?? 'none';
    var isActive = banner?.isActive ?? true;
    var imageUrl = imageController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(banner == null ? 'Novo banner extra' : 'Editar banner extra'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ImagePreview(imageUrl: imageUrl),
                  const SizedBox(height: 10),
                  const _ImageUrlHelp(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titulo'),
                  ),
                  TextField(
                    controller: subtitleController,
                    decoration: const InputDecoration(labelText: 'Subtitulo'),
                  ),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'URL da imagem',
                      helperText:
                          'Use link direto HTTPS de imagem (.jpg, .png ou .webp).',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      setState(() => imageUrl = value.trim());
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: targetType,
                    decoration: const InputDecoration(labelText: 'Destino'),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Nenhum')),
                      DropdownMenuItem(
                        value: 'category',
                        child: Text('Categoria'),
                      ),
                      DropdownMenuItem(value: 'product', child: Text('Produto')),
                    ],
                    onChanged: (value) {
                      setState(() => targetType = value ?? 'none');
                    },
                  ),
                  TextField(
                    controller: targetIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID ou nome do destino',
                    ),
                  ),
                  TextField(
                    controller: orderController,
                    decoration: const InputDecoration(labelText: 'Ordem'),
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativo'),
                    value: isActive,
                    onChanged: (value) => setState(() => isActive = value),
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
                final model = HomeBannerModel(
                  id: banner?.id ?? '',
                  title: titleController.text.trim(),
                  subtitle: subtitleController.text.trim(),
                  imageUrl: imageController.text.trim(),
                  targetType: targetType,
                  targetId: targetIdController.text.trim().isEmpty
                      ? null
                      : targetIdController.text.trim(),
                  order: int.tryParse(orderController.text) ?? 0,
                  isActive: isActive,
                );
                await ref.read(adminFirestoreProvider).upsertHomeBanner(model);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryHomeDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final subtitleController =
        TextEditingController(text: category.subtitle ?? '');
    final imageController = TextEditingController(text: category.imageUrl ?? '');
    final orderController = TextEditingController(text: '${category.sortOrder}');
    var showOnHome = category.showOnHome;
    var isActive = category.isActive;
    var imageUrl = imageController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Categoria: ${category.name}'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ImagePreview(imageUrl: imageUrl),
                  const SizedBox(height: 10),
                  const _ImageUrlHelp(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: subtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Subtitulo na Home',
                    ),
                  ),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'URL da imagem',
                      helperText:
                          'Use link direto HTTPS de imagem (.jpg, .png ou .webp).',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      setState(() => imageUrl = value.trim());
                    },
                  ),
                  TextField(
                    controller: orderController,
                    decoration: const InputDecoration(labelText: 'Ordem'),
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Exibir na Home'),
                    value: showOnHome,
                    onChanged: (value) => setState(() => showOnHome = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Categoria ativa'),
                    value: isActive,
                    onChanged: (value) => setState(() => isActive = value),
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
                final subtitle = subtitleController.text.trim();
                final imageUrl = imageController.text.trim();
                await ref.read(adminFirestoreProvider).upsertCategory(
                      CategoryModel(
                        id: category.id,
                        name: category.name,
                        sortOrder: int.tryParse(orderController.text) ??
                            category.sortOrder,
                        isActive: isActive,
                        imageUrl: imageUrl.isEmpty ? null : imageUrl,
                        subtitle: subtitle.isEmpty ? null : subtitle,
                        showOnHome: showOnHome,
                      ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFeaturedProductDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    final orderController =
        TextEditingController(text: '${product.featuredOrder}');
    final badgeController = TextEditingController(
      text: product.featuredBadgeLabel ?? '\u{1F525} Mais pedido',
    );
    final imageController =
        TextEditingController(text: product.featuredImageUrl ?? '');
    var isFeatured = product.isFeatured;
    var imageUrl = imageController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(product.name),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ImagePreview(
                    imageUrl: imageUrl.isEmpty ? product.imageUrl : imageUrl,
                  ),
                  const SizedBox(height: 10),
                  const _ImageUrlHelp(),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar em Mais pedidos'),
                    value: isFeatured,
                    onChanged: (value) => setState(() => isFeatured = value),
                  ),
                  TextField(
                    controller: orderController,
                    decoration: const InputDecoration(labelText: 'Ordem'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: badgeController,
                    decoration: const InputDecoration(
                      labelText: 'Texto do selo',
                    ),
                  ),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'URL da imagem de destaque',
                      hintText: 'Opcional. Se vazio, usa a imagem do produto.',
                      helperText:
                          'Evite links do Google Imagens, Drive, Instagram ou Pinterest.',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      setState(() => imageUrl = value.trim());
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
                final badgeLabel = badgeController.text.trim();
                final featuredImageUrl = imageController.text.trim();
                await ref.read(adminFirestoreProvider).upsertProduct(
                      ProductModel(
                        id: product.id,
                        name: product.name,
                        description: product.description,
                        price: product.price,
                        categoryId: product.categoryId,
                        imageUrl: product.imageUrl,
                        isAvailable: product.isAvailable,
                        isActive: product.isActive,
                        isFeatured: isFeatured,
                        featuredOrder: int.tryParse(orderController.text) ?? 0,
                        featuredBadgeLabel:
                            badgeLabel.isEmpty ? null : badgeLabel,
                        featuredImageUrl: featuredImageUrl.isEmpty
                            ? null
                            : featuredImageUrl,
                      ),
                    );
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

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFE7E0),
            foregroundColor: const Color(0xFF7B2E1F),
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF2B1D18),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF7D6B61),
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


class _BannerUsageNotice extends StatelessWidget {
  const _BannerUsageNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECC9B2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.campaign_outlined,
            color: Color(0xFF7B2E1F),
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Para o uso normal, edite o carrossel principal acima. Use banners extras apenas para promoções. Se houver banners ativos, eles podem substituir o carrossel principal no topo da Home para evitar duplicidade.',
              style: TextStyle(
                color: Color(0xFF7B2E1F),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEADFD4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF2B1D18),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF7D6B61),
                          ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BannerAdminTile extends StatelessWidget {
  const _BannerAdminTile({
    required this.banner,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final HomeBannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _EditableTile(
      imageUrl: banner.imageUrl,
      title: banner.title.isEmpty ? 'Banner sem titulo' : banner.title,
      subtitle: banner.subtitle,
      chips: [
        'Ordem ${banner.order}',
        banner.isActive ? 'Ativo' : 'Inativo',
        'Destino: ${banner.targetType}',
      ],
      onEdit: onEdit,
      onToggle: onToggle,
      toggleLabel: banner.isActive ? 'Desativar' : 'Ativar',
      onDelete: onDelete,
    );
  }
}

class _CategoryHomeTile extends StatelessWidget {
  const _CategoryHomeTile({
    required this.category,
    required this.onEdit,
  });

  final CategoryModel category;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _EditableTile(
      imageUrl: category.imageUrl,
      title: category.name,
      subtitle: category.subtitle ?? 'Sem subtitulo na Home',
      chips: [
        'Ordem ${category.sortOrder}',
        category.showOnHome ? 'Na Home' : 'Oculta',
        category.isActive ? 'Ativa' : 'Inativa',
      ],
      onEdit: onEdit,
    );
  }
}

class _FeaturedProductTile extends StatelessWidget {
  const _FeaturedProductTile({
    required this.product,
    required this.onEdit,
  });

  final ProductModel product;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.featuredImageUrl?.trim().isNotEmpty == true
        ? product.featuredImageUrl
        : product.imageUrl;

    return _EditableTile(
      imageUrl: imageUrl,
      title: product.name,
      subtitle: product.featuredBadgeLabel ?? '\u{1F525} Mais pedido',
      chips: [
        product.isFeatured ? 'Em destaque' : 'Fora da Home',
        'Ordem ${product.featuredOrder}',
      ],
      onEdit: onEdit,
    );
  }
}

class _EditableTile extends StatelessWidget {
  const _EditableTile({
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.onEdit,
    this.imageUrl,
    this.onToggle,
    this.toggleLabel,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final List<String> chips;
  final String? imageUrl;
  final VoidCallback onEdit;
  final VoidCallback? onToggle;
  final String? toggleLabel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADFD4)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final content = [
            _TileImage(imageUrl: imageUrl),
            const SizedBox(width: 12, height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2B1D18),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF7D6B61)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final chip in chips) _TinyChip(label: chip),
                    ],
                  ),
                ],
              ),
            ),
          ];

          final actions = Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: [
              if (onToggle != null)
                OutlinedButton(
                  onPressed: onToggle,
                  child: Text(toggleLabel ?? 'Ativar'),
                ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                ),
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...content,
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _TileImage extends StatelessWidget {
  const _TileImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 76,
        height: 76,
        child: _ImageOrPlaceholder(imageUrl: imageUrl),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _ImageOrPlaceholder(imageUrl: imageUrl),
      ),
    );
  }
}

class _ImageOrPlaceholder extends StatelessWidget {
  const _ImageOrPlaceholder({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return const _ImagePlaceholder();
    }

    if (!_isProbablyUsableImageUrl(url)) {
      return const _ImageUrlProblem(
        message:
            'URL parece ser página/link indireto. Use um link direto HTTPS de imagem.',
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ImageUrlProblem(
        message:
            'Não foi possível carregar esta imagem. Troque por uma URL direta HTTPS.',
      ),
    );
  }
}

bool _isProbablyUsableImageUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme || uri.scheme.toLowerCase() != 'https') {
    return false;
  }

  final host = uri.host.toLowerCase();
  const blockedHosts = [
    'google.com',
    'www.google.com',
    'images.google.com',
    'drive.google.com',
    'instagram.com',
    'www.instagram.com',
    'facebook.com',
    'www.facebook.com',
    'pinterest.com',
    'br.pinterest.com',
    'www.pinterest.com',
  ];

  if (blockedHosts.any((blocked) => host == blocked || host.endsWith('.$blocked'))) {
    return false;
  }

  return true;
}

class _ImageUrlHelp extends StatelessWidget {
  const _ImageUrlHelp();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECC9B2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF7B2E1F),
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Use URL direta HTTPS da imagem. Evite links do Google Imagens, Drive, Instagram, Facebook ou Pinterest. Se o preview não carregar aqui, pode aparecer diferente no app. Quando houver banners ativos, eles substituem o carrossel superior de categorias na Home para evitar banner duplicado.',
              style: TextStyle(
                color: Color(0xFF7B2E1F),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageUrlProblem extends StatelessWidget {
  const _ImageUrlProblem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3E0), Color(0xFFECC9B2)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF7B2E1F),
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7B2E1F),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

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
        Icons.image_outlined,
        color: Color(0xFF7B2E1F),
        size: 34,
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7B2E1F).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7B2E1F),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF7D6B61)),
      ),
    );
  }
}
