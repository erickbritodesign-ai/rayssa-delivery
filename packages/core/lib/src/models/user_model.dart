import 'package:equatable/equatable.dart';
import 'package:rayssa_core/src/enums/user_role.dart';
import 'package:rayssa_core/src/models/address_model.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.addresses = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final List<AddressModel> addresses;
  final DateTime? createdAt;

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    final addressesRaw = data['addresses'] as List<dynamic>? ?? [];
    return UserModel(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      addresses: addressesRaw
          .map((item) => AddressModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      createdAt: _timestampToDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, name, email, phone, role, addresses, createdAt];
}

DateTime? _timestampToDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return value.toDate() as DateTime;
}
