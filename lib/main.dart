import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_section.dart';
import 'providers/pos_provider.dart';
import 'services/db_helper.dart';
import 'services/file_utils.dart';
import 'widgets/dashboard.dart';
import 'widgets/inventory_panel.dart';
import 'widgets/placeholder_panel.dart';
import 'widgets/pos_layout.dart';
import 'widgets/settings_panel.dart';
import 'widgets/sidebar.dart';
import 'widgets/transactions.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PosProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tobacco POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.all(0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F7F9),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF3F7F9), Color(0xFFE7F5F3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: child ?? const SizedBox(),
          ),
        );
      },
      home: const HomeScreen(),
    );
  }
}

class TobaccoPosApp extends MyApp {
  const TobaccoPosApp({super.key});
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
    setState(() => _selected = s);
  }

  void _processBarcode(String code) {
    final pos = context.read<PosProvider>();
    final found = pos.findByBarcode(code);
    if (found != null) {
      pos.addToCart(found);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة "${found.displayName}" إلى السلة')),
      );
      _barcodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد منتج مطابق للباركود')),
      );
    }
  }

  PreferredSizeWidget _buildTopBar(double width, bool showMenuButton) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Text('Tobacco POS — ${_selected.label}', style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: false,
      leading: showMenuButton
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      actions: [
        IconButton(
          tooltip: 'استيراد بيانات المصنع',
          icon: const Icon(Icons.download_rounded),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('استيراد بيانات المصنع'),
                content: const Text('هل تريد استيراد بيانات المصنع؟ سيؤدي ذلك إلى مسح المنتجات الحالية وإعادة تحميل البيانات الافتراضية.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                  ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('نعم')),
                ],
              ),
            );
            if (confirmed == true) {
              final posProv = context.read<PosProvider>();
              try {
                await posProv.resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استيراد بيانات المصنع')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الاستيراد: $e')));
                }
              }
            }
          },
        ),
        IconButton(
          tooltip: 'تصدير قاعدة البيانات',
          icon: const Icon(Icons.upload_file_rounded),
          onPressed: () async {
            try {
              final path = await DBHelper.exportDatabaseToDownloads();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تصدير قاعدة البيانات: $path'),
                    action: SnackBarAction(
                      label: 'فتح',
                      onPressed: () async {
                        final ok = await FileUtils.openFile(path);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تعذر فتح الملف على هذا النظام')),
                          );
                        }
                      },
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التصدير: $e')));
              }
            }
          },
        ),
        SizedBox(
          width: width < 420 ? width * 0.6 : 360,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                hintText: 'مسح/ادخال الباركود واضغط Enter',
                prefixIcon: const Icon(Icons.qr_code_2_rounded),
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
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
            ),
            child: Sidebar(selected: _selected, onSelect: _selectSection),
          ),
          Expanded(child: content),
        ],
      );
    }

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
            final shortages = pos.checkCartAvailability();
            if (shortages.isNotEmpty) {
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
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines.map((l) => Text(l)).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
                  ],
                ),
              );
              return;
            }

            await pos.checkout();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة وتحديث المخزون')));
            }
          },
        );
      case AppSection.dashboard:
        return const Directionality(textDirection: TextDirection.rtl, child: Dashboard());
      case AppSection.inventory:
        return InventoryPanel(key: const ValueKey('inventory'));
      case AppSection.expensesDebts:
        return PlaceholderPanel(key: const ValueKey('expenses'), title: s.label, width: width, icon: s.icon);
      case AppSection.salesReports:
        return const Directionality(textDirection: TextDirection.rtl, child: TransactionsPage());
      case AppSection.users:
        return PlaceholderPanel(key: const ValueKey('users'), title: s.label, width: width, icon: s.icon);
      case AppSection.settings:
        return const SettingsPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 1000;

    if (wide) {
      return Scaffold(
        backgroundColor: Colors.transparent,
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
