import 'package:intl/intl.dart';

String formatCurrency(double amount, {String symbol = 'RD\$'}) {
  final formatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: symbol,
    decimalDigits: 2,
  );
  return formatter.format(amount);
}
