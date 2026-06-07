import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rayssa_admin/features/auth/presentation/pages/admin_login_page.dart';
import 'package:rayssa_admin/features/auth/presentation/providers/admin_auth_providers.dart';
import 'package:rayssa_admin/features/categories/presentation/pages/categories_page.dart';
import 'package:rayssa_admin/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:rayssa_admin/features/orders/presentation/pages/admin_orders_page.dart';
import 'package:rayssa_admin/features/products/presentation/pages/products_page.dart';
import 'package:rayssa_admin/features/settings/presentation/pages/settings_page.dart';
import 'package:rayssa_admin/features/tables/presentation/pages/admin_tables_page.dart';
import 'package:rayssa_admin/shared/widgets/admin_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(adminAuthStateProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authState,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLogin) return '/login';
      if (isLoggedIn && isLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsPage(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const AdminOrdersPage(),
          ),
          GoRoute(
            path: '/tables',
            builder: (context, state) => const AdminTablesPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
