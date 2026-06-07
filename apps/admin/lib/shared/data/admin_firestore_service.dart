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
    return _firestore
        .collection(FirestoreCollections.categorias)
        .doc(id)
        .delete();
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
    return _firestore
        .collection(FirestoreCollections.produtos)
        .doc(id)
        .delete();
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
    return _firestore
        .collection(FirestoreCollections.pedidos)
        .doc(orderId)
        .update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<TableModel>> watchTables() {
    return _firestore
        .collection(FirestoreCollections.tables)
        .orderBy('number')
        .snapshots()
        .map((snapshot) {
      final tables = snapshot.docs
          .map((doc) => TableModel.fromFirestore(doc.id, doc.data()))
          .toList();

      return mergeWithDefaultTables(tables);
    });
  }

  Future<void> ensureDefaultTables() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.tables)
        .where('number', isGreaterThanOrEqualTo: 1)
        .where('number', isLessThanOrEqualTo: defaultTableCount)
        .get();
    final existingNumbers = snapshot.docs
        .map((doc) => (doc.data()['number'] as num?)?.toInt())
        .whereType<int>()
        .toSet();
    final batch = _firestore.batch();
    var hasWrites = false;

    for (var number = 1; number <= defaultTableCount; number++) {
      if (existingNumbers.contains(number)) continue;

      hasWrites = true;
      batch.set(
        _firestore.collection(FirestoreCollections.tables).doc('mesa-$number'),
        {
          'number': number,
          'name': 'Mesa $number',
          'status': TableStatus.free.value,
          'currentSessionId': null,
          'currentTotal': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    if (hasWrites) await batch.commit();
  }

  Stream<TableSessionModel?> watchOpenTableSession(String tableId) {
    return _firestore
        .collection(FirestoreCollections.tableSessions)
        .where('tableId', isEqualTo: tableId)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs
          .map((doc) => TableSessionModel.fromFirestore(doc.id, doc.data()))
          .where((session) {
        return session.status == TableSessionStatus.open ||
            session.status == TableSessionStatus.preparing ||
            session.status == TableSessionStatus.waitingPayment;
      }).toList();

      sessions.sort((a, b) {
        final aDate = a.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return sessions.isEmpty ? null : sessions.first;
    });
  }

  Future<void> updateTableSessionStatus(
    TableSessionModel session,
    TableSessionStatus status,
  ) async {
    final tableStatus = switch (status) {
      TableSessionStatus.open => TableStatus.open,
      TableSessionStatus.preparing => TableStatus.preparing,
      TableSessionStatus.waitingPayment => TableStatus.waitingPayment,
      TableSessionStatus.closed => TableStatus.free,
      TableSessionStatus.cancelled => TableStatus.free,
    };

    final batch = _firestore.batch();
    batch.update(
      _firestore.collection(FirestoreCollections.tableSessions).doc(session.id),
      {
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == TableSessionStatus.closed)
          'closedAt': FieldValue.serverTimestamp(),
        if (status == TableSessionStatus.closed)
          'paymentStatus': PaymentStatus.paid.value,
        if (status == TableSessionStatus.closed)
          'paymentMethod': PaymentMethod.notSelected.value,
      },
    );
    batch.set(
      _firestore.collection(FirestoreCollections.tables).doc(session.tableId),
      {
        'number': session.tableNumber,
        'name': 'Mesa ${session.tableNumber}',
        'status': tableStatus.value,
        'currentSessionId': tableStatus == TableStatus.free ? null : session.id,
        'currentTotal': tableStatus == TableStatus.free ? 0 : session.total,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    if (status == TableSessionStatus.closed) {
      for (final orderId in session.orderIds) {
        batch.update(
          _firestore.collection(FirestoreCollections.pedidos).doc(orderId),
          {
            'status': OrderStatus.delivered.value,
            'paymentStatus': PaymentStatus.paid.value,
            'paymentMethod': PaymentMethod.notSelected.value,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
    }
    await batch.commit();
  }

  Stream<Map<String, dynamic>> watchStoreSettings() {
    return _firestore
        .collection('configuracoes')
        .doc('store')
        .snapshots()
        .map((doc) {
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
