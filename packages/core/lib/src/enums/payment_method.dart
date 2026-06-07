enum PaymentMethod {
  pix('pix', 'PIX'),
  cash('cash', 'Dinheiro na entrega'),
  creditCard('credit_card', 'Cartão de crédito na entrega'),
  debitCard('debit_card', 'Cartão de débito na entrega'),
  pixOnDelivery('pix_on_delivery', 'Pix na entrega'),
  pixApp('pix_app', 'Pix pelo aplicativo');

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
