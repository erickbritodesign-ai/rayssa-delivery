enum DeliveryType {
  delivery('delivery', 'Entrega'),
  pickup('pickup', 'Retirada no local');

  const DeliveryType(this.value, this.label);
  final String value;
  final String label;

  static DeliveryType fromString(String? value) {
    return DeliveryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DeliveryType.delivery,
    );
  }
}
