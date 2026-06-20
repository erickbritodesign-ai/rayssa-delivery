import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc.id, doc.data()))
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc.id, doc.data()))
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
    return _firestore
        .collection(FirestoreCollections.produtos)
        .doc(id)
        .delete();
  }

  Stream<List<HomeBannerModel>> watchHomeBanners() {
    return _firestore
        .collection(FirestoreCollections.homeBanners)
        .snapshots()
        .map((snapshot) {
      final banners = snapshot.docs
          .map((doc) => HomeBannerModel.fromFirestore(doc.id, doc.data()))
          .toList();
      banners.sort((a, b) => a.order.compareTo(b.order));
      return banners;
    });
  }

  Future<void> upsertHomeBanner(HomeBannerModel banner) {
    return _firestore
        .collection(FirestoreCollections.homeBanners)
        .doc(banner.id.isEmpty ? null : banner.id)
        .set(banner.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteHomeBanner(String id) {
    return _firestore
        .collection(FirestoreCollections.homeBanners)
        .doc(id)
        .delete();
  }

  Stream<List<OrderModel>> watchOrders() {
    return _firestore
        .collection(FirestoreCollections.pedidos)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<OrderModel>> watchRecentOrders({int limit = 150}) {
    return _firestore
        .collection(FirestoreCollections.pedidos)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<UserModel?> getUser(String userId) async {
    if (userId.trim().isEmpty) return null;

    final snapshot = await _firestore
        .collection(FirestoreCollections.usuarios)
        .doc(userId)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;

    return UserModel.fromFirestore(snapshot.id, data);
  }

  Future<int> updateOrderStatus(String orderId, OrderStatus status) async {
    var awardedPoints = 0;
    final orderRef =
        _firestore.collection(FirestoreCollections.pedidos).doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) return;

      final order = OrderModel.fromFirestore(
        orderSnapshot.id,
        orderSnapshot.data() ?? <String, dynamic>{},
      );
      final updates = <String, dynamic>{
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final points = _loyaltyPointsForStatus(order, status);

      if (points > 0) {
        awardedPoints = points;
        final userRef = _firestore
            .collection(FirestoreCollections.usuarios)
            .doc(order.userId);

        transaction.set(
          userRef,
          {
            'loyaltyPoints': FieldValue.increment(points),
            'lifetimeLoyaltyPoints': FieldValue.increment(points),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        updates.addAll({
          'loyaltyPointsAwarded': true,
          'loyaltyPoints': points,
          'loyaltyAwardedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(orderRef, updates);
    });

    return awardedPoints;
  }

  int _loyaltyPointsForStatus(OrderModel order, OrderStatus nextStatus) {
    if (nextStatus != OrderStatus.delivered) return 0;
    if (order.status == OrderStatus.cancelled) return 0;
    if (order.loyaltyPointsAwarded) return 0;
    if (order.userId.trim().isEmpty) return 0;

    final isEligibleType = order.deliveryType == DeliveryType.delivery ||
        order.deliveryType == DeliveryType.pickup;
    if (!isEligibleType) return 0;

    return calculateLoyaltyPointsFromProducts(order);
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

  Future<TableSessionModel> openTable({
    required TableModel table,
    String? guestName,
    String? guestPhone,
  }) async {
    final existing = await _fetchOpenTableSession(table.id);
    if (existing != null) return existing;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sessão administrativa expirada.');

    final sessionRef =
        _firestore.collection(FirestoreCollections.tableSessions).doc();
    final orderRef = _firestore.collection(FirestoreCollections.pedidos).doc();
    final tableRef =
        _firestore.collection(FirestoreCollections.tables).doc(table.id);
    final cleanName = _nullableText(guestName);
    final cleanPhone = _nullableText(guestPhone);
    final orderDateKey = BrazilClock.dateKey();
    final counterRef = _firestore
        .collection(FirestoreCollections.orderCounters)
        .doc(orderDateKey);
    var dailyOrderNumber = 0;

    await _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);
      dailyOrderNumber =
          ((counterSnapshot.data()?['current'] as num?)?.toInt() ?? 0) + 1;

      transaction.set(counterRef, {
        'current': dailyOrderNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(sessionRef, {
        'tableId': table.id,
        'tableNumber': table.number,
        'status': TableSessionStatus.open.value,
        'items': <Map<String, dynamic>>[],
        'subtotal': 0,
        'serviceFee': 0,
        'discount': 0,
        'total': 0,
        'paymentStatus': PaymentStatus.pending.value,
        'guestName': cleanName,
        'guestPhone': cleanPhone,
        'customerNameManual': cleanName,
        'customerPhoneManual': cleanPhone,
        'dailyOrderNumber': dailyOrderNumber,
        'orderDateKey': orderDateKey,
        'openedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'openedByName': user.displayName ?? 'Admin',
        'waiterName': user.displayName ?? 'Admin',
        'openedByUserId': user.uid,
        'orderIds': [orderRef.id],
        'linkedOrderIds': [orderRef.id],
      });
      transaction.set(
        tableRef,
        {
          'number': table.number,
          'name': table.name,
          'status': TableStatus.open.value,
          'currentSessionId': sessionRef.id,
          'currentTotal': 0,
          'openedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      transaction.set(orderRef, {
        ...OrderModel(
          id: orderRef.id,
          userId: user.uid,
          items: const [],
          subtotal: 0,
          deliveryFee: 0,
          total: 0,
          status: OrderStatus.preparing,
          deliveryType: DeliveryType.dineIn,
          paymentMethod: PaymentMethod.notSelected,
          paymentStatus: PaymentStatus.pending,
          guestName: cleanName,
          guestPhone: cleanPhone,
          tableId: table.id,
          tableNumber: table.number,
          tableSessionId: sessionRef.id,
          dineInStatus: TableSessionStatus.open.value,
          dailyOrderNumber: dailyOrderNumber,
          orderDateKey: orderDateKey,
        ).toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final now = BrazilClock.now();
    return TableSessionModel(
      id: sessionRef.id,
      tableId: table.id,
      tableNumber: table.number,
      status: TableSessionStatus.open,
      items: const [],
      subtotal: 0,
      serviceFee: 0,
      discount: 0,
      total: 0,
      guestName: cleanName,
      guestPhone: cleanPhone,
      openedAt: now,
      updatedAt: now,
      openedByName: user.displayName ?? 'Admin',
      waiterName: user.displayName ?? 'Admin',
      openedByUserId: user.uid,
      dailyOrderNumber: dailyOrderNumber,
      orderDateKey: orderDateKey,
      orderIds: [orderRef.id],
    );
  }

  Future<void> saveTableOrder({
    required TableSessionModel session,
    required List<OrderItemModel> items,
    String? guestName,
    String? guestPhone,
    String? notes,
  }) async {
    final total = items.fold<double>(0, (value, item) {
      return value + item.subtotal;
    });
    final cleanName = _nullableText(guestName);
    final cleanPhone = _nullableText(guestPhone);
    final cleanNotes = _nullableText(notes);
    final sessionRef = _firestore
        .collection(FirestoreCollections.tableSessions)
        .doc(session.id);
    final tableRef =
        _firestore.collection(FirestoreCollections.tables).doc(session.tableId);
    final batch = _firestore.batch();
    final orderId = session.orderIds.isEmpty ? null : session.orderIds.first;

    batch.update(sessionRef, {
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': total,
      'total': total,
      'serviceFee': 0,
      'discount': 0,
      'guestName': cleanName,
      'guestPhone': cleanPhone,
      'customerNameManual': cleanName,
      'customerPhoneManual': cleanPhone,
      'notes': cleanNotes,
      'status': items.isEmpty
          ? TableSessionStatus.open.value
          : TableSessionStatus.preparing.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      tableRef,
      {
        'number': session.tableNumber,
        'name': 'Mesa ${session.tableNumber}',
        'status': items.isEmpty
            ? TableStatus.open.value
            : TableStatus.preparing.value,
        'currentSessionId': session.id,
        'currentTotal': total,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (orderId != null) {
      batch.update(
        _firestore.collection(FirestoreCollections.pedidos).doc(orderId),
        {
          'items': items.map((item) => item.toMap()).toList(),
          'subtotal': total,
          'subtotalBeforeDiscount': total,
          'subtotalAfterDiscount': total,
          'deliveryFee': 0,
          'total': total,
          'notes': cleanNotes,
          'guestName': cleanName,
          'guestPhone': cleanPhone,
          'customerNameManual': cleanName,
          'customerPhoneManual': cleanPhone,
          'deliveryType': DeliveryType.dineIn.value,
          'orderType': DeliveryType.dineIn.value,
          'fulfillmentType': DeliveryType.dineIn.value,
          'status': OrderStatus.preparing.value,
          'dineInStatus': items.isEmpty
              ? TableSessionStatus.open.value
              : TableSessionStatus.preparing.value,
          'loyaltyRewardApplied': false,
          'loyaltyPointsRedeemed': 0,
          'loyaltyDiscountAmount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }

  Future<void> closeTable({
    required TableSessionModel session,
    required PaymentMethod paymentMethod,
    double? changeFor,
  }) async {
    final batch = _firestore.batch();
    batch.update(
      _firestore.collection(FirestoreCollections.tableSessions).doc(session.id),
      {
        'status': TableSessionStatus.closed.value,
        'paymentMethod': paymentMethod.value,
        'paymentStatus': PaymentStatus.paid.value,
        'changeFor': changeFor,
        'closedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _firestore.collection(FirestoreCollections.tables).doc(session.tableId),
      {
        'number': session.tableNumber,
        'name': 'Mesa ${session.tableNumber}',
        'status': TableStatus.free.value,
        'currentSessionId': null,
        'currentTotal': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    for (final orderId in session.orderIds) {
      batch.update(
        _firestore.collection(FirestoreCollections.pedidos).doc(orderId),
        {
          'status': OrderStatus.delivered.value,
          'paymentMethod': paymentMethod.value,
          'paymentStatus': PaymentStatus.paid.value,
          'changeFor': changeFor,
          'dineInStatus': TableSessionStatus.closed.value,
          'loyaltyRewardApplied': false,
          'loyaltyPointsRedeemed': 0,
          'loyaltyDiscountAmount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();
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

  Future<TableSessionModel?> _fetchOpenTableSession(String tableId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.tableSessions)
        .where('tableId', isEqualTo: tableId)
        .get();
    final sessions = snapshot.docs
        .map((doc) => TableSessionModel.fromFirestore(doc.id, doc.data()))
        .where(
          (session) =>
              session.status == TableSessionStatus.open ||
              session.status == TableSessionStatus.preparing ||
              session.status == TableSessionStatus.waitingPayment,
        )
        .toList();
    sessions.sort((a, b) {
      final aDate = a.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return sessions.isEmpty ? null : sessions.first;
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
    return _firestore.collection('configuracoes').doc('store').set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

String? _nullableText(String? value) {
  final clean = value?.trim();
  return clean == null || clean.isEmpty ? null : clean;
}

final adminFirestoreProvider = Provider<AdminFirestoreService>((ref) {
  return AdminFirestoreService();
});

int calculateLoyaltyPointsFromProducts(OrderModel order) {
  final productValue = order.loyaltyRewardApplied
      ? order.subtotalAfterDiscount
      : (order.subtotal > 0
          ? order.subtotal
          : order.items.fold<double>(
              0,
              (totalValue, item) => totalValue + item.subtotal,
            ));
  final points = productValue.floor();
  return points > 0 ? points : 0;
}
