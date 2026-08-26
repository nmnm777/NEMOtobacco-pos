import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../models/transaction.dart';
import '../providers/pos_provider.dart';
import '../services/pdf_service.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionSummary transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final pos = context.read<PosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الفاتورة: ${transaction.saleGroup}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              // open pdf preview and allow printing
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfPreviewPage(transaction: transaction)));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('فاتورة: ', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 8),
                Text(transaction.saleGroup, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('التاريخ: ${transaction.date.toLocal()}'),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: transaction.items.map((s) {
                    final product = pos.getProductById(s.productId);
                    final name = product?.name ?? s.productId;
                    final unitPrice = s.qty != 0 ? s.total / s.qty : s.total;
                    return ListTile(
                      title: Text(name, textDirection: TextDirection.ltr),
                      subtitle: Text('السعر للوحدة: \$${unitPrice.toStringAsFixed(2)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('x${s.qty}'),
                          const SizedBox(height: 4),
                          Text('\$${s.total.toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Spacer(),
                    Text('\$${transaction.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple page that shows PdfPreview using printing package
class PdfPreviewPage extends StatelessWidget {
  final TransactionSummary transaction;
  const PdfPreviewPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final pos = context.read<PosProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة الفاتورة')),
      body: PdfPreview(
        maxPageWidth: 700,
        build: (format) async => await generateInvoicePdf(transaction, pos),
      ),
    );
  }
}
