import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/pos_provider.dart';

class InventoryPanel extends StatefulWidget {
  const InventoryPanel({super.key});

  @override
  State<InventoryPanel> createState() => _InventoryPanelState();
}

class _InventoryPanelState extends State<InventoryPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filteredProducts(List<Product> products) {
    final query = _searchController.text.trim().toLowerCase();
    return products.where((product) {
      final matchesQuery = query.isEmpty ||
          product.displayName.toLowerCase().contains(query) ||
          product.barcode.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList(growable: false);
  }

  Future<void> _showProductDialog({Product? product}) async {
    final initialId = product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final nameController = TextEditingController(text: product?.name ?? '');
    final arabicNameController = TextEditingController(text: product?.nameAr ?? '');
    final categoryController = TextEditingController(text: product?.category ?? 'Accessories');
    final priceController = TextEditingController(text: product != null ? product.price.toStringAsFixed(2) : '0.00');
    final barcodeController = TextEditingController(text: product?.barcode ?? '');
    final stockController = TextEditingController(text: (product?.stock ?? 0).toString());

    final formKey = GlobalKey<FormState>();
    final pos = context.read<PosProvider>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product == null ? 'إضافة منتج جديد' : 'تعديل المنتج'),
        content: SizedBox(
          width: 540,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم المنتج'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: arabicNameController,
                    decoration: const InputDecoration(labelText: 'اسم المنتج بالعربية (اختياري)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'القسم'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'القسم مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'السعر'),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            return parsed == null ? 'السعر غير صالح' : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'الكمية'),
                          validator: (value) {
                            final parsed = int.tryParse(value ?? '');
                            return parsed == null ? 'الكمية غير صالحة' : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: barcodeController,
                    decoration: const InputDecoration(labelText: 'الباركود'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'الباركود مطلوب' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newProduct = Product(
                id: initialId,
                name: nameController.text.trim(),
                nameAr: arabicNameController.text.trim().isEmpty ? null : arabicNameController.text.trim(),
                category: categoryController.text.trim(),
                price: double.parse(priceController.text),
                barcode: barcodeController.text.trim(),
                stock: int.parse(stockController.text),
              );
              try {
                if (product == null) {
                  await pos.addProduct(newProduct);
                } else {
                  await pos.updateProduct(newProduct);
                }
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('فشل حفظ المنتج: $e')),
                  );
                }
              }
            },
            child: Text(product == null ? 'حفظ المنتج' : 'تحديث المنتج'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(product == null ? 'تمت إضافة المنتج بنجاح' : 'تم تحديث المنتج بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final categories = pos.categories;
    final products = _filteredProducts(pos.products);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, color: Colors.teal),
                  const SizedBox(width: 10),
                  Text('إدارة المخزون', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showProductDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('منتج جديد'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'بحث عن منتج أو باركود أو قسم',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    items: categories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('لا توجد منتجات تطابق البحث', style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final product = products[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.qr_code_2_rounded, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('${product.category} • ${product.barcode}', style: TextStyle(color: Colors.grey.shade700)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text('السعر', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${product.price.toStringAsFixed(2)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text('الكمية', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${product.stock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      tooltip: 'تعديل',
                                      onPressed: () => _showProductDialog(product: product),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'نقص 1',
                                      onPressed: () => pos.adjustStock(product.id, -1),
                                      icon: const Icon(Icons.remove_circle_outline),
                                    ),
                                    IconButton(
                                      tooltip: 'زيادة 1',
                                      onPressed: () => pos.adjustStock(product.id, 1),
                                      icon: const Icon(Icons.add_circle_outline),
                                    ),
                                    IconButton(
                                      tooltip: 'حذف',
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('تأكيد الحذف'),
                                            content: Text('هل تريد حذف المنتج "${product.displayName}"؟'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                                              FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('حذف')),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await pos.deleteProduct(product.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('تم حذف المنتج ${product.displayName}')),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
