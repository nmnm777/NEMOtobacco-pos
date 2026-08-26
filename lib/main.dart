import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_section.dart';
import 'models/product.dart';
import 'models/cart_item.dart';
import 'providers/pos_provider.dart';
import 'widgets/sidebar.dart';
import 'widgets/pos_layout.dart';
import 'widgets/placeholder_panel.dart';
import 'widgets/dashboard.dart';
import 'widgets/transactions.dart';
import 'widgets/settings_panel.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PosProvider(),
      child: const TobaccoPosApp(),
    ),
  );
}

class TobaccoPosApp extends StatelessWidget {
  const TobaccoPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tobacco POS',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      // Force RTL across the app for Arabic professional layout
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox());
      },
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppSection _selected = AppSection.cashier;

  final TextEditingController _barcodeController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _selectSection(AppSection s) {
    setState(() {
      _selected = s;
    });
  }

  void _processBarcode(String code) {
    final pos = context.read<PosProvider>();
    final found = pos.findByBarcode(code);
    if (found != null) {
      pos.addToCart(found);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة "${found.displayName}" إلى السلة')));
      _barcodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد منتج مطابق للباركود')));
    }
  }

  PreferredSizeWidget _buildTopBar(double width, bool showMenuButton) {
    return AppBar(
      title: Text('Tobacco POS — ${_selected.label}'),
      centerTitle: false,
      leading: showMenuButton
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      actions: [
        SizedBox(
          width: width < 420 ? width * 0.6 : 360,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                hintText: 'مسح/ادخال الباركود واضغط Enter',
                prefixIcon: const Icon(Icons.qr_code_2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;
                _processBarcode(value);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildResponsiveScaffold(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 1000;

    final content = _buildSectionContent(width);

    if (wide) {
      return Row(
        children: [
          Container(
            width: 260,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Sidebar(selected: _selected, onSelect: _selectSection),
          ),
          Expanded(child: content),
        ],
      );
    } else {
      return Scaffold(
        appBar: _buildTopBar(width, true),
        drawer: Drawer(
          child: SafeArea(
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
                    children: AppSection.values.map((s) {
                      final isSelected = s == _selected;
                      return Material(
                        color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                        child: ListTile(
                          hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                          leading: Icon(s.icon, color: isSelected ? Colors.teal : null),
                          title: Text(s.label, textDirection: TextDirection.rtl),
                          selected: isSelected,
                          onTap: () {
                            Navigator.of(context).pop();
                            _selectSection(s);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: content,
      );
    }
  }

  Widget _buildSectionContent(double width) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _sectionWidget(_selected, width),
      ),
    );
  }

  Widget _sectionWidget(AppSection s, double width) {
    final pos = context.watch<PosProvider>();
    switch (s) {
      case AppSection.cashier:
        return PosLayout(
          key: const ValueKey('cashier'),
          products: pos.products,
          selectedCategory: pos.selectedCategory,
          onCategoryChanged: (c) => pos.setCategory(c),
          addToCart: pos.addToCart,
          cart: pos.cart,
          changeQty: pos.changeQty,
          removeFromCart: pos.removeFromCart,
          totalPriceGetter: () => pos.totalPrice,
          barcodeController: _barcodeController,
          processBarcode: _processBarcode,
          onClearCart: () => pos.clearCart(),
          onCheckout: () async {
            // check availability first
            final shortages = pos.checkCartAvailability();
            if (shortages.isNotEmpty) {
              // build message listing shortage items
              final lines = <String>[];
              shortages.forEach((productId, shortageAmt) {
                final p = pos.getProductById(productId);
                final name = p?.displayName ?? productId;
                final available = p != null ? p.stock : 0;
                lines.add('$name — المطلوب ${shortageAmt + available}، المتوفر $available (نقص ${shortageAmt})');
              });

              await showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('كمية غير كافية'),
                  content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines.map((l) => Text(l)).toList())),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
                  ],
                ),
              );
              return;
            }

            // perform checkout and show confirmation
            await pos.checkout();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة وتحديث المخزون')));
          },
        );
      case AppSection.dashboard:
              return const Directionality(textDirection: TextDirection.rtl, child: Dashboard());
      case AppSection.inventory:
        return PlaceholderPanel(key: const ValueKey('inventory'), title: s.label, width: width, icon: s.icon);
      case AppSection.expensesDebts:
        return PlaceholderPanel(key: const ValueKey('expenses'), title: s.label, width: width, icon: s.icon);
      case AppSection.salesReports:
              return const Directionality(textDirection: TextDirection.rtl, child: TransactionsPage());
      case AppSection.users:
        return PlaceholderPanel(key: const ValueKey('users'), title: s.label, width: width, icon: s.icon);
      case AppSection.settings:
        return SettingsPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 1000;

    if (wide) {
      return Scaffold(
        body: Column(
          children: [
            SizedBox(height: kToolbarHeight, child: _buildTopBar(width, false)),
            Expanded(child: _buildResponsiveScaffold(context)),
          ],
        ),
      );
    }

    return _buildResponsiveScaffold(context);
  }
}

// --- small extension helper ---
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
