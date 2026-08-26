class Sale {
  final String id;
  final String productId;
  final int qty;
  final double total;
  final DateTime date;

  Sale({required this.id, required this.productId, required this.qty, required this.total, required this.date});

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        productId: json['productId'] as String,
        qty: (json['qty'] as num).toInt(),
        total: (json['total'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'qty': qty,
        'total': total,
        'date': date.toIso8601String(),
      };
}
