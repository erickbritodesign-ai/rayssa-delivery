import 'package:intl/intl.dart';

class DailyClosingReceiptData {
  const DailyClosingReceiptData({
    required this.periodLabel,
    required this.total,
    required this.orders,
    required this.averageTicket,
    required this.delivery,
    required this.pickup,
    required this.dineIn,
    required this.cash,
    required this.pix,
    required this.debit,
    required this.credit,
    required this.other,
    required this.cancelled,
    required this.deliveryFees,
  });

  final String periodLabel;
  final double total;
  final int orders;
  final double averageTicket;
  final double delivery;
  final double pickup;
  final double dineIn;
  final double cash;
  final double pix;
  final double debit;
  final double credit;
  final double other;
  final int cancelled;
  final double deliveryFees;
}

abstract final class DailyClosingReceiptFormatter {
  static const width = 24;

  static String format(DailyClosingReceiptData data) {
    final money = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    final lines = <String>[
      '## LANCHONETE DA RAY',
      'FECHAMENTO',
      data.periodLabel,
      _separator,
      'TOTAL: ${money.format(data.total)}',
      'Pedidos: ${data.orders}',
      'Ticket: ${money.format(data.averageTicket)}',
      _separator,
      'POR TIPO',
      'Delivery: ${money.format(data.delivery)}',
      'Retirada: ${money.format(data.pickup)}',
      'Mesa: ${money.format(data.dineIn)}',
      _separator,
      'PAGAMENTOS',
      'Pix: ${money.format(data.pix)}',
      'Debito: ${money.format(data.debit)}',
      'Credito: ${money.format(data.credit)}',
      'Dinheiro: ${money.format(data.cash)}',
      'A definir: ${money.format(data.other)}',
      _separator,
      'Cancelados: ${data.cancelled}',
      'Taxas: ${money.format(data.deliveryFees)}',
      _separator,
      'Conferir com o caixa.',
    ];
    return _fit(lines);
  }

  static String get _separator => '-' * width;

  static String _fit(List<String> source) {
    final output = <String>[];
    for (final line in source) {
      output.addAll(_wrap(_safe(line)));
    }
    return output.join('\n');
  }

  static List<String> _wrap(String text) {
    final value = text.trim();
    if (value.isEmpty) return const [''];
    final words = value.split(RegExp(r'\s+'));
    final result = <String>[];
    var current = '';
    for (final word in words) {
      if (word.length > width) {
        if (current.isNotEmpty) {
          result.add(current);
          current = '';
        }
        for (var index = 0; index < word.length; index += width) {
          final end = index + width < word.length ? index + width : word.length;
          result.add(word.substring(index, end));
        }
        continue;
      }
      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length <= width) {
        current = candidate;
      } else {
        result.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) result.add(current);
    return result;
  }

  static String _safe(String value) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ç': 'c',
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ç': 'C',
    };
    var result = value;
    replacements.forEach((from, to) {
      result = result.replaceAll(from, to);
    });
    return String.fromCharCodes(
      result.codeUnits.where((code) => code >= 32 && code <= 126),
    );
  }
}
