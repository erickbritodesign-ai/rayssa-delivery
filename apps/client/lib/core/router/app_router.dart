import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rayssa_client/features/auth/presentation/pages/login_page.dart';
import 'package:rayssa_client/features/auth/presentation/pages/register_page.dart';
import 'package:rayssa_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:rayssa_client/features/cart/presentation/pages/cart_page.dart';
import 'package:rayssa_client/features/checkout/presentation/pages/checkout_page.dart';
import 'package:rayssa_client/features/menu/presentation/pages/home_page.dart';
import 'package:rayssa_client/features/orders/presentation/pages/order_detail_page.dart';
import 'package:rayssa_client/features/orders/presentation/pages/orders_page.dart';
import 'package:rayssa_client/features/profile/presentation/pages/profile_page.dart';
import 'package:rayssa_client/features/tables/presentation/pages/table_add_items_page.dart';
import 'package:rayssa_client/features/tables/presentation/pages/table_detail_page.dart';
import 'package:rayssa_client/features/tables/presentation/pages/table_service_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authState,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isTableRoute = state.uri.path.startsWith('/tables');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      if (isLoggedIn && isTableRoute && !authState.canAccessTableService) {
        return '/profile?restricted=tables';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfilePage(
          showAccessDeniedMessage:
              state.uri.queryParameters['restricted'] == 'tables',
        ),
      ),
      GoRoute(
        path: '/tables',
        builder: (context, state) => const TableServicePage(),
      ),
      GoRoute(
        path: '/tables/:id',
        builder: (context, state) => TableDetailPage(
          tableId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/tables/:id/add',
        builder: (context, state) => TableAddItemsPage(
          tableId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderDetailPage(
          orderId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
