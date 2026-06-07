import 'package:equatable/equatable.dart';
import 'package:rayssa_core/src/enums/delivery_type.dart';
import 'package:rayssa_core/src/enums/order_status.dart';
import 'package:rayssa_core/src/enums/payment_method.dart';
import 'package:rayssa_core/src/enums/payment_status.dart';
import 'package:rayssa_core/src/models/address_model.dart';
import 'package:rayssa_core/src/models/order_item_model.dart';

class OrderModel extends Equatable {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.deliveryType,
    required this.paymentMethod,
    required this.paymentStatus,
    this.address,
    this.notes,
    this.changeFor,
    this.tableId,
    this.tableNumber,
    this.tableSessionId,
    this.dineInStatus,
    this.mercadoPagoPaymentId,
    this.loyaltyPointsAwarded = false,
    this.loyaltyPoints = 0,
    this.loyaltyAwardedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final AddressModel? address;
  final String? notes;
  final double? changeFor;
  final String? tableId;
  final int? tableNumber;
  final String? tableSessionId;
  final String? dineInStatus;
  final String? mercadoPagoPaymentId;
  final bool loyaltyPointsAwarded;
  final int loyaltyPoints;
  final DateTime? loyaltyAwardedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final addressRaw = data['address'] as Map<String, dynamic>?;
    return OrderModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      items: itemsRaw
          .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromString(data['status'] as String?),
      deliveryType: DeliveryType.fromString(
        (data['orderType'] ?? data['fulfillmentType'] ?? data['deliveryType'])
            as String?,
      ),
      paymentMethod: PaymentMethod.fromString(data['paymentMethod'] as String?),
      paymentStatus: PaymentStatus.fromString(data['paymentStatus'] as String?),
      address: addressRaw != null ? AddressModel.fromMap(addressRaw) : null,
      notes: data['notes'] as String?,
      changeFor: (data['changeFor'] as num?)?.toDouble(),
      tableId: data['tableId'] as String?,
      tableNumber: (data['tableNumber'] as num?)?.toInt(),
      tableSessionId: data['tableSessionId'] as String?,
      dineInStatus: data['dineInStatus'] as String?,
      mercadoPagoPaymentId: data['mercadoPagoPaymentId'] as String?,
      loyaltyPointsAwarded: data['loyaltyPointsAwarded'] == true,
      loyaltyPoints: (data['loyaltyPoints'] as num?)?.toInt() ?? 0,
      loyaltyAwardedAt: _timestampToDate(data['loyaltyAwardedAt']),
      createdAt: _timestampToDate(data['createdAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'status': status.value,
      'deliveryType': deliveryType.value,
      'orderType': deliveryType.value,
      'fulfillmentType': deliveryType.value,
      'paymentMethod': paymentMethod.value,
      'paymentStatus': paymentStatus.value,
      'address': address?.toMap(),
      'notes': notes,
      'changeFor': changeFor,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'tableSessionId': tableSessionId,
      'dineInStatus': dineInStatus,
      'mercadoPagoPaymentId': mercadoPagoPaymentId,
      'loyaltyPointsAwarded': loyaltyPointsAwarded,
      'loyaltyPoints': loyaltyPoints,
      'loyaltyAwardedAt': loyaltyAwardedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    items,
    subtotal,
    deliveryFee,
    total,
    status,
    deliveryType,
    paymentMethod,
    paymentStatus,
    address,
    notes,
    changeFor,
    tableId,
    tableNumber,
    tableSessionId,
    dineInStatus,
    mercadoPagoPaymentId,
    loyaltyPointsAwarded,
    loyaltyPoints,
    loyaltyAwardedAt,
    createdAt,
    updatedAt,
  ];
}

DateTime? _timestampToDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return value.toDate() as DateTime;
}
