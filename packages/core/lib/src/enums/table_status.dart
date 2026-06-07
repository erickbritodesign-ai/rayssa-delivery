enum TableStatus {
  free('free', 'Livre'),
  open('open', 'Aberta'),
  preparing('preparing', 'Em preparo'),
  waitingPayment('waitingPayment', 'Aguardando pagamento');

  const TableStatus(this.value, this.label);
  final String value;
  final String label;

  static TableStatus fromString(String? value) {
    return TableStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TableStatus.free,
    );
  }
}
