import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayssa_core/rayssa_core.dart';

class TableService {
  TableService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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

  Stream<TableSessionModel?> watchOpenSession(String tableId) {
    return _firestore
        .collection(FirestoreCollections.tableSessions)
        .where('tableId', isEqualTo: tableId)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs
          .map((doc) => TableSessionModel.fromFirestore(doc.id, doc.data()))
          .where((session) => _isOpenSession(session.status))
          .toList();

      sessions.sort((a, b) {
        final aDate = a.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return sessions.isEmpty ? null : sessions.first;
    });
  }

  Future<String> addItemsToTable({
    required TableModel table,
    required List<CartItemModel> cartItems,
    required String openedByUserId,
    required String openedByName,
    String? notes,
  }) async {
    if (cartItems.isEmpty) {
      throw StateError('Nenhum item selecionado para a mesa.');
    }

    final session = await _fetchOpenSession(table.id);
    final orderItems = cartItems
        .map(
          (item) => OrderItemModel(
            productId: item.product.id,
            name: item.product.name,
            unitPrice: item.product.price,
            quantity: item.quantity,
            imageUrl: item.product.imageUrl,
          ),
        )
        .toList();
    final subtotal = orderItems.fold<double>(
      0,
      (totalValue, item) => totalValue + item.subtotal,
    );

    final sessionRef = session == null
        ? _firestore.collection(FirestoreCollections.tableSessions).doc()
        : _firestore
            .collection(FirestoreCollections.tableSessions)
            .doc(session.id);
    final tableRef =
        _firestore.collection(FirestoreCollections.tables).doc(table.id);
    final orderRef = _firestore.collection(FirestoreCollections.pedidos).doc();

    final mergedItems = _mergeItems([
      if (session != null) ...session.items,
      ...orderItems,
    ]);
    final total = mergedItems.fold<double>(
      0,
      (totalValue, item) => totalValue + item.subtotal,
    );
    final orderIds = [
      if (session != null) ...session.orderIds,
      orderRef.id,
    ];
    final orderDateKey = BrazilClock.dateKey();
    final counterRef = _firestore
        .collection(FirestoreCollections.orderCounters)
        .doc(orderDateKey);

    await _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);
      final dailyOrderNumber =
          ((counterSnapshot.data()?['current'] as num?)?.toInt() ?? 0) + 1;

      transaction.set(counterRef, {
        'current': dailyOrderNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
        sessionRef,
        {
          'tableId': table.id,
          'tableNumber': table.number,
          'status': TableSessionStatus.preparing.value,
          'items': mergedItems.map((item) => item.toMap()).toList(),
          'subtotal': total,
          'serviceFee': session?.serviceFee ?? 0,
          'discount': session?.discount ?? 0,
          'total': total,
          'paymentStatus': PaymentStatus.pending.value,
          'openedAt': session?.openedAt ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'openedByName': session?.openedByName ?? openedByName,
          'waiterName': openedByName,
          'openedByUserId': session?.openedByUserId ?? openedByUserId,
          if (session == null) 'dailyOrderNumber': dailyOrderNumber,
          if (session == null) 'orderDateKey': orderDateKey,
          'orderIds': orderIds,
          'linkedOrderIds': orderIds,
        },
        SetOptions(merge: true),
      );
      transaction.set(
        tableRef,
        {
          'number': table.number,
          'name': table.name,
          'status': TableStatus.preparing.value,
          'currentSessionId': sessionRef.id,
          'currentTotal': total,
          'openedAt': session?.openedAt ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final order = OrderModel(
        id: '',
        userId: openedByUserId,
        items: orderItems,
        subtotal: subtotal,
        deliveryFee: 0,
        total: subtotal,
        status: OrderStatus.preparing,
        deliveryType: DeliveryType.dineIn,
        paymentMethod: PaymentMethod.notSelected,
        paymentStatus: PaymentStatus.pending,
        notes: notes,
        tableId: table.id,
        tableNumber: table.number,
        tableSessionId: sessionRef.id,
        dineInStatus: TableSessionStatus.preparing.value,
        dailyOrderNumber: dailyOrderNumber,
        orderDateKey: orderDateKey,
      );
      transaction.set(orderRef, {
        ...order.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return sessionRef.id;
  }

  Future<void> markPreparing(TableSessionModel session) async {
    await _updateSessionAndTableStatus(
      session: session,
      sessionStatus: TableSessionStatus.preparing,
      tableStatus: TableStatus.preparing,
    );
  }

  Future<void> markWaitingPayment(TableSessionModel session) async {
    await _updateSessionAndTableStatus(
      session: session,
      sessionStatus: TableSessionStatus.waitingPayment,
      tableStatus: TableStatus.waitingPayment,
    );
  }

  Future<void> closeSession({
    required TableSessionModel session,
    required PaymentMethod paymentMethod,
    double? changeFor,
  }) async {
    final batch = _firestore.batch();
    final sessionRef = _firestore
        .collection(FirestoreCollections.tableSessions)
        .doc(session.id);
    final tableRef =
        _firestore.collection(FirestoreCollections.tables).doc(session.tableId);

    batch.update(sessionRef, {
      'status': TableSessionStatus.closed.value,
      'paymentMethod': paymentMethod.value,
      'paymentStatus': PaymentStatus.paid.value,
      'changeFor': changeFor,
      'closedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      tableRef,
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
      final orderRef =
          _firestore.collection(FirestoreCollections.pedidos).doc(orderId);
      batch.update(orderRef, {
        'paymentMethod': paymentMethod.value,
        'paymentStatus': PaymentStatus.paid.value,
        'status': OrderStatus.delivered.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<TableSessionModel?> _fetchOpenSession(String tableId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.tableSessions)
        .where('tableId', isEqualTo: tableId)
        .get();

    final sessions = snapshot.docs
        .map((doc) => TableSessionModel.fromFirestore(doc.id, doc.data()))
        .where((session) => _isOpenSession(session.status))
        .toList();

    sessions.sort((a, b) {
      final aDate = a.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return sessions.isEmpty ? null : sessions.first;
  }

  Future<void> _updateSessionAndTableStatus({
    required TableSessionModel session,
    required TableSessionStatus sessionStatus,
    required TableStatus tableStatus,
  }) async {
    final batch = _firestore.batch();
    batch.update(
      _firestore.collection(FirestoreCollections.tableSessions).doc(session.id),
      {
        'status': sessionStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _firestore.collection(FirestoreCollections.tables).doc(session.tableId),
      {
        'number': session.tableNumber,
        'name': 'Mesa ${session.tableNumber}',
        'status': tableStatus.value,
        'currentSessionId': session.id,
        'currentTotal': session.total,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  bool _isOpenSession(TableSessionStatus status) {
    return status == TableSessionStatus.open ||
        status == TableSessionStatus.preparing ||
        status == TableSessionStatus.waitingPayment;
  }

  List<OrderItemModel> _mergeItems(List<OrderItemModel> items) {
    final byProduct = <String, OrderItemModel>{};

    for (final item in items) {
      final current = byProduct[item.productId];
      if (current == null) {
        byProduct[item.productId] = item;
        continue;
      }

      byProduct[item.productId] = OrderItemModel(
        productId: current.productId,
        name: current.name,
        unitPrice: current.unitPrice,
        quantity: current.quantity + item.quantity,
        imageUrl: current.imageUrl ?? item.imageUrl,
      );
    }

    return byProduct.values.toList();
  }
}
