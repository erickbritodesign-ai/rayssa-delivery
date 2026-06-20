import 'package:equatable/equatable.dart';

class DeliveryZoneModel extends Equatable {
  const DeliveryZoneModel({
    required this.id,
    required this.name,
    required this.fee,
    this.isActive = true,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final double fee;
  final bool isActive;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DeliveryZoneModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return DeliveryZoneModel(
      id: id,
      name: data['name'] as String? ?? '',
      fee: (data['fee'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      order: (data['order'] as num?)?.toInt() ?? 0,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'fee': fee,
    'isActive': isActive,
    'order': order,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    fee,
    isActive,
    order,
    createdAt,
    updatedAt,
  ];
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return value.toDate() as DateTime;
}
