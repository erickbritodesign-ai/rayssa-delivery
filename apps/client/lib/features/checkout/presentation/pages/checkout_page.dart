import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/core/widgets/ray_brand.dart';
import 'package:rayssa_client/features/cart/presentation/providers/cart_providers.dart';
import 'package:rayssa_client/features/checkout/presentation/providers/checkout_providers.dart';
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

    final orderId =
        await ref.read(checkoutControllerProvider.notifier).placeOrder(
              address: address,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );

    if (orderId != null && mounted) {
      context.go('/orders/$orderId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartControllerProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(deliveryFeeProvider);
    final total = ref.watch(checkoutTotalProvider);
    final deliveryType = ref.watch(deliveryTypeProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finalizar pedido')),
        body: const _EmptyCheckout(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar pedido')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _CheckoutIntro(),
          _CheckoutSection(
            icon: Icons.delivery_dining,
            title: 'Como você quer receber?',
            child: SegmentedButton<DeliveryType>(
              segments: const [
                ButtonSegment(
                  value: DeliveryType.delivery,
                  icon: Icon(Icons.delivery_dining),
                  label: Text('Entrega'),
                ),
                ButtonSegment(
                  value: DeliveryType.pickup,
                  icon: Icon(Icons.storefront),
                  label: Text('Retirada'),
                ),
              ],
              selected: {deliveryType},
              onSelectionChanged: (value) =>
                  ref.read(deliveryTypeProvider.notifier).state = value.first,
            ),
          ),
          if (deliveryType == DeliveryType.delivery)
            _CheckoutSection(
              icon: Icons.location_on_outlined,
              title: 'Endereço de entrega',
              child: Column(
                children: [
                  TextField(
                    controller: _streetController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Rua'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _numberController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Número'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _neighborhoodController,
                          textInputAction: TextInputAction.next,
                          decoration:
                              const InputDecoration(labelText: 'Bairro'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _complementController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Complemento',
                      hintText: 'Casa, referência, apartamento...',
                    ),
                  ),
                ],
              ),
            ),
          _CheckoutSection(
            icon: Icons.edit_note,
            title: 'Observações para a Ray',
            child: TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Algum detalhe do seu pedido?',
                hintText: 'Ex.: tirar cebola, ponto da massa, troco...',
              ),
            ),
          ),
          _CheckoutSection(
            icon: Icons.receipt_long_outlined,
            title: 'Conferência do pedido',
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: currency.format(subtotal)),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Taxa de entrega',
                  value: currency.format(deliveryFee),
                ),
                const Divider(),
                _SummaryRow(
                  label: 'Total',
                  value: currency.format(total),
                  emphasized: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ElevatedButton.icon(
            onPressed: checkoutState.isLoading ? null : _submit,
            icon: checkoutState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.pix),
            label: const Text('Confirmar pedido com PIX'),
          ),
          const SizedBox(height: 10),
          Text(
            'Depois de confirmar, você acompanha cada etapa do preparo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CheckoutIntro extends StatelessWidget {
  const _CheckoutIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.chocolate,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const RayBrandMark(size: 48, onDark: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Revise com calma. A Ray só recebe seu pedido depois da confirmação.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.cream,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppTheme.primaryRed, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.deepRed,
              fontWeight: FontWeight.w900,
            )
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RayBrandMark(size: 84),
            const SizedBox(height: 18),
            Text(
              'Nada para finalizar ainda',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Volte ao cardápio e escolha algo gostoso antes de pagar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ver cardápio'),
            ),
          ],
        ),
      ),
    );
  }
}
