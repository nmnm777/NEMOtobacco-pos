import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../providers/pos_provider.dart';

/// Simple PDF invoice generator. Returns PDF bytes for a TransactionSummary.
Future<Uint8List> generateInvoicePdf(TransactionSummary tx, PosProvider pos) async {
  final doc = pw.Document();

  // try load Arabic font from assets; try Cairo then Amiri; fallback to default
  pw.Font? arabicFont;
  try {
    ByteData? fontData;
    try {
      fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    } catch (_) {
      // ignore
    }
    if (fontData == null) {
      try {
        fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      } catch (_) {
        // ignore
      }
    }
    if (fontData != null) arabicFont = pw.Font.ttf(fontData);
  } catch (e) {
    // font not available; arabic may not render properly
    arabicFont = null;
  }

  final baseStyle = arabicFont != null ? pw.TextStyle(font: arabicFont, fontSize: 12) : pw.TextStyle(fontSize: 12);
  final boldStyle = arabicFont != null ? pw.TextStyle(font: arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold) : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

  final header = pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Tobacco POS', style: pw.TextStyle(font: arabicFont, fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('فاتورة رقم: ${tx.saleGroup}', style: baseStyle),
        ],
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('Date: ${tx.date.toLocal().toString()}', style: baseStyle),
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
        headerStyle: boldStyle,
        cellStyle: baseStyle,
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
              pw.Text('الإجمالي: \$${tx.total.toStringAsFixed(2)}', style: pw.TextStyle(font: arabicFont, fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 24),
      pw.Text('شكراً لتسوقكم!', style: baseStyle, textAlign: pw.TextAlign.center),
    ],
  ));

  return doc.save();
}

/// Save generated PDF to the user's Downloads folder (or documents if downloads not available).
Future<String> saveInvoicePdfToDownloads(TransactionSummary tx, PosProvider pos) async {
  final bytes = await generateInvoicePdf(tx, pos);
  Directory? downloadsDir;
  try {
    downloadsDir = await getDownloadsDirectory(); // may return null on some platforms
  } catch (e) {
    downloadsDir = null;
  }

  Directory baseDir;
  if (downloadsDir != null) {
    baseDir = downloadsDir;
  } else {
    baseDir = await getApplicationDocumentsDirectory();
  }

  final filename = 'invoice_${tx.saleGroup}.pdf';
  final filePath = p.join(baseDir.path, filename);
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return filePath;
}
