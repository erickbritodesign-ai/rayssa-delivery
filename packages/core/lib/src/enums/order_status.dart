enum OrderStatus {
  received('received', 'Recebido'),
  confirmed('confirmed', 'Confirmado'),
  preparing('preparing', 'Em preparo'),
  outForDelivery('out_for_delivery', 'Saiu para entrega'),
  delivered('delivered', 'Entregue'),
  cancelled('cancelled', 'Cancelado');

  const OrderStatus(this.value, this.label);
  final String value;
  final String label;

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.received,
    );
  }
}
