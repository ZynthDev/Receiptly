import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<ExpenseCategory> categories = [
    ExpenseCategory(
      name: 'Food & Dining',
      icon: Icons.restaurant,
      color: Color(0xFF4CAF50),
    ),
    ExpenseCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Color(0xFF2196F3),
    ),
    ExpenseCategory(
      name: 'Transportation',
      icon: Icons.directions_car,
      color: Color(0xFF9C27B0),
    ),
    ExpenseCategory(
      name: 'Healthcare',
      icon: Icons.local_hospital,
      color: Color(0xFFF44336),
    ),
    ExpenseCategory(
      name: 'Entertainment',
      icon: Icons.movie,
      color: Color(0xFFFF9800),
    ),
    ExpenseCategory(
      name: 'Bills & Utilities',
      icon: Icons.receipt_long,
      color: Color(0xFF607D8B),
    ),
    ExpenseCategory(
      name: 'Education',
      icon: Icons.school,
      color: Color(0xFF3F51B5),
    ),
    ExpenseCategory(
      name: 'Travel',
      icon: Icons.flight,
      color: Color(0xFF00BCD4),
    ),
    ExpenseCategory(
      name: 'Groceries',
      icon: Icons.local_grocery_store,
      color: Color(0xFF8BC34A),
    ),
    ExpenseCategory(
      name: 'Other',
      icon: Icons.category,
      color: Color(0xFF795548),
    ),
  ];

  static ExpenseCategory getCategoryByName(String name) {
    return categories.firstWhere(
      (category) => category.name == name,
      orElse: () => categories.last, // Return 'Other' as default
    );
  }

  static Color getColorByName(String name) {
    return getCategoryByName(name).color;
  }

  static IconData getIconByName(String name) {
    return getCategoryByName(name).icon;
  }
}
