import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_admin/shared/data/admin_firestore_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final storeSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminFirestoreProvider).watchStoreSettings();
});

final deliveryZonesAdminProvider =
    StreamProvider<List<DeliveryZoneModel>>((ref) {
  return ref.watch(adminFirestoreProvider).watchDeliveryZones();
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
  final _tableCountController = TextEditingController();

  bool _loaded = false;
  bool _isOpen = true;

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _pixKeyController.dispose();
    _deliveryFeeController.dispose();
    _tableCountController.dispose();
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
    _tableCountController.text = '${data['tableCount'] ?? 10}';
    _isOpen = data['isOpen'] != false;

    _loaded = true;
  }

  Future<void> _save() async {
    final deliveryFee =
        double.tryParse(_deliveryFeeController.text.replaceAll(',', '.')) ?? 5;
    final tableCount =
        (int.tryParse(_tableCountController.text) ?? 10).clamp(1, 99);

    await ref.read(adminFirestoreProvider).saveStoreSettings({
      'storeName': _storeNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'instagram': _instagramController.text.trim(),
      'pixKey': _pixKeyController.text.trim(),
      'deliveryFee': deliveryFee,
      'tableCount': tableCount,
      'isOpen': _isOpen,
    });
    await ref
        .read(adminFirestoreProvider)
        .ensureDefaultTables(count: tableCount);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações salvas com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(storeSettingsProvider);
    final zonesAsync = ref.watch(deliveryZonesAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: settingsAsync.when(
        data: (data) {
          _fillForm(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
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
                      labelText: 'Taxa padrão (fallback)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tableCountController,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade de mesas',
                      helperText: 'Entre 1 e 99 mesas',
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
                  const SizedBox(height: 32),
                  _DeliveryZonesSection(
                    zonesAsync: zonesAsync,
                    onAdd: () => _editZone(context),
                    onEdit: (zone) => _editZone(context, zone),
                    onToggle: (zone, active) =>
                        ref.read(adminFirestoreProvider).saveDeliveryZone(
                              DeliveryZoneModel(
                                id: zone.id,
                                name: zone.name,
                                fee: zone.fee,
                                isActive: active,
                                order: zone.order,
                              ),
                            ),
                    onDelete: (zone) => _deleteZone(context, zone),
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

  Future<void> _editZone(
    BuildContext context, [
    DeliveryZoneModel? zone,
  ]) async {
    final name = TextEditingController(text: zone?.name);
    final fee = TextEditingController(
      text: zone == null ? '' : zone.fee.toStringAsFixed(2),
    );
    final order = TextEditingController(text: '${zone?.order ?? 0}');
    var active = zone?.isActive ?? true;
    final result = await showDialog<DeliveryZoneModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(zone == null ? 'Adicionar bairro' : 'Editar bairro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Bairro'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fee,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Taxa'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: order,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ordem'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativo'),
                  value: active,
                  onChanged: (value) {
                    setDialogState(() => active = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final cleanName = name.text.trim();
                final parsedFee =
                    double.tryParse(fee.text.replaceAll(',', '.'));
                if (cleanName.isEmpty || parsedFee == null || parsedFee < 0) {
                  return;
                }
                Navigator.pop(
                  context,
                  DeliveryZoneModel(
                    id: zone?.id ?? '',
                    name: cleanName,
                    fee: parsedFee,
                    isActive: active,
                    order: int.tryParse(order.text) ?? 0,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    fee.dispose();
    order.dispose();
    if (result == null) return;
    await ref.read(adminFirestoreProvider).saveDeliveryZone(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bairro salvo.')),
    );
  }

  Future<void> _deleteZone(
    BuildContext context,
    DeliveryZoneModel zone,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir bairro?'),
        content: Text('Excluir “${zone.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminFirestoreProvider).deleteDeliveryZone(zone.id);
    }
  }
}

class _DeliveryZonesSection extends StatelessWidget {
  const _DeliveryZonesSection({
    required this.zonesAsync,
    required this.onAdd,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final AsyncValue<List<DeliveryZoneModel>> zonesAsync;
  final VoidCallback onAdd;
  final ValueChanged<DeliveryZoneModel> onEdit;
  final void Function(DeliveryZoneModel zone, bool active) onToggle;
  final ValueChanged<DeliveryZoneModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bairros e taxas',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gerencie os bairros atendidos e suas taxas de entrega.',
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Adicionar bairro'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              zonesAsync.when(
                data: (zones) => zones.isEmpty
                    ? const SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Nenhum bairro cadastrado. A taxa padrão será usada até o primeiro cadastro.',
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: zones
                            .map(
                              (zone) => _DeliveryZoneCard(
                                zone: zone,
                                onEdit: () => onEdit(zone),
                                onToggle: (active) => onToggle(zone, active),
                                onDelete: () => onDelete(zone),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Erro ao carregar bairros: $error'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryZoneCard extends StatelessWidget {
  const _DeliveryZoneCard({
    required this.zone,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final DeliveryZoneModel zone;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zone.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                'R\$ ${zone.fee.toStringAsFixed(2).replaceAll('.', ',')} · Ordem ${zone.order}',
              ),
            ],
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: zone.isActive, onChanged: onToggle),
              IconButton(
                tooltip: 'Editar',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Excluir',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          );

          if (compact) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 12),
                actions,
              ],
            ),
          );
        },
      ),
    );
  }
}
