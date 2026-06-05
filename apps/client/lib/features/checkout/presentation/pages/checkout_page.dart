import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/features/cart/presentation/providers/cart_providers.dart';
import 'package:rayssa_client/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:rayssa_client/features/checkout/presentation/widgets/pix_payment_stub.dart';
import 'package:rayssa_core/rayssa_core.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _complementController = TextEditingController();
  final _notesController = TextEditingController();
  String? _lastOrderId;

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _complementController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final deliveryType = ref.read(deliveryTypeProvider);
    AddressModel? address;
    if (deliveryType == DeliveryType.delivery) {
      if (_streetController.text.isEmpty || _numberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha o endereço de entrega')),
        );
        return;
      }
      address = AddressModel(
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: 'Pedro Canário',
        state: 'ES',
        zipCode: '29950-000',
        complement: _complementController.text.trim().isEmpty
            ? null
            : _complementController.text.trim(),
      );
    }

    final orderId = await ref.read(checkoutControllerProvider.notifier).placeOrder(
          address: address,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (orderId != null && mounted) {
      setState(() => _lastOrderId = orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido criado! Aguardando PIX.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(deliveryFeeProvider);
    final total = ref.watch(checkoutTotalProvider);
    final deliveryType = ref.watch(deliveryTypeProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<DeliveryType>(
              segments: const [
                ButtonSegment(
                  value: DeliveryType.delivery,
                  label: Text('Entrega'),
                ),
                ButtonSegment(
                  value: DeliveryType.pickup,
                  label: Text('Retirada'),
                ),
              ],
              selected: {deliveryType},
              onSelectionChanged: (value) =>
                  ref.read(deliveryTypeProvider.notifier).state = value.first,
            ),
            if (deliveryType == DeliveryType.delivery) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Rua'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Número'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _neighborhoodController,
                decoration: const InputDecoration(labelText: 'Bairro'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _complementController,
                decoration: const InputDecoration(labelText: 'Complemento'),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 16),
            Text('Subtotal: ${currency.format(subtotal)}'),
            Text('Taxa de entrega: ${currency.format(deliveryFee)}'),
            Text(
              'Total: ${currency.format(total)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: checkoutState.isLoading ? null : _submit,
              child: checkoutState.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Confirmar pedido (PIX)'),
            ),
            if (_lastOrderId != null) ...[
              const SizedBox(height: 24),
              PixPaymentStub(orderId: _lastOrderId!),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/orders/$_lastOrderId'),
                child: const Text('Acompanhar pedido'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
