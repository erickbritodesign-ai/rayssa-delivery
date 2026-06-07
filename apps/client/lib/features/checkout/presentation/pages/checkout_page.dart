import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rayssa_client/core/config/ray_payment_config.dart';
import 'package:rayssa_client/core/platform/external_link_launcher.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/core/widgets/ray_brand.dart';
import 'package:rayssa_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:rayssa_client/features/cart/presentation/providers/cart_providers.dart';
import 'package:rayssa_client/features/checkout/domain/models/delivery_area.dart';
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
  final _complementController = TextEditingController();
  final _notesController = TextEditingController();

  DeliveryArea? _selectedArea;
  _PaymentSelection? _selectedPayment;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(selectedDeliveryAreaProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    final deliveryType = ref.read(deliveryTypeProvider);
    if (!_validateDelivery(deliveryType)) return;

    final payment = _selectedPayment;
    if (payment == null) {
      await _openPaymentSheet();
      return;
    }

    await _submit(payment);
  }

  bool _validateDelivery(DeliveryType deliveryType) {
    if (deliveryType == DeliveryType.pickup) return true;

    final street = _streetController.text.trim();
    final number = _numberController.text.trim();
    final area = _selectedArea;

    if (street.isEmpty || number.isEmpty || area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha rua, número e bairro para entrega.'),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _openPaymentSheet() async {
    final total = ref.read(checkoutTotalProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    final result = await showModalBottomSheet<_PaymentSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PaymentSheet(
          totalLabel: currency.format(total),
          initialSelection: _selectedPayment,
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _selectedPayment = result);
    }
  }

  Future<void> _submit(_PaymentSelection payment) async {
    final deliveryType = ref.read(deliveryTypeProvider);
    final deliveryFee = ref.read(deliveryFeeProvider);
    AddressModel? address;

    if (deliveryType == DeliveryType.delivery) {
      final area = _selectedArea!;
      address = AddressModel(
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        neighborhood: area.name,
        city: 'Pedro Canário',
        state: 'ES',
        zipCode: '29950-000',
        deliveryFee: deliveryFee,
        complement: _complementController.text.trim().isEmpty
            ? null
            : _complementController.text.trim(),
      );
    }

    final orderId =
        await ref.read(checkoutControllerProvider.notifier).placeOrder(
              address: address,
              paymentMethod: payment.method,
              changeFor: payment.changeFor,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );

    if (!mounted) return;

    if (orderId == null) {
      final error = ref.read(checkoutControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível confirmar: $error')),
      );
      return;
    }

    if (payment.method == PaymentMethod.pixApp) {
      await _showPixConfirmation(orderId);
    }

    if (mounted) context.go('/orders/$orderId');
  }

  Future<void> _showPixConfirmation(String orderId) async {
    final total = ref.read(checkoutTotalProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pix pelo aplicativo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pedido #${_shortOrderId(orderId)} confirmado.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _PixInfo(totalLabel: currency.format(total)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _copyPixKey,
              child: const Text('Copiar chave Pix'),
            ),
            FilledButton(
              onPressed: () => _openWhatsAppProof(orderId),
              child: const Text('Enviar comprovante'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyPixKey() async {
    await Clipboard.setData(
      const ClipboardData(text: RayPaymentConfig.pixKey),
    );
    if (!mounted) return;

    final isTodo = RayPaymentConfig.pixKey.contains('TODO');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTodo
              ? 'Chave Pix ainda precisa ser configurada.'
              : 'Chave Pix copiada.',
        ),
      ),
    );
  }

  Future<void> _openWhatsAppProof(String orderId) async {
    final phone = RayPaymentConfig.whatsappNumber.trim();
    if (phone.isEmpty || phone.contains('TODO')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure o WhatsApp da Ray para enviar comprovante.'),
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    final customerName = user?.name.trim();
    final safeCustomerName =
        customerName == null || customerName.isEmpty ? 'Cliente' : customerName;
    final total = ref.read(checkoutTotalProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final message = [
      'Olá, Ray! Segue o comprovante do pedido #${_shortOrderId(orderId)}.',
      'Cliente: $safeCustomerName',
      'Total: ${currency.format(total)}',
    ].join('\n');

    final uri = Uri.https('wa.me', '/$phone', {'text': message});
    final opened = await ExternalLinkLauncher.open(uri);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
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

    final hasPayment = _selectedPayment != null;

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
              onSelectionChanged: (value) {
                ref.read(deliveryTypeProvider.notifier).state = value.first;
              },
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
                  TextField(
                    controller: _numberController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Número'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<DeliveryArea>(
                    value: _selectedArea,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bairro',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: pedroCanarioDeliveryAreas
                        .map(
                          (area) => DropdownMenuItem(
                            value: area,
                            child: Text(area.name),
                          ),
                        )
                        .toList(),
                    onChanged: (area) {
                      setState(() => _selectedArea = area);
                      ref.read(selectedDeliveryAreaProvider.notifier).state =
                          area;
                    },
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
                hintText: 'Ex.: tirar cebola, ponto da massa...',
              ),
            ),
          ),
          _CheckoutSection(
            icon: Icons.payments_outlined,
            title: 'Pagamento',
            child: _PaymentSummary(
              selection: _selectedPayment,
              onChange: _openPaymentSheet,
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
            onPressed:
                checkoutState.isLoading ? null : _handlePrimaryAction,
            icon: checkoutState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(hasPayment
                    ? Icons.check_circle_outline
                    : Icons.payments_outlined),
            label: Text(
              hasPayment ? 'Confirmar pedido' : 'Escolher método de pagamento',
            ),
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

class _PaymentSelection {
  const _PaymentSelection({
    required this.method,
    this.needsChange = false,
    this.changeFor,
  });

  final PaymentMethod method;
  final bool needsChange;
  final double? changeFor;
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.totalLabel,
    required this.initialSelection,
  });

  final String totalLabel;
  final _PaymentSelection? initialSelection;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _changeForController = TextEditingController();
  PaymentMethod? _method;
  bool _needsChange = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelection;
    _method = initial?.method;
    _needsChange = initial?.needsChange ?? false;
    if (initial?.changeFor != null) {
      _changeForController.text =
          initial!.changeFor!.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _changeForController.dispose();
    super.dispose();
  }

  void _confirm() {
    final method = _method;
    if (method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma forma de pagamento.')),
      );
      return;
    }

    double? changeFor;
    if (method == PaymentMethod.cash && _needsChange) {
      changeFor = _parseMoney(_changeForController.text);
      if (changeFor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o valor para troco.')),
        );
        return;
      }
    }

    Navigator.of(context).pop(
      _PaymentSelection(
        method: method,
        needsChange: method == PaymentMethod.cash && _needsChange,
        changeFor: changeFor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Método de pagamento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Escolha como deseja pagar o pedido de ${widget.totalLabel}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _PaymentOption(
                icon: Icons.payments_outlined,
                title: 'Dinheiro na entrega',
                subtitle: 'Pague quando receber o pedido.',
                selected: _method == PaymentMethod.cash,
                onTap: () => setState(() => _method = PaymentMethod.cash),
              ),
              if (_method == PaymentMethod.cash) ...[
                const SizedBox(height: 8),
                _ChangeCard(
                  needsChange: _needsChange,
                  controller: _changeForController,
                  onChanged: (value) => setState(() => _needsChange = value),
                ),
              ],
              _PaymentOption(
                icon: Icons.credit_card,
                title: 'Cartão de crédito na entrega',
                subtitle: 'Pagamento na maquininha.',
                selected: _method == PaymentMethod.creditCard,
                onTap: () =>
                    setState(() => _method = PaymentMethod.creditCard),
              ),
              _PaymentOption(
                icon: Icons.credit_card,
                title: 'Cartão de débito na entrega',
                subtitle: 'Pagamento na maquininha.',
                selected: _method == PaymentMethod.debitCard,
                onTap: () => setState(() => _method = PaymentMethod.debitCard),
              ),
              _PaymentOption(
                icon: Icons.pix,
                title: 'Pix na entrega',
                subtitle: 'A Ray confirma o Pix na entrega.',
                selected: _method == PaymentMethod.pixOnDelivery,
                onTap: () =>
                    setState(() => _method = PaymentMethod.pixOnDelivery),
              ),
              _PaymentOption(
                icon: Icons.qr_code_2_outlined,
                title: 'Pix pelo aplicativo',
                subtitle: 'Use a chave Pix e envie o comprovante depois.',
                selected: _method == PaymentMethod.pixApp,
                onTap: () => setState(() => _method = PaymentMethod.pixApp),
              ),
              if (_method == PaymentMethod.pixApp) ...[
                const SizedBox(height: 8),
                _PixInfo(totalLabel: widget.totalLabel),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: RayPaymentConfig.pixKey),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chave Pix copiada.')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar chave Pix'),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check),
                label: const Text('Usar este pagamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? AppTheme.blush : AppTheme.warmWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryRed : AppTheme.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppTheme.warmWhite : AppTheme.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Radio<bool>(
                value: true,
                groupValue: selected,
                onChanged: (_) => onTap(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({
    required this.needsChange,
    required this.controller,
    required this.onChanged,
  });

  final bool needsChange;
  final TextEditingController controller;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Precisa de troco?'),
            value: needsChange,
            onChanged: onChanged,
          ),
          if (needsChange) ...[
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Troco para quanto?',
                prefixText: 'R\$ ',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PixInfo extends StatelessWidget {
  const _PixInfo({required this.totalLabel});

  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.chocolate,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            RayPaymentConfig.pixReceiverName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.warmWhite,
                ),
          ),
          const SizedBox(height: 8),
          _PixLine(label: 'Total', value: totalLabel),
          _PixLine(label: 'Chave Pix', value: RayPaymentConfig.pixKey),
          const SizedBox(height: 8),
          Text(
            'Depois de confirmar, você pode copiar a chave e enviar o comprovante pelo WhatsApp.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.cream,
                ),
          ),
        ],
      ),
    );
  }
}

class _PixLine extends StatelessWidget {
  const _PixLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warmWhite,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.selection,
    required this.onChange,
  });

  final _PaymentSelection? selection;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final selected = selection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected == null)
          Text(
            'Escolha a forma de pagamento antes de enviar o pedido.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected.method.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          if (selected.changeFor != null) ...[
            const SizedBox(height: 6),
            Text(
              'Troco para R\$ ${selected.changeFor!.toStringAsFixed(2).replaceAll('.', ',')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onChange,
          icon: const Icon(Icons.payments_outlined),
          label: Text(selected == null ? 'Escolher pagamento' : 'Alterar'),
        ),
      ],
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

double? _parseMoney(String text) {
  final normalized = text
      .replaceAll('R\$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();
  return double.tryParse(normalized);
}

String _shortOrderId(String orderId) {
  if (orderId.length <= 8) return orderId;
  return orderId.substring(0, 8);
}
