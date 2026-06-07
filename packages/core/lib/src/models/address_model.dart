import 'package:equatable/equatable.dart';

class AddressModel extends Equatable {
  const AddressModel({
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.complement,
    this.reference,
    this.label = 'Casa',
    this.deliveryFee,
  });

  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final String? complement;
  final String? reference;
  final String label;
  final double? deliveryFee;

  String get formatted => '$street, $number - $neighborhood, $city/$state';

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      street: map['street'] as String? ?? '',
      number: map['number'] as String? ?? '',
      neighborhood: map['neighborhood'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zipCode: map['zipCode'] as String? ?? '',
      complement: map['complement'] as String?,
      reference: map['reference'] as String?,
      label: map['label'] as String? ?? 'Casa',
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'number': number,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'complement': complement,
      'reference': reference,
      'label': label,
      'deliveryFee': deliveryFee,
    };
  }

  @override
  List<Object?> get props => [
    street,
    number,
    neighborhood,
    city,
    state,
    zipCode,
    complement,
    reference,
    label,
    deliveryFee,
  ];
}
