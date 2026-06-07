import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_core/rayssa_core.dart';

class AdminFirestoreService {
  AdminFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CategoryModel>> watchCategories() {
    return _firestore
        .collection(FirestoreCollections.categorias)
        .orderBy('sortOrder')
        .snapshots()
        .map((s) => s.docs
            .map((d) => CategoryModel.fromFirestore(d.id, d.data()))
            .toList());
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

  Stream<List<ProductModel>> watchProducts() {
    return _firestore
        .collection(FirestoreCollections.produtos)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ProductModel.fromFirestore(d.id, d.data()))
            .toList());
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

  Stream<List<OrderModel>> watchOrders() {
    return _firestore
        .collection(FirestoreCollections.pedidos)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => OrderModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) {
    return _firestore.collection(FirestoreCollections.pedidos).doc(orderId).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>> watchStoreSettings() {
    return _firestore.collection('configuracoes').doc('store').snapshots().map((doc) {
      if (!doc.exists) {
        return {
          'storeName': 'Rayssa Delivery',
          'phone': '',
          'instagram': '',
          'pixKey': '',
          'deliveryFee': 5,
          'isOpen': true,
        };
      }
      return doc.data() ?? {};
    });
  }

  Future<void> saveStoreSettings(Map<String, dynamic> data) {
    return _firestore.collection('configuracoes').doc('store').set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final adminFirestoreProvider = Provider<AdminFirestoreService>((ref) {
  return AdminFirestoreService();
});
