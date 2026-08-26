import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final totalProducts = pos.totalProducts;
    final totalCategories = pos.totalCategories;
    final salesTotal = pos.salesTotal;
    final ordersCount = pos.ordersCount;
    final lowStock = pos.lowStockProducts;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('لوحة المؤشرات', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatCard('إجمالي المنتجات', totalProducts.toString(), Icons.inventory_2, Colors.blue),
              _buildStatCard('عدد الأقسام', totalCategories.toString(), Icons.category, Colors.orange),
              _buildStatCard('إجمالي المبيعات', '\$${salesTotal.toStringAsFixed(2)}', Icons.bar_chart, Colors.green),
              _buildStatCard('إجمالي الفواتير', ordersCount.toString(), Icons.receipt_long, Colors.purple),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('المنتجات منخفضة المخزون', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text('${lowStock.length} عناصر', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (lowStock.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('لا توجد منتجات منخفضة المخزون حالياً', style: TextStyle(color: Colors.grey.shade700)),
                    )
                  else
                    ...lowStock.map((p) => ListTile(
                                              tileColor: Theme.of(context).colorScheme.surfaceVariant,
                                              hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                                              title: Text(p.name, textDirection: TextDirection.ltr),
                                              trailing: Text('مخزون: ${p.stock}'),
                                            ))
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('أحدث المبيعات', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Builder(builder: (ctx) {
                    final sales = pos.sales;
                    if (sales.isEmpty) return Text('لا توجد مبيعات مسجلة', style: TextStyle(color: Colors.grey.shade700));
                    return Column(
                      children: sales.reversed.take(6).map((s) => ListTile(
                            dense: true,
                                                tileColor: Theme.of(context).colorScheme.surfaceVariant,
                                                hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                                                title: Text('منتج: ${s.productId}', textDirection: TextDirection.ltr),
                                                trailing: Text('\$${s.total.toStringAsFixed(2)}'),
                                                subtitle: Text('${s.qty} وحدة — ${s.date.toLocal()}'),
                                              )).toList(),
                                        );
                  })
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
