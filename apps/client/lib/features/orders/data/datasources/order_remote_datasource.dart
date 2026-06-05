import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayssa_core/rayssa_core.dart';

class OrderRemoteDatasource {
  OrderRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _firestore
        .collection(FirestoreCollections.pedidos)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<OrderModel?> watchOrder(String orderId) {
    return _firestore
        .collection(FirestoreCollections.pedidos)
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(doc.id, doc.data()!);
    });
  }

  Future<String> createOrder(OrderModel order) async {
    final doc = _firestore.collection(FirestoreCollections.pedidos).doc();
    final payload = {
      ...order.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await doc.set(payload);
    return doc.id;
  }
}
