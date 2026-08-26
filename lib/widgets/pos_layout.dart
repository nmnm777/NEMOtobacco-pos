import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class PosLayout extends StatelessWidget {
  final List<Product> products;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final void Function(Product, {int qty}) addToCart;
  final Map<String, CartItem> cart;
  final void Function(String, int) changeQty;
  final void Function(String) removeFromCart;
  final double Function() totalPriceGetter;
  final TextEditingController barcodeController;
  final void Function(String) processBarcode;
  final VoidCallback onCheckout;

  const PosLayout({
    super.key,
    required this.products,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.addToCart,
    required this.cart,
    required this.changeQty,
    required this.removeFromCart,
    required this.totalPriceGetter,
    required this.barcodeController,
    required this.processBarcode,
    required this.onCheckout,
  });

  List<String> get categories {
    return [
      'All',
      'Cigarettes',
      'Shisha / Molasses',
      'Vapes',
      'Accessories',
    ];
  }

  List<Product> filteredProducts() {
    if (selectedCategory == 'All') return products;
    return products.where((p) => p.category == selectedCategory).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final items = cart.values.toList();

    Widget productArea = Column(
      children: [
        // category chips
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final selected = cat == selectedCategory;
              return ChoiceChip(
                label: Text(cat, textDirection: TextDirection.ltr),
                selected: selected,
                onSelected: (_) => onCategoryChanged(cat),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCountForWidth(width),
                childAspectRatio: 4 / 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredProducts().length,
              itemBuilder: (context, idx) {
                final p = filteredProducts()[idx];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: InkWell(
                    onTap: () => addToCart(p),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(child: Icon(_iconForCategory(p.category), size: 36, color: Colors.grey.shade700)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('\$${p.price.toStringAsFixed(2)}'),
                              ElevatedButton(
                                onPressed: () => addToCart(p),
                                child: const Text('إضافة'),
                                style: ElevatedButton.styleFrom(minimumSize: const Size(64, 32), padding: EdgeInsets.zero),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );

    Widget cartSidebar = Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text('السلة الحالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shopping_cart_outlined, size: 48),
                          SizedBox(height: 8),
                          Text('لا توجد عناصر في السلة'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, idx) {
                        final ci = items[idx];
                        return ListTile(
                          tileColor: Theme.of(context).colorScheme.surfaceVariant,
                          hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text('${ci.qty}x')),
                          title: Text(ci.product.displayName, textDirection: TextDirection.ltr),
                          subtitle: Text('\$${ci.product.price.toStringAsFixed(2)} لكل وحدة'),
                          trailing: SizedBox(
                            width: 112,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => changeQty(ci.product.id, -1)),
                                Text('${ci.qty}', style: const TextStyle(fontSize: 16)),
                                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => changeQty(ci.product.id, 1)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Text('الإجمالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('\$${totalPriceGetter().toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('تفريغ'),
                    onPressed: cart.isEmpty ? null : () => cart.clear(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(icon: const Icon(Icons.payment), label: const Text('الدفع'), onPressed: cart.isEmpty ? null : onCheckout),
                ),
              ],
            )
          ],
        ),
      ),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(flex: 3, child: productArea),
          const SizedBox(width: 12),
          SizedBox(width: 360, child: cartSidebar),
        ],
      );
    } else {
      return Column(
        children: [
          // barcode input row for narrow view
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6),
            child: TextField(
              controller: barcodeController,
              decoration: InputDecoration(
                hintText: 'مسح/ادخال الباركود واضغط Enter',
                prefixIcon: const Icon(Icons.qr_code_2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                processBarcode(v);
              },
            ),
          ),
          Expanded(child: productArea),
          const Divider(height: 1),
          SizedBox(height: 360, child: cartSidebar),
        ],
      );
    }
  }

  int _crossAxisCountForWidth(double width) {
    if (width >= 1200) return 5;
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Cigarettes':
        return Icons.smoking_rooms;
      case 'Shisha / Molasses':
        return Icons.fireplace;
      case 'Vapes':
        return Icons.electrical_services;
      case 'Accessories':
        return Icons.extension;
      default:
        return Icons.local_offer;
    }
  }
}
