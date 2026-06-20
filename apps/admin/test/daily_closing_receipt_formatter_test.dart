import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rayssa_admin/features/reports/utils/daily_closing_receipt_formatter.dart';

Future<void> main() async {
  await initializeDateFormatting('pt_BR');

  test('formats POS-58 daily closing within 24 characters', () {
    const data = DailyClosingReceiptData(
      periodLabel: '20/06/2026',
      total: 350,
      orders: 22,
      averageTicket: 15.90,
      delivery: 120,
      pickup: 80,
      dineIn: 150,
      cash: 50,
      pix: 100,
      debit: 150,
      credit: 50,
      other: 0,
      cancelled: 1,
      deliveryFees: 20,
    );

    final receipt = DailyClosingReceiptFormatter.format(data);

    expect(receipt, contains('TOTAL'));
    expect(receipt, contains('PAGAMENTOS'));
    expect(receipt, contains('Delivery'));
    expect(receipt, contains('Retirada'));
    expect(receipt, contains('Mesa'));
    expect(receipt, contains('Cancelados'));

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
}
