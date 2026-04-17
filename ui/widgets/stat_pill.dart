import 'package:flutter/material.dart';

class StatPill extends StatelessWidget {
  final String judul;
  final int angka;
  final Color warna;
  final bool isAktif;
  final IconData ikon;
  final bool isDark;
  final VoidCallback onTap;

  const StatPill({
    super.key,
    required this.judul,
    required this.angka,
    required this.warna,
    required this.isAktif,
    required this.ikon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isAktif ? warna : (isDark ? Colors.grey[850] : Colors.white),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isAktif
                ? warna
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: 1.5,
          ),
          boxShadow: isAktif
              ? [
                  BoxShadow(
                    color: warna.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, color: isAktif ? Colors.white : warna, size: 22),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  angka.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAktif
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                Text(
                  judul.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isAktif ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
