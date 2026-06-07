import 'package:rayssa_client/core/widgets/ray_brand.dart';
import 'package:rayssa_core/rayssa_core.dart';

class RayPhoto {
  const RayPhoto({
    required this.storagePath,
    required this.url,
    required this.assetPath,
  });

  final String storagePath;
  final String url;
  final String assetPath;
}

abstract final class RayPhotos {
  static const _storagePrefix = 'produtos/ray-assets';
  static const _assetPrefix = 'assets/ray';

  static RayPhoto _photo(String fileName) {
    final storagePath = '$_storagePrefix/$fileName';
    return RayPhoto(
      storagePath: storagePath,
      url: '',
      assetPath: '$_assetPrefix/$fileName',
    );
  }

  static final facadeHero = _photo('marca_ray_fachada_hero_1600x900.jpg');
  static final rayStory = _photo('marca_ray_fachada_story_1080x1350.jpg');
  static final pastelHero = _photo('produto_pastel_carne_hero_1600x900.jpg');
  static final pastel = _photo('produto_pastel_carne_square_1080.jpg');
  static final pastelMilho =
      _photo('produto_pastel_milho_queijo_square_1080.jpg');
  static final pizza = _photo('produto_pizza_square_1080.jpg');
  static final panqueca = _photo('produto_panqueca_square_1080.jpg');
  static final doce = _photo('produto_doce_copo_square_1080.jpg');
  static final pudim = _photo('produto_pudim_square_1080.jpg');
  static final caldoCana = _photo('produto_caldo_cana_square_1080.jpg');

  static RayPhoto catalogForKey(String key) {
    final text = normalizedCatalogText(key);
    if (text.contains('pastel')) return pastel;
    if (text.contains('salgado') ||
        text.contains('empada') ||
        text.contains('torta') ||
        text.contains('lasanha')) {
      return panqueca;
    }
    if (text.contains('pizza')) return pizza;
    if (text.contains('panqueca')) return panqueca;
    if (text.contains('caldo') || text.contains('cana')) return caldoCana;
    if (text.contains('bebida') ||
        text.contains('refri') ||
        text.contains('refrigerante')) {
      return caldoCana;
    }
    if (text.contains('doce') ||
        text.contains('sobremesa') ||
        text.contains('bolo')) {
      return doce;
    }
    return pastel;
  }

  static RayPhoto fallbackForProduct(ProductModel product) {
    final text =
        normalizedCatalogText('${product.name} ${product.description}');
    if (text.contains('milho') || text.contains('queijo')) return pastelMilho;
    if (text.contains('pastel')) return pastel;
    if (text.contains('pizza')) return pizza;
    if (text.contains('panqueca')) return panqueca;
    if (text.contains('empada') ||
        text.contains('torta') ||
        text.contains('chips')) {
      return panqueca;
    }
    if (text.contains('lasanha')) return pizza;
    if (text.contains('caldo') || text.contains('cana')) return caldoCana;
    if (text.contains('pudim')) return pudim;
    if (text.contains('doce') ||
        text.contains('sobremesa') ||
        text.contains('bolo')) {
      return doce;
    }
    if (text.contains('refri') ||
        text.contains('refrigerante') ||
        text.contains('bebida')) {
      return caldoCana;
    }
    return pastel;
  }
}
