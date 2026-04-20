// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  // Palet Warna Premium (Navy & Gold)
  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color surfaceColor = Colors.white;

  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<bool> _konfirmasiLogout(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Keluar Aplikasi',
              style: TextStyle(fontWeight: FontWeight.w900, color: navyColor),
            ),
            content: const Text(
              'Apakah Anda yakin ingin mengakhiri sesi dan keluar dari aplikasi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'BATAL',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'KELUAR',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ===========================================================================
  // FUNGSI: TAMPILKAN DETAIL SIRA (TENTANG APLIKASI)
  // ===========================================================================
  void _tampilkanTentangSIRA(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Header Logo SIRA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: navyColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: goldColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SIRA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const Text(
              'Sistem Informasi Riwayat Administrasi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'SIRA adalah platform digital yang dirancang untuk mengelola, mengarsipkan, dan melacak rekam jejak administrasi secara terstruktur. Fokus utama aplikasi ini adalah menyediakan "peta jalan" dokumen agar lebih transparan dan mudah diakses.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  _buildSiraPoint(
                    '1. Tujuan Utama',
                    'Digitalisasi berkas Notaris & Bapenda, optimalisasi SLA (deadline), serta transparansi rekam jejak setiap dokumen.',
                  ),
                  _buildSiraPoint(
                    '2. Fitur Unggulan',
                    'Modul Ganda (Mandiri & Bapenda), Radar Jatuh Tempo H-3, Kalkulator Pajak Otomatis, dan Ekspor Laporan PDF/CSV.',
                  ),
                  _buildSiraPoint(
                    '3. Alur Kerja (Workflow)',
                    'Input Data > Pelacakan Real-time Umur Pekerjaan > Update Kendala Lapangan > Verifikasi & Approval Admin > Pengarsipan Otomatis.',
                  ),
                  _buildSiraPoint(
                    '4. Manfaat Utama',
                    'Efisiensi operasional tanpa manual, mitigasi risiko keterlambatan berkas bank, dan pemantauan kinerja PIC secara objektif.',
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Developed by Ega • v2.0.0 Premium',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiraPoint(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: goldColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color currentBg = isDark ? const Color(0xFF121212) : bgColor;
    Color currentSurface = isDark ? const Color(0xFF1E1E1E) : surfaceColor;
    Color currentText = isDark ? Colors.white : navyColor;

    String email = currentUser?.email ?? 'Tidak diketahui';
    String inisial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        backgroundColor: currentBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: currentText),
        title: Text(
          'Profil Pengguna',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: currentText,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. KARTU IDENTITAS UTAMA
              // ==========================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: navyColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: navyColor.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: goldColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: goldColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          inisial,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: goldColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(email)
                          .get(),
                      builder: (context, snapshot) {
                        String role =
                            (snapshot.hasData && snapshot.data!.exists)
                            ? (snapshot.data!.data() as Map)['role'] ?? 'STAFF'
                            : 'STAFF';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: goldColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: goldColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'AKSES: $role',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: goldColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ==========================================
              // 2. KEAMANAN & PENGATURAN
              // ==========================================
              Text(
                'KEAMANAN & AKUN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: currentSurface,
                  borderRadius: BorderRadius.circular(26),
                  border: isDark
                      ? Border.all(color: Colors.grey.shade800)
                      : null,
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.lock_reset_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'Ubah Password',
                      subtitle: 'Hubungi administrator sistem',
                      isDark: isDark,
                      currentText: currentText,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            title: const Text(
                              'Reset Password',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              'Sistem saat ini menggunakan akses email internal. Silakan hubungi Admin jika ingin melakukan perubahan password.',
                            ),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: navyColor,
                                ),
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'MENGERTI',
                                  style: TextStyle(color: goldColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(
                        height: 1,
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                      ),
                    ),
                    _buildMenuTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.teal.shade500,
                      title: 'Tentang Aplikasi',
                      subtitle: 'Mengenal SIRA lebih dalam',
                      isDark: isDark,
                      currentText: currentText,
                      onTap: () => _tampilkanTentangSIRA(context, isDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ==========================================
              // 3. KELUAR APLIKASI
              // ==========================================
              Container(
                decoration: BoxDecoration(
                  color: currentSurface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: _buildMenuTile(
                  icon: Icons.logout_rounded,
                  iconColor: Colors.redAccent,
                  title: 'Keluar Aplikasi',
                  subtitle: 'Akhiri sesi dan kembali ke login',
                  isDark: isDark,
                  currentText: Colors.redAccent,
                  onTap: () async {
                    bool confirm = await _konfirmasiLogout(context);
                    if (confirm) {
                      await FirebaseAuth.instance.signOut();
                      if (mounted)
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color currentText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: currentText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 24,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }
}
