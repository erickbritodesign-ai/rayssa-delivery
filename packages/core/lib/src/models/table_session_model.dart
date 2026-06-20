import 'package:equatable/equatable.dart';
import 'package:rayssa_core/src/enums/payment_method.dart';
import 'package:rayssa_core/src/enums/payment_status.dart';
import 'package:rayssa_core/src/enums/table_session_status.dart';
import 'package:rayssa_core/src/models/order_item_model.dart';

class TableSessionModel extends Equatable {
  const TableSessionModel({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.discount,
    required this.total,
    this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.changeFor,
    this.guestName,
    this.guestPhone,
    this.notes,
    this.openedAt,
    this.closedAt,
    this.updatedAt,
    this.openedByName,
    this.waiterName,
    this.openedByUserId,
    this.orderIds = const [],
  });

  final String id;
  final String tableId;
  final int tableNumber;
  final TableSessionStatus status;
  final List<OrderItemModel> items;
  final double subtotal;
  final double serviceFee;
  final double discount;
  final double total;
  final PaymentMethod? paymentMethod;
  final PaymentStatus paymentStatus;
  final double? changeFor;
  final String? guestName;
  final String? guestPhone;
  final String? notes;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final DateTime? updatedAt;
  final String? openedByName;
  final String? waiterName;
  final String? openedByUserId;
  final List<String> orderIds;

  factory TableSessionModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final orderIdsRaw = data['orderIds'] ?? data['linkedOrderIds'];

    return TableSessionModel(
      id: id,
      tableId: data['tableId'] as String? ?? '',
      tableNumber: (data['tableNumber'] as num?)?.toInt() ?? 0,
      status: TableSessionStatus.fromString(data['status'] as String?),
      items: itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(OrderItemModel.fromMap)
          .toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      serviceFee: (data['serviceFee'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod'] == null
          ? null
          : PaymentMethod.fromString(data['paymentMethod'] as String?),
      paymentStatus: PaymentStatus.fromString(data['paymentStatus'] as String?),
      changeFor: (data['changeFor'] as num?)?.toDouble(),
      guestName: (data['guestName'] ?? data['customerNameManual']) as String?,
      guestPhone:
          (data['guestPhone'] ?? data['customerPhoneManual']) as String?,
      notes: data['notes'] as String?,
      openedAt: _timestampToDate(data['openedAt']),
      closedAt: _timestampToDate(data['closedAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
      openedByName: data['openedByName'] as String?,
      waiterName: data['waiterName'] as String?,
      openedByUserId: data['openedByUserId'] as String?,
      orderIds: orderIdsRaw is List
          ? orderIdsRaw.map((id) => id.toString()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tableId': tableId,
      'tableNumber': tableNumber,
      'status': status.value,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod?.value,
      'paymentStatus': paymentStatus.value,
      'changeFor': changeFor,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'customerNameManual': guestName,
      'customerPhoneManual': guestPhone,
      'notes': notes,
      'openedAt': openedAt,
      'closedAt': closedAt,
      'updatedAt': updatedAt,
      'openedByName': openedByName,
      'waiterName': waiterName,
      'openedByUserId': openedByUserId,
      'orderIds': orderIds,
      'linkedOrderIds': orderIds,
    };
  }

  @override
  List<Object?> get props => [
    id,
    tableId,
    tableNumber,
    status,
    items,
    subtotal,
    serviceFee,
    discount,
    total,
    paymentMethod,
    paymentStatus,
    changeFor,
    guestName,
    guestPhone,
    notes,
    openedAt,
    closedAt,
    updatedAt,
    openedByName,
    waiterName,
    openedByUserId,
    orderIds,
  ];
}

DateTime? _timestampToDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return value.toDate() as DateTime;
}
