import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/transaction.dart';
import '../providers/pos_provider.dart';

/// Simple PDF invoice generator. Returns PDF bytes for a TransactionSummary.
Future<Uint8List> generateInvoicePdf(TransactionSummary tx, PosProvider pos) async {
  final doc = pw.Document();

  final header = pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Tobacco POS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('فاتورة رقم: ${tx.saleGroup}'),
        ],
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('Date: ${tx.date.toLocal().toString()}'),
        ],
      ),
    ],
  );

  // table headers
  final tableHeaders = ['المنتج', 'الكمية', 'سعر الوحدة', 'الإجمالي'];

  // table data rows
  final List<List<String>> rows = tx.items.map((s) {
    final product = pos.getProductById(s.productId);
    final name = product?.name ?? s.productId;
    final unitPrice = s.qty != 0 ? (s.total / s.qty) : s.total;
    return [name, '${s.qty}', '\$${unitPrice.toStringAsFixed(2)}', '\$${s.total.toStringAsFixed(2)}'];
  }).toList();

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (pw.Context context) => [
      header,
      pw.SizedBox(height: 12),
      pw.Divider(),
      pw.SizedBox(height: 8),
      pw.Table.fromTextArray(
        headers: tableHeaders,
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignment: pw.Alignment.centerLeft,
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
        cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('الإجمالي: \$${tx.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 24),
      pw.Text('شكراً لتسوقكم!', textAlign: pw.TextAlign.center),
    ],
  ));

  return doc.save();
}
