import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_section.dart';
import '../providers/pos_provider.dart';

class Sidebar extends StatelessWidget {
  final AppSection selected;
  final ValueChanged<AppSection> onSelect;

  const Sidebar({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.smoking_rooms, color: Colors.white)),
                const SizedBox(width: 8),
                Expanded(child: Text('Tobacco POS', style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: AppSection.values.map((s) {
                final isSelected = s == selected;
                return Material(
                  color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                  child: ListTile(
                    hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                    leading: Icon(s.icon, color: isSelected ? Colors.teal : null),
                    title: Text(s.label, textDirection: TextDirection.rtl),
                    selected: isSelected,
                    onTap: () => onSelect(s),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('تسجيل خروج'),
                content: const Text('هل تريد تسجيل الخروج؟ سيتم مسح السلة الحالية.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                  ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('تسجيل خروج')),
                ],
              ));

              if (confirm == true) {
                // clear cart (use Provider) and navigate to cashier
                try {
                  final pos = Provider.of<PosProvider>(context, listen: false);
                  pos.clearCart();
                } catch (e) {
                  // ignore if provider not available
                }
                onSelect(AppSection.cashier);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل خروج'),
          ),
          ),
        ],
      ),
    );
  }
}
