import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rayssa_admin/features/auth/presentation/providers/admin_auth_providers.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForPath(location);
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    if (isMobile) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            context.go(_pathForIndex(index));
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: 'Cat.',
            ),
            NavigationDestination(
              icon: Icon(Icons.fastfood_outlined),
              selectedIcon: Icon(Icons.fastfood),
              label: 'Prod.',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Ped.',
            ),
            NavigationDestination(
              icon: Icon(Icons.table_restaurant_outlined),
              selectedIcon: Icon(Icons.table_restaurant),
              label: 'Mesas',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Config.',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              context.go(_pathForIndex(index));
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.storefront),
                label: Text('Vitrine'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category),
                label: Text('Categorias'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.fastfood),
                label: Text('Produtos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt),
                label: Text('Pedidos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.table_restaurant),
                label: Text('Mesas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Config.'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IconButton(
                  tooltip: 'Sair',
                  icon: const Icon(Icons.logout),
                  onPressed: () =>
                      ref.read(adminAuthControllerProvider.notifier).signOut(),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _indexForPath(String path) {
    if (path.startsWith('/home')) return 1;
    if (path.startsWith('/categories')) return 2;
    if (path.startsWith('/products')) return 3;
    if (path.startsWith('/orders')) return 4;
    if (path.startsWith('/tables')) return 5;
    if (path.startsWith('/settings')) return 6;
    return 0;
  }

  String _pathForIndex(int index) {
    switch (index) {
      case 1:
        return '/home';
      case 2:
        return '/categories';
      case 3:
        return '/products';
      case 4:
        return '/orders';
      case 5:
        return '/tables';
      case 6:
        return '/settings';
      default:
        return '/';
    }
  }
}
