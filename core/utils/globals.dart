import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================
// ThemeController: Menggantikan variabel global mutable
// Dikelola via Provider di main.dart
// =====================================================
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  Future<void> muatDariPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('tema_gelap') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTema(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tema_gelap', isDark);
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// =====================================================
// Format Rupiah: Menggunakan intl NumberFormat
// =====================================================
final _rupiahFormat = NumberFormat.currency(
  locale: 'id',
  symbol: '',
  decimalDigits: 0,
);

String formatRupiah(String angka) {
  if (angka.isEmpty) return '0';
  final clean = angka.replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.isEmpty) return '0';
  return _rupiahFormat.format(int.parse(clean));
}
