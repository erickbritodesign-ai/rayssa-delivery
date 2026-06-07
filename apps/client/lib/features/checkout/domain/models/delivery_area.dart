class DeliveryArea {
  const DeliveryArea({
    required this.id,
    required this.name,
    this.deliveryFee,
  });

  final String id;
  final String name;

  // TODO: permitir que o Admin defina a taxa por bairro via Firestore.
  final double? deliveryFee;
}

const pedroCanarioDeliveryAreas = [
  DeliveryArea(id: 'centro', name: 'Centro'),
  DeliveryArea(id: 'leonorio_i_ii', name: 'Leonório I e II'),
  DeliveryArea(id: 'camata', name: 'Camata'),
  DeliveryArea(id: 'boa_vista', name: 'Boa Vista'),
  DeliveryArea(id: 'santa_rita', name: 'Santa Rita'),
  DeliveryArea(id: 'canarinho', name: 'Canarinho'),
  DeliveryArea(id: 'colina', name: 'Colina'),
  DeliveryArea(id: 'alvorada', name: 'Alvorada'),
  DeliveryArea(id: 'vista_alegre', name: 'Vista Alegre'),
  DeliveryArea(id: 'sao_geraldo', name: 'São Geraldo'),
  DeliveryArea(id: 'esplanada', name: 'Esplanada'),
  DeliveryArea(id: 'eldorado', name: 'Eldorado'),
  DeliveryArea(id: 'novo_horizonte', name: 'Novo Horizonte'),
  DeliveryArea(id: 'lagoa_dourada', name: 'Lagoa Dourada'),
];
