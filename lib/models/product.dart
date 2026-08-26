class Product {
  final String id;
  final String name;
  final String? nameAr;
  final String category;
  final double price;
  final String barcode;
  final int stock;

  Product({required this.id, required this.name, this.nameAr, required this.category, required this.price, required this.barcode, this.stock = 0});

  /// Preferred display name (Arabic if available, otherwise default name)
  String get displayName => nameAr != null && nameAr!.trim().isNotEmpty ? nameAr! : name;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        nameAr: json['name_ar'] as String?,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        barcode: json['barcode'] as String,
        stock: (json['stock'] as int?) ?? (json['stock'] is num ? (json['stock'] as num).toInt() : 0),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_ar': nameAr,
        'category': category,
        'price': price,
        'barcode': barcode,
        'stock': stock,
      };
}
