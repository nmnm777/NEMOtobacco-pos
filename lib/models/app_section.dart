import 'package:flutter/material.dart';

enum AppSection {
  dashboard,
  cashier,
  inventory,
  expensesDebts,
  salesReports,
  users,
  settings,
}

extension AppSectionExt on AppSection {
  String get label {
    switch (this) {
      case AppSection.dashboard:
        return 'لوحة المؤشرات والبيان';
      case AppSection.cashier:
        return 'الكاشير';
      case AppSection.inventory:
        return 'المخزون';
      case AppSection.expensesDebts:
        return 'المصروفات والديون';
      case AppSection.salesReports:
        return 'المبيعات والتقارير';
      case AppSection.users:
        return 'المستخدمين';
      case AppSection.settings:
        return 'الإعدادات';
    }
  }

  IconData get icon {
    switch (this) {
      case AppSection.dashboard:
        return Icons.dashboard;
      case AppSection.cashier:
        return Icons.point_of_sale;
      case AppSection.inventory:
        return Icons.inventory_2;
      case AppSection.expensesDebts:
        return Icons.money_off;
      case AppSection.salesReports:
        return Icons.bar_chart;
      case AppSection.users:
        return Icons.people;
      case AppSection.settings:
        return Icons.settings;
    }
  }
}
