import 'print_order_stub.dart' if (dart.library.html) 'print_order_web.dart'
    as implementation;

Future<bool> printOrderReceipt(String receiptText) {
  return implementation.printOrderReceipt(receiptText);
}
