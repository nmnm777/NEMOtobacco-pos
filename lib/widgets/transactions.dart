import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/transaction.dart';
import 'transaction_detail.dart';
import '../services/pdf_service.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final transactions = pos.getTransactions();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('الفواتير / المعاملات', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('لا توجد فواتير حالياً', style: TextStyle(color: Colors.grey.shade700)),
              ),
            )
          else
            ...transactions.map((t) => _buildTransactionCard(context, t)).toList(),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionSummary t) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: Row(
          children: [
            Text('فاتورة: ${t.saleGroup}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('\$${t.total.toStringAsFixed(2)}'),
          ],
        ),
        subtitle: Text('${t.date.toLocal()}'),
        children: [
          ...t.items.map((s) => ListTile(
                          tileColor: Theme.of(context).colorScheme.surfaceVariant,
                          hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                          title: Text('منتج: ${s.productId}', textDirection: TextDirection.ltr),
                          trailing: Text('x${s.qty}'),
                          subtitle: Text('\$${s.total.toStringAsFixed(2)}'),
                        )),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // open transaction detail page
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionDetailPage(transaction: t)));
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('عرض التفاصيل'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(onPressed: () async {
                  final pos = context.read<PosProvider>();
                  try {
                    final savedPath = await saveInvoicePdfToDownloads(t, pos);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ الفاتورة: $savedPath')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التصدير: $e')));
                  }
                }, icon: const Icon(Icons.download), label: const Text('تصدير')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
