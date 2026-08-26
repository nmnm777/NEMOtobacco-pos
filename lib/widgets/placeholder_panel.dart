import 'package:flutter/material.dart';

class PlaceholderPanel extends StatelessWidget {
  final String title;
  final double width;
  final IconData icon;

  const PlaceholderPanel({super.key, required this.title, required this.width, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 3,
        child: SizedBox(
          width: width > 700 ? 760 : double.infinity,
          height: 520,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 28, color: Colors.teal),
                    const SizedBox(width: 12),
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('جديد')),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Center(
                    child: Text('لوحة ${title} قيد التطوير — يمكنك إضافة ميزات لاحقًا.', style: TextStyle(color: Colors.grey.shade700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
