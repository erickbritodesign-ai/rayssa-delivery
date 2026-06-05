import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayssa_core/rayssa_core.dart';

class AdminFirestoreService {
  AdminFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // --- Categorias ---
  Stream<List<CategoryModel>> watchCategories() {
    return _firestore
        .collection(FirestoreCollections.categorias)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => CategoryModel.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> upsertCategory(CategoryModel category) {
    return _firestore
        .collection(FirestoreCollections.categorias)
        .doc(category.id.isEmpty ? null : category.id)
        .set(category.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) {
    return _firestore.collection(FirestoreCollections.categorias).doc(id).delete();
  }

  // --- Produtos ---
  Stream<List<ProductModel>> watchProducts() {
    return _firestore
        .collection(FirestoreCollections.produtos)
        .orderBy('name')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => ProductModel.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> upsertProduct(ProductModel product) {
    return _firestore
        .collection(FirestoreCollections.produtos)
        .doc(product.id.isEmpty ? null : product.id)
        .set(product.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String id) {
    return _firestore.collection(FirestoreCollections.produtos).doc(id).delete();
  }

  // --- Pedidos ---
  Stream<List<OrderModel>> watchOrders() {
    return _firestore
        .collection(FirestoreCollections.pedidos)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => OrderModel.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) {
    return _firestore.collection(FirestoreCollections.pedidos).doc(orderId).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> countOrdersToday() async {
    final start = DateTime.now();
    final startOfDay = DateTime(start.year, start.month, start.day);
    final snapshot = await _firestore
        .collection(FirestoreCollections.pedidos)
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .get();
    return snapshot.size;
  }
}

final adminFirestoreProvider = Provider<AdminFirestoreService>((ref) {
  return AdminFirestoreService();
  });