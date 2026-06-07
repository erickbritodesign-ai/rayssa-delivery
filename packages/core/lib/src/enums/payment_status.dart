enum PaymentStatus {
  pending('pending', 'Pendente'),
  paid('paid', 'Pago'),
  approved('approved', 'Aprovado'),
  rejected('rejected', 'Recusado'),
  cancelled('cancelled', 'Cancelado');

  const PaymentStatus(this.value, this.label);
  final String value;
  final String label;

  static PaymentStatus fromString(String? value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}
