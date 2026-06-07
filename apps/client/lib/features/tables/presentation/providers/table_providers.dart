import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_client/features/tables/data/table_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final tableServiceProvider = Provider<TableService>((ref) {
  return TableService();
});

final tablesProvider = StreamProvider<List<TableModel>>((ref) {
  return ref.watch(tableServiceProvider).watchTables();
});

final tableSessionProvider =
    StreamProvider.family<TableSessionModel?, String>((ref, tableId) {
  return ref.watch(tableServiceProvider).watchOpenSession(tableId);
});
