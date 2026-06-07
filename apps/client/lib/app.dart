import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_client/core/router/app_router.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/core/theme/theme_mode_controller.dart';

class RayssaClientApp extends ConsumerWidget {
  const RayssaClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final darkThemeEnabled = ref.watch(darkThemeEnabledProvider);
    return MaterialApp.router(
      title: 'Rayssa Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: darkThemeEnabled ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return ColoredBox(
          color: darkThemeEnabled ? AppTheme.darkSurface : AppTheme.surface,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
