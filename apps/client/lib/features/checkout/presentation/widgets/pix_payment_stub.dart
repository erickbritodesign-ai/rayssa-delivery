import 'package:flutter/material.dart';

/// Placeholder de PIX — integração real via Cloud Functions + Mercado Pago.
class PixPaymentStub extends StatelessWidget {
  const PixPaymentStub({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagamento PIX',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'A integração com Mercado Pago será ativada após configurar '
              'as credenciais nas Cloud Functions.',
            ),
            const SizedBox(height: 12),
            SelectableText('Pedido: $orderId'),
            const SizedBox(height: 8),
            const Text('QR Code e copia-e-cola aparecerão aqui.'),
          ],
        ),
      ),
    );
  }
}
