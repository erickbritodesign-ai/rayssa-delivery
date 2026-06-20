import 'package:intl/intl.dart';
import 'package:rayssa_core/rayssa_core.dart';

class OrderReceiptFormatter {
  const OrderReceiptFormatter._();

  static const int _receiptWidth = 24;

  static String format(
    OrderModel order, {
    String? customerName,
    String? customerPhone,
  }) {
    final currency = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    final date = order.createdAt?.toLocal();
    final orderNumber = _numericOrderCode(order.id);
    final receiptCustomerName = _firstNotEmpty(
      order.guestName,
      customerName,
    );
    final receiptCustomerPhone = _firstNotEmpty(
      order.guestPhone,
      customerPhone,
    );
    final lines = <String>[
      '## LANCHONETE DA RAY',
      _separator(),
      'PEDIDO #$orderNumber',
      'Data: ${date == null ? 'N/I' : DateFormat('dd/MM/yyyy').format(date)}',
      'Hora: ${date == null ? 'N/I' : DateFormat('HH:mm').format(date)}',
      'Tipo: ${_deliveryTypeLabel(order.deliveryType)}',
      _separator(),
      'Cliente: ${_valueOrFallback(receiptCustomerName)}',
      'Fone: ${_valueOrFallback(receiptCustomerPhone)}',
    ];

    if (order.deliveryType == DeliveryType.delivery) {
      lines
        ..add(_separator())
        ..add('ENDERECO')
        ..addAll(_addressLines(order.address));
    } else if (order.deliveryType == DeliveryType.dineIn) {
      lines.add('Mesa: ${order.tableNumber ?? 'N/I'}');
    }

    lines
      ..add(_separator())
      ..add('ITENS');

    if (order.items.isEmpty) {
      lines.add('Nenhum item.');
    } else {
      for (final item in order.items) {
        lines
          ..add('${item.quantity}x ${item.name}')
          ..add(currency.format(item.subtotal));

        final notes = item.notes?.trim();
        if (notes != null && notes.isNotEmpty) {
          lines.add('Obs: $notes');
        }
      }
    }

    final subtotal = order.subtotalBeforeDiscount > 0
        ? order.subtotalBeforeDiscount
        : order.subtotal;

    lines
      ..add(_separator())
      ..add('Subtotal: ${currency.format(subtotal)}');

    if (order.deliveryFee > 0) {
      lines.add('Entrega: ${currency.format(order.deliveryFee)}');
    }
    if (order.loyaltyDiscountAmount > 0) {
      lines.add('Desc: ${currency.format(order.loyaltyDiscountAmount)}');
    }

    lines
      ..add('TOTAL: ${currency.format(order.total)}')
      ..add(_separator())
      ..add('## Pgto: ${_paymentMethodLabel(order.paymentMethod)}');

    if (order.changeFor != null && order.changeFor! > 0) {
      lines.add('Troco: ${currency.format(order.changeFor)}');
    }

    final orderNotes = order.notes?.trim();
    if (orderNotes != null && orderNotes.isNotEmpty) {
      lines
        ..add(_separator())
        ..add('OBSERVACOES')
        ..add(orderNotes);
    }

    lines
      ..add(_separator())
      ..add('Obrigado!');

    return _ensureReceiptWidth(lines);
  }

  static String shortOrderCode(String id) => _numericOrderCode(id);

  static String _numericOrderCode(String rawId) {
    final source = rawId.trim();
    if (source.isEmpty) return '000000';

    var hash = 0;
    for (final codeUnit in source.codeUnits) {
      hash = (hash * 31 + codeUnit) % 1000000;
    }

    final normalized = hash.abs() % 1000000;
    return normalized.toString().padLeft(6, '0');
  }

  static String _separator() => '-' * _receiptWidth;

  static String _ensureReceiptWidth(List<String> sourceLines) {
    final safeLines = <String>[];
    for (final sourceLine in sourceLines) {
      for (final line in sourceLine.split('\n')) {
        safeLines.addAll(_wrapLine(line));
      }
    }
    return safeLines.join('\n').trimRight();
  }

  static List<String> _wrapLine(
    String text, {
    int width = _receiptWidth,
  }) {
    final clean = _safeText(text).trim();
    if (clean.isEmpty) return const [''];
    final words = clean.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';

    for (final word in words) {
      if (word.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        for (var index = 0; index < word.length; index += width) {
          final end = index + width < word.length ? index + width : word.length;
          lines.add(word.substring(index, end));
        }
        continue;
      }

      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length <= width) {
        current = candidate;
      } else {
        if (current.isNotEmpty) lines.add(current);
        current = word;
      }
    }

    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  static String _valueOrFallback(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'N/I' : trimmed;
  }

  static String? _firstNotEmpty(String? primary, String? fallback) {
    final primaryValue = primary?.trim();
    if (primaryValue != null && primaryValue.isNotEmpty) return primaryValue;
    final fallbackValue = fallback?.trim();
    return fallbackValue == null || fallbackValue.isEmpty
        ? null
        : fallbackValue;
  }

  static List<String> _addressLines(AddressModel? address) {
    if (address == null) return const ['N/I'];

    return [
      '${address.street}, ${address.number}',
      address.neighborhood,
      '${address.city}/${address.state}',
      if (address.zipCode.trim().isNotEmpty) 'CEP: ${address.zipCode}',
      if ((address.complement ?? '').trim().isNotEmpty)
        'Comp: ${address.complement!.trim()}',
      if ((address.reference ?? '').trim().isNotEmpty)
        'Ref: ${address.reference!.trim()}',
    ].where((value) => value.trim().isNotEmpty).toList();
  }

  static String _safeText(String value) {
    final withoutAccents = value
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éêèë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óôõòö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp('[ÁÀÂÃÄ]'), 'A')
        .replaceAll(RegExp('[ÉÊÈË]'), 'E')
        .replaceAll(RegExp('[ÍÌÎÏ]'), 'I')
        .replaceAll(RegExp('[ÓÔÕÒÖ]'), 'O')
        .replaceAll(RegExp('[ÚÙÛÜ]'), 'U')
        .replaceAll('Ç', 'C');

    return String.fromCharCodes(
      withoutAccents.codeUnits.where((codeUnit) {
        return codeUnit == 10 || (codeUnit >= 32 && codeUnit <= 126);
      }),
    );
  }

  static String _deliveryTypeLabel(DeliveryType type) {
    return switch (type) {
      DeliveryType.delivery => 'Delivery',
      DeliveryType.pickup => 'Retirada',
      DeliveryType.dineIn => 'Mesa',
    };
  }

  static String _paymentMethodLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.notSelected => 'A definir',
      PaymentMethod.cash => 'Dinheiro',
      PaymentMethod.creditCard => 'Credito',
      PaymentMethod.debitCard => 'Debito',
      PaymentMethod.pixApp => 'Pix app',
      PaymentMethod.pixOnDelivery => 'Pix entrega',
      PaymentMethod.pix => 'Pix',
    };
  }
}
