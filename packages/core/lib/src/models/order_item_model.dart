import 'package:equatable/equatable.dart';

class OrderItemModel extends Equatable {
  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.notes,
  });

  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final String? notes;

  double get subtotal => unitPrice * quantity;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: map['quantity'] as int? ?? 1,
      imageUrl: map['imageUrl'] as String?,
      notes:
          (map['notes'] ?? map['observation'] ?? map['observacao']) as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
    productId,
    name,
    unitPrice,
    quantity,
    imageUrl,
    notes,
  ];
}
