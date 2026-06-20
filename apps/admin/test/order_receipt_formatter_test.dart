import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rayssa_admin/features/orders/utils/order_receipt_formatter.dart';
import 'package:rayssa_core/rayssa_core.dart';

Future<void> main() async {
  await initializeDateFormatting('pt_BR');

  test('formats a delivery order receipt', () {
    final order = OrderModel(
      id: 'abcdefgh123',
      userId: 'customer-1',
      items: const [
        OrderItemModel(
          productId: 'product-1',
          name: 'X-Burger',
          unitPrice: 15,
          quantity: 2,
          notes: 'Sem cebola',
        ),
      ],
      subtotal: 30,
      deliveryFee: 5,
      total: 30,
      status: OrderStatus.preparing,
      deliveryType: DeliveryType.delivery,
      paymentMethod: PaymentMethod.debitCard,
      paymentStatus: PaymentStatus.pending,
      address: const AddressModel(
        street: 'Rua das Flores',
        number: '10',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01000-000',
        complement: 'Apto 2',
        reference: 'Portão azul',
      ),
      notes: 'Interfone não funciona',
      changeFor: 50,
      loyaltyRewardApplied: true,
      loyaltyDiscountAmount: 5,
      subtotalBeforeDiscount: 30,
      subtotalAfterDiscount: 25,
      createdAt: DateTime(2026, 6, 19, 18, 30),
    );

    final receipt = OrderReceiptFormatter.format(
      order,
      customerName: 'Maria',
      customerPhone: '(11) 99999-9999',
    );

    expect(receipt, contains('LANCHONETE DA RAY'));
    expect(receipt, isNot(contains('PEDIDO #ABCDEFGH')));
    expect(receipt, isNot(contains('SHJJHLMB')));
    expect(
      RegExp(r'PEDIDO #\d{6}(?:\n|$)').hasMatch(receipt),
      isTrue,
    );
    final orderLine =
        receipt.split('\n').firstWhere((line) => line.startsWith('PEDIDO #'));
    expect(orderLine, isNot(contains('-')));
    expect(orderLine.substring('PEDIDO #'.length), matches(RegExp(r'^\d{6}$')));
    expect(receipt, contains('Cliente: Maria'));
    expect(receipt, contains('2x X-Burger'));
    expect(receipt, contains('Obs: Sem cebola'));
    expect(receipt, contains('Desc:'));
    expect(receipt, contains('Troco:'));
    expect(receipt, contains('TOTAL:'));
    expect(receipt, contains('## Pgto: Debito'));
    expect(receipt, contains('Obrigado!'));
    expect(receipt, isNot(contains('Obrigado pela preferencia')));
    expect(receipt, isNot(contains('Telefone: Nao informado')));
    expect(receipt, isNot(contains('Pagamento: Cartao de debito')));

    for (final line in receipt.split('\n')) {
      expect(
        line.length,
        lessThanOrEqualTo(24),
        reason: 'Linha excedeu 24 caracteres: "$line"',
      );
      if (RegExp(r'^-+$').hasMatch(line)) {
        expect(line.length, 24);
      }
    }
  });

  test('uses manual table customer data and keeps every line within 24 chars',
      () {
    final order = OrderModel(
      id: 'pedido-mesa-firestore-id',
      userId: 'admin-1',
      items: const [
        OrderItemModel(
          productId: 'product-1',
          name: 'Bolo Fatia Chocolate',
          unitPrice: 18,
          quantity: 2,
          notes: 'Sem cobertura extra',
        ),
        OrderItemModel(
          productId: 'product-2',
          name: 'Bombom Aberto',
          unitPrice: 13,
          quantity: 1,
        ),
      ],
      subtotal: 49,
      deliveryFee: 0,
      total: 49,
      status: OrderStatus.preparing,
      deliveryType: DeliveryType.dineIn,
      paymentMethod: PaymentMethod.debitCard,
      paymentStatus: PaymentStatus.pending,
      guestName: 'João',
      guestPhone: '(11) 98888-7777',
      tableNumber: 1,
      notes: 'Trazer guardanapos',
      dailyOrderNumber: 1,
      orderDateKey: '20260620',
      createdAt: DateTime.utc(2026, 6, 20, 21, 48),
    );

    final receipt = OrderReceiptFormatter.format(
      order,
      customerName: 'Nome cadastrado',
      customerPhone: 'Telefone cadastrado',
    );

    expect(receipt, contains('PEDIDO #'));
    expect(receipt, contains('PEDIDO #000001'));
    expect(receipt, contains('Data: 20/06/2026'));
    expect(receipt, contains('Hora: 18:48'));
    expect(receipt, contains('Cliente: Joao'));
    expect(receipt, contains('Mesa: 1'));
    expect(receipt, contains('2x Bolo Fatia'));
    expect(receipt, contains('TOTAL:'));
    expect(receipt, isNot(contains('Nome cadastrado')));

    for (final line in receipt.split('\n')) {
      expect(
        line.length,
        lessThanOrEqualTo(24),
        reason: 'Linha excedeu 24 caracteres: "$line"',
      );
    }
  });

  test('pads daily order number 23 to six digits', () {
    final order = OrderModel(
      id: 'ignored-when-daily-number-exists',
      userId: 'customer-1',
      items: const [],
      subtotal: 0,
      deliveryFee: 0,
      total: 0,
      status: OrderStatus.received,
      deliveryType: DeliveryType.pickup,
      paymentMethod: PaymentMethod.pix,
      paymentStatus: PaymentStatus.pending,
      dailyOrderNumber: 23,
      orderDateKey: '20260620',
      createdAt: DateTime.utc(2026, 6, 20, 12),
    );

    final receipt = OrderReceiptFormatter.format(order);

    expect(receipt, contains('PEDIDO #000023'));
  });
}
