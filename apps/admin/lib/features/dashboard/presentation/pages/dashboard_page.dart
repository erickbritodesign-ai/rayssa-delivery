import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';

final ordersTodayProvider = FutureProvider<int>((ref) {
  return ref.watch(adminFirestoreProvider).countOrdersToday();
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersToday = ref.watch(ordersTodayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ordersToday.when(
          data: (count) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(title: 'Pedidos hoje', value: '$count'),
              const _StatCard(
                title: 'Faturamento',
                value: 'Em breve',
                subtitle: 'MVP: métrica na V2',
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erro: $e'),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 220,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (subtitle != null) Text(subtitle!),
            ],
          ),
        ),
      ),
    );
  }
}
