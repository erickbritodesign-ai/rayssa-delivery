enum TableSessionStatus {
  open('open', 'Aberta'),
  preparing('preparing', 'Em preparo'),
  waitingPayment('waitingPayment', 'Aguardando pagamento'),
  closed('closed', 'Fechada'),
  cancelled('cancelled', 'Cancelada');

  const TableSessionStatus(this.value, this.label);
  final String value;
  final String label;

  static TableSessionStatus fromString(String? value) {
    return TableSessionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TableSessionStatus.open,
    );
  }
}
