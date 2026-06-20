import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rayssa_admin/features/orders/utils/print_order.dart';
import 'package:share_plus/share_plus.dart';

class PrintTextDialog extends StatelessWidget {
  const PrintTextDialog({
    super.key,
    required this.title,
    required this.text,
    required this.subject,
    this.copyLabel = 'Copiar',
    this.copyMessage = 'Texto copiado.',
  });

  final String title;
  final String text;
  final String subject;
  final String copyLabel;
  final String copyMessage;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String text,
    required String subject,
    String copyLabel = 'Copiar',
    String copyMessage = 'Texto copiado.',
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PrintTextDialog(
        title: title,
        text: text,
        subject: subject,
        copyLabel: copyLabel,
        copyMessage: copyMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE1D8CF)),
                    ),
                    child: SelectableText(
                      text,
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(copyLabel),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartilhar'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _print(context),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Imprimir'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ].map((button) => SizedBox(height: 48, child: button)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(copyMessage)),
    );
  }

  Future<void> _share(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin: renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size,
    );
  }

  Future<void> _print(BuildContext context) async {
    final opened = await printOrderReceipt(text);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impressão disponível no Admin Web.')),
    );
  }
}
