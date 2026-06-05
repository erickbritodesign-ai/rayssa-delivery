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

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _indexForPath(location),
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
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IconButton(
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
    if (path.startsWith('/categories')) return 1;
    if (path.startsWith('/products')) return 2;
    if (path.startsWith('/orders')) return 3;
    return 0;
  }

  String _pathForIndex(int index) {
    switch (index) {
      case 1:
        return '/categories';
      case 2:
        return '/products';
      case 3:
        return '/orders';
      default:
        return '/';
    }
  }
}
