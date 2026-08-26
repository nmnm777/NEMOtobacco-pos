import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.read<PosProvider>();

    return Center(
      child: Card(
        elevation: 3,
        child: SizedBox(
          width: 760,
          height: 480,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings, size: 28, color: Colors.teal),
                    const SizedBox(width: 12),
                    Text('الإعدادات', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('خيارات عامة للنظام', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('إعادة تهيئة بيانات المصنع'),
                    subtitle: const Text('يحذف جميع المبيعات والمنتجات الحالية ويعيد استيراد بيانات المصنع من الملفات الافتراضية.'),
                    trailing: ElevatedButton(
                      child: const Text('إعادة التهيئة'),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تأكيد إعادة التهيئة'),
                            content: const Text('هل أنت متأكد أنك تريد إعادة تهيئة البيانات لمسح كل المبيعات والمنتجات الحالية؟ هذا الإجراء لا يمكن التراجع عنه.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('نعم، أعد التهيئة')),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            await pos.resetToDefaults();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إعادة تهيئة البيانات بنجاح')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إعادة التهيئة: $e')));
                            }
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('خطوط وPDF', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('تم إعداد مولد الفواتير لاستخدام خط Amiri العربي إذا كان متوفراً في assets/fonts/Amiri-Regular.ttf.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
