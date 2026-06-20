import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayssa_client/features/tables/data/table_service.dart';
import 'package:rayssa_core/rayssa_core.dart';

final tableServiceProvider = Provider<TableService>((ref) {
  return TableService();
});

final tablesProvider = StreamProvider<List<TableModel>>((ref) {
  final count = ref.watch(tableCountProvider).valueOrNull ?? 10;
  return ref.watch(tableServiceProvider).watchTables(count: count);
});

final tableCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.configuracoes)
      .doc('store')
      .snapshots()
      .map((doc) {
    return ((doc.data()?['tableCount'] as num?)?.toInt() ?? 10).clamp(1, 99);
  });
});

final tableSessionProvider =
    StreamProvider.family<TableSessionModel?, String>((ref, tableId) {
  return ref.watch(tableServiceProvider).watchOpenSession(tableId);
});
