import 'package:flutter/material.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_core/rayssa_core.dart';

class RayBrandMark extends StatelessWidget {
  const RayBrandMark({
    this.size = 56,
    this.showWordmark = false,
    this.onDark = false,
    super.key,
  });

  final double size;
  final bool showWordmark;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final mark = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(onDark ? 0.18 : 0.12),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _RayMarkPainter(onDark: onDark),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              'Ray',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: onDark ? AppTheme.primaryRed : AppTheme.warmWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.34,
                    height: 1,
                  ),
            ),
          ),
        ),
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.22),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lanchonete da Ray',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onDark ? AppTheme.warmWhite : AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                'Pastelaria artesanal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: onDark
                          ? AppTheme.cream.withOpacity(0.82)
                          : AppTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RayMarkPainter extends CustomPainter {
  const _RayMarkPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(0, 0, size.width, size.height);
    final inset = size.width * 0.08;
    final inner = outer.deflate(inset);

    final basePaint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: onDark
            ? [AppTheme.warmWhite, AppTheme.cream]
            : [AppTheme.primaryRed, AppTheme.deepRed],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(outer);

    canvas.drawOval(outer, basePaint);

    final borderPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..color = AppTheme.gold.withOpacity(onDark ? 0.8 : 0.7);
    canvas.drawOval(inner, borderPaint);

    final pastelPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.07
      ..color = (onDark ? AppTheme.primaryRed : AppTheme.gold).withOpacity(0.9);

    final curve = Path()
      ..moveTo(size.width * 0.25, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.82,
        size.width * 0.75,
        size.height * 0.64,
      );
    canvas.drawPath(curve, pastelPaint);

    final stitchPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.018
      ..color = (onDark ? AppTheme.primaryRed : AppTheme.warmWhite)
          .withOpacity(0.58);

    for (var index = 0; index < 5; index++) {
      final x = size.width * (0.33 + index * 0.085);
      canvas.drawLine(
        Offset(x, size.height * 0.665),
        Offset(x + size.width * 0.025, size.height * 0.69),
        stitchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RayMarkPainter oldDelegate) {
    return oldDelegate.onDark != onDark;
  }
}

class CategoryVisual {
  const CategoryVisual({
    required this.label,
    required this.colors,
    this.note,
  });

  final String label;
  final List<Color> colors;
  final String? note;
}

CategoryVisual visualForText(String value) {
  final text = _normalized(value);

  if (text.contains('caldo') || text.contains('cana')) {
    return const CategoryVisual(
      label: 'Caldo de cana',
      note: 'Geladinho',
      colors: [Color(0xFF5B6F35), Color(0xFFD7A552)],
    );
  }
  if (text.contains('refri') ||
      text.contains('refrigerante') ||
      text.contains('coca') ||
      text.contains('guarana')) {
    return const CategoryVisual(
      label: 'Refrigerantes',
      note: 'Bebidas',
      colors: [Color(0xFF7B2E1F), Color(0xFFB6462F)],
    );
  }
  if (text.contains('pastel')) {
    return const CategoryVisual(
      label: 'Pastéis',
      note: 'Crocante',
      colors: [Color(0xFFD7A552), Color(0xFFB6462F)],
    );
  }
  if (text.contains('pizza')) {
    return const CategoryVisual(
      label: 'Pizzas',
      note: 'Forno',
      colors: [Color(0xFFB6462F), Color(0xFFD7A552)],
    );
  }
  if (text.contains('lasanha')) {
    return const CategoryVisual(
      label: 'Lasanhas',
      note: 'Caseira',
      colors: [Color(0xFF7B2E1F), Color(0xFFC7772E)],
    );
  }
  if (text.contains('panqueca')) {
    return CategoryVisual(
      label: 'Panquecas',
      note: text.contains('frango')
          ? 'Frango'
          : text.contains('carne')
              ? 'Carne'
              : 'Recheada',
      colors: const [Color(0xFFB6462F), Color(0xFFD7A552)],
    );
  }
  if (text.contains('bebida')) {
    return const CategoryVisual(
      label: 'Bebidas',
      note: 'Geladas',
      colors: [Color(0xFF7B2E1F), Color(0xFFD7A552)],
    );
  }
  if (text.contains('bolo')) {
    return const CategoryVisual(
      label: 'Bolos',
      note: 'Fatia',
      colors: [Color(0xFF7B2E1F), Color(0xFFD7A552)],
    );
  }
  if (text.contains('doce') ||
      text.contains('brigadeiro') ||
      text.contains('sobremesa')) {
    return const CategoryVisual(
      label: 'Doces',
      note: 'Sobremesa',
      colors: [Color(0xFFB6462F), Color(0xFFF2D8CF)],
    );
  }

  return const CategoryVisual(
    label: 'Artesanal',
    note: 'Da Ray',
    colors: [AppTheme.primaryRed, AppTheme.gold],
  );
}

String normalizedCatalogText(String value) => _normalized(value);

String _normalized(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}

class RayFoodPlaceholder extends StatelessWidget {
  const RayFoodPlaceholder({
    required this.product,
    this.size = 86,
    super.key,
  });

  final ProductModel product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = visualForText('${product.name} ${product.description}');

    return RayCatalogIllustration(
      visual: visual,
      size: size,
    );
  }
}

class RayCatalogIllustration extends StatelessWidget {
  const RayCatalogIllustration({
    required this.visual,
    this.size = 86,
    super.key,
  });

  final CategoryVisual visual;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: LinearGradient(
          colors: visual.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.12),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: Text(
            visual.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.warmWhite,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.13,
                  height: 1.08,
                ),
          ),
        ),
      ),
    );
  }
}
