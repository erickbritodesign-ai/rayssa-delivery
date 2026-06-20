import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rayssa_admin/features/orders/utils/order_receipt_formatter.dart';
import 'package:rayssa_admin/features/orders/utils/print_order.dart';
import 'package:rayssa_core/rayssa_core.dart';
import 'package:share_plus/share_plus.dart';

class PrintOrderDialog extends StatelessWidget {
  const PrintOrderDialog({
    super.key,
    required this.order,
    this.customerName,
    this.customerPhone,
  });

  final OrderModel order;
  final String? customerName;
  final String? customerPhone;

  static Future<void> show(
    BuildContext context, {
    required OrderModel order,
    String? customerName,
    String? customerPhone,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PrintOrderDialog(
        order: order,
        customerName: customerName,
        customerPhone: customerPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptText = OrderReceiptFormatter.format(
      order,
      customerName: customerName,
      customerPhone: customerPhone,
    );
    final mediaQuery = MediaQuery.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: mediaQuery.size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Imprimir pedido',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFEFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE1D8CF)),
                      ),
                      child: SelectableText(
                        receiptText,
                        style: const TextStyle(
                          color: Color(0xFF1D1D1D),
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _copy(context, receiptText),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar comanda'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _share(context, receiptText),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartilhar'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _print(context, receiptText),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Imprimir'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ].map((button) {
                  return SizedBox(height: 48, child: button);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String receiptText) async {
    await Clipboard.setData(ClipboardData(text: receiptText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comanda copiada.')),
    );
  }

  Future<void> _share(BuildContext context, String receiptText) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    await Share.share(
      receiptText,
      subject: 'Pedido #${OrderReceiptFormatter.shortOrderCode(order.id)}',
      sharePositionOrigin: renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size,
    );
  }

  Future<void> _print(BuildContext context, String receiptText) async {
    final opened = await printOrderReceipt(receiptText);
    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impressão disponível na versão Web do Admin.'),
      ),
    );
  }
}
