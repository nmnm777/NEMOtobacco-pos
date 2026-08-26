import 'product.dart';

class CartItem {
  final Product product;
  int qty;
  CartItem({required this.product, this.qty = 1});

  double get total => product.price * qty;
}
