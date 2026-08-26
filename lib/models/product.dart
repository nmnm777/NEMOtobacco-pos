class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String barcode;

  Product({required this.id, required this.name, required this.category, required this.price, required this.barcode});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        barcode: json['barcode'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'barcode': barcode,
      };
}
