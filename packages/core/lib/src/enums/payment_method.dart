enum PaymentMethod {
  pix('pix', 'PIX'),
  creditCard('credit_card', 'Cartão de crédito'),
  debitCard('debit_card', 'Cartão de débito');

  const PaymentMethod(this.value, this.label);
  final String value;
  final String label;

  static PaymentMethod fromString(String? value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.pix,
    );
  }
}
