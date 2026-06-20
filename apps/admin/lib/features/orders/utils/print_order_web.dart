// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<bool> printOrderReceipt(String receiptText) async {
  try {
    const receiptId = 'rayssa-order-receipt-print';
    const styleId = 'rayssa-order-receipt-print-style';
    html.document.getElementById(receiptId)?.remove();
    html.document.getElementById(styleId)?.remove();

    final receipt = html.PreElement()
      ..id = receiptId
      ..text = receiptText;
    final style = html.StyleElement()
      ..id = styleId
      ..text = '''
@media screen {
  #$receiptId { display: none; }
}
@media print {
  @page { margin: 4mm; }
  body > *:not(#$receiptId) { display: none !important; }
  #$receiptId {
    display: block !important;
    width: 48mm;
    max-width: 48mm;
    margin: 0;
    color: #000;
    background: #fff;
    font-family: "Courier New", Courier, monospace;
    font-size: 10px;
    line-height: 1.2;
    white-space: pre;
  }
}
''';

    html.document.head?.append(style);
    html.document.body?.append(receipt);
    html.window.print();

    await Future<void>.delayed(const Duration(milliseconds: 300));
    receipt.remove();
    style.remove();
    return true;
  } catch (_) {
    return false;
  }
}
