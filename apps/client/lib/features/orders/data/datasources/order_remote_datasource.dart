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
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.id, doc.data()))
          .toList();

      orders.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return orders;
    });
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
    final orderDateKey = BrazilClock.dateKey();
    final counterRef = _firestore
        .collection(FirestoreCollections.orderCounters)
        .doc(orderDateKey);
    final userRef =
        _firestore.collection(FirestoreCollections.usuarios).doc(order.userId);

    await _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);
      final dailyOrderNumber =
          ((counterSnapshot.data()?['current'] as num?)?.toInt() ?? 0) + 1;
      DocumentSnapshot<Map<String, dynamic>>? userSnapshot;
      if (order.loyaltyRewardApplied && order.loyaltyPointsRedeemed > 0) {
        userSnapshot = await transaction.get(userRef);
        final currentPoints =
            (userSnapshot.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
        if (currentPoints < order.loyaltyPointsRedeemed) {
          throw StateError('Pontos insuficientes para aplicar o resgate.');
        }
      }

      transaction.set(counterRef, {
        'current': dailyOrderNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(doc, {
        ...order.toFirestore(),
        'dailyOrderNumber': dailyOrderNumber,
        'orderDateKey': orderDateKey,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (userSnapshot != null) {
        transaction.set(
          userRef,
          {
            'loyaltyPoints': FieldValue.increment(-order.loyaltyPointsRedeemed),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    return doc.id;
  }
}
