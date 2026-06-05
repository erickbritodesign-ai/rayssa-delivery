import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';

final storeSettingsProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminFirestoreProvider).watchStoreSettings();
});

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _pixKeyController = TextEditingController();
  final _deliveryFeeController = TextEditingController();

  bool _loaded = false;
  bool _isOpen = true;

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _pixKeyController.dispose();
    _deliveryFeeController.dispose();
    super.dispose();
  }

  void _fillForm(Map<String, dynamic> data) {
    if (_loaded) return;

    _storeNameController.text =
        (data['storeName'] ?? 'Rayssa Delivery').toString();
    _phoneController.text = (data['phone'] ?? '').toString();
    _instagramController.text = (data['instagram'] ?? '').toString();
    _pixKeyController.text = (data['pixKey'] ?? '').toString();
    _deliveryFeeController.text = '${data['deliveryFee'] ?? 5}';
    _isOpen = data['isOpen'] != false;

    _loaded = true;
  }

  Future<void> _save() async {
    final deliveryFee =
        double.tryParse(_deliveryFeeController.text.replaceAll(',', '.')) ?? 5;

    await ref.read(adminFirestoreProvider).saveStoreSettings({
      'storeName': _storeNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'instagram': _instagramController.text.trim(),
      'pixKey': _pixKeyController.text.trim(),
      'deliveryFee': deliveryFee,
      'isOpen': _isOpen,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações salvas com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(storeSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: settingsAsync.when(
        data: (data) {
          _fillForm(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Dados da loja',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da loja',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone / WhatsApp',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _instagramController,
                    decoration: const InputDecoration(
                      labelText: 'Instagram',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pixKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Chave PIX',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deliveryFeeController,
                    decoration: const InputDecoration(
                      labelText: 'Taxa de entrega',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Loja aberta'),
                    value: _isOpen,
                    onChanged: (value) {
                      setState(() => _isOpen = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar configurações'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}