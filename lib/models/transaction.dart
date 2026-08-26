import 'sale.dart';

class TransactionSummary {
  final String saleGroup;
  final DateTime date;
  final double total;
  final List<Sale> items;

  TransactionSummary({required this.saleGroup, required this.date, required this.total, required this.items});
}
