class Product {
  final String id;
  final String name;
  final String? nameAr;
  final String category;
  final double price;
  final String barcode;
  final int stock;

  Product({
    required this.id,
    required this.name,
    this.nameAr,
    required this.category,
    required this.price,
    required this.barcode,
    this.stock = 0,
  });

  String get displayName =>
      (nameAr != null && nameAr!.trim().isNotEmpty) ? nameAr! : name;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? json['nameAr'] ?? 'غير مسمى').toString(),
        nameAr: (json['name_ar'] ?? json['nameAr'])?.toString(),
        category: (json['category'] ?? 'General').toString(),
        price: (json['price'] is num ? json['price'] as num : double.tryParse(json['price'].toString()) ?? 0.0)
            .toDouble(),
        barcode: (json['barcode'] ?? '').toString(),
        stock: (json['stock'] is num ? (json['stock'] as num).toInt() : int.tryParse(json['stock']?.toString() ?? '') ?? 0),
      );

  Product copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? category,
    double? price,
    String? barcode,
    int? stock,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        category: category ?? this.category,
        price: price ?? this.price,
        barcode: barcode ?? this.barcode,
        stock: stock ?? this.stock,
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
