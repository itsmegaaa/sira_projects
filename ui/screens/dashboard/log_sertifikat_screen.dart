// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class LogSertifikatScreen extends StatelessWidget {
  const LogSertifikatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color navyColor = const Color(0xFF0F172A);
    final Color goldColor = const Color(0xFFD4AF37);

    Color currentBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF8FAFC);
    Color currentSurface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color currentText = isDark ? Colors.white : navyColor;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        backgroundColor: currentSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: currentText),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AUDIT TRAIL',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: currentText,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Riwayat Pergerakan Sertifikat',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 👇 goldColor kita gunakan di sini agar tampilannya lebih premium
            Icon(
              Icons.history_rounded,
              size: 80,
              color: goldColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Modul Log Riwayat sedang disiapkan',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(Pondasi UI telah terhubung dengan layar utama)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
