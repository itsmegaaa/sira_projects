import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:sira_projects/controllers/mandiri_controller.dart';
import 'package:sira_projects/controllers/bapenda_controller.dart';
import 'package:sira_projects/ui/screens/dashboard/mandiri_screen.dart';
import 'package:sira_projects/ui/screens/dashboard/bapenda_screen.dart';
import 'package:sira_projects/ui/screens/profil/profil_screen.dart';
import 'package:sira_projects/ui/screens/form/form_mandiri_screen.dart';
import 'package:sira_projects/ui/screens/form/form_bapenda_screen.dart';
import 'package:sira_projects/ui/screens/dashboard/pengaturan_screen.dart'; // 👈 Tambahkan baris ini

// =====================================================================
// KELAS FORMATTER: Untuk Input Kalkulator Rupiah
// =====================================================================
class CurrencyFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String cleanNumber = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.isEmpty) return newValue.copyWith(text: '');
    try {
      final formatter = NumberFormat.currency(
        locale: 'id',
        symbol: '',
        decimalDigits: 0,
      );
      String newText = formatter.format(int.parse(cleanNumber));
      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}

// =====================================================================
// CUSTOM PAINTER: Grafik Garis Dinamis untuk Latar Belakang Finansial
// =====================================================================
class ChartBackgroundPainter extends CustomPainter {
  final Color lineColor;
  ChartBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = lineColor.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintGradient = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withOpacity(0.2), lineColor.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.4,
    );

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintGradient);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Palet Warna Premium (Navy & Gold) dengan Latar Clean
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color surfaceColor = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MandiriController>().inisialisasiData();
      context.read<BapendaController>().mulaiListen();
    });
  }

  String _getSapaan() {
    var jam = DateTime.now().hour;
    if (jam >= 3 && jam < 11) return 'Selamat Pagi';
    if (jam >= 11 && jam < 15) return 'Selamat Siang';
    if (jam >= 15 && jam < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'User';
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color currentBg = isDark ? const Color(0xFF121212) : bgColor;
    Color currentSurface = isDark ? const Color(0xFF1E1E1E) : surfaceColor;
    Color currentText = isDark ? Colors.white : navyColor;

    return Scaffold(
      backgroundColor: currentBg,
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1. HEADER (SAPAAN & PROFIL)
                // ==========================================
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilScreen(),
                        ),
                      ),
                      child: Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: navyColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: navyColor.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            userEmail.isNotEmpty
                                ? userEmail[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: goldColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hallo, ${_getSapaan()} 👋',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail.split('@')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: currentText,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: currentSurface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.settings_outlined, color: currentText),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HalamanPengaturan(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ==========================================
                // 2. RINGKASAN FINANSIAL (PORTOFOLIO BULAN INI)
                // ==========================================
                Text(
                  'PORTOFOLIO MANDIRI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildWealthDashboard(context),
                const SizedBox(height: 32),

                // ==========================================
                // 3. PINTASAN AKSI CEPAT
                // ==========================================
                Text(
                  'PINTASAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickActionChip(
                        icon: Icons.add_circle_rounded,
                        label: 'Input Mandiri',
                        color: Colors.blueAccent,
                        surfaceColor: currentSurface,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FormMandiriScreen(
                              targetSLADefault: 30,
                              userRole: 'STAFF',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickActionChip(
                        icon: Icons.add_circle_rounded,
                        label: 'Input Bapenda',
                        color: goldColor,
                        surfaceColor: currentSurface,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FormBapendaScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickActionChip(
                        icon: Icons.calculate_rounded,
                        label: 'Hitung Pajak',
                        color: Colors.teal.shade600,
                        surfaceColor: currentSurface,
                        isDark: isDark,
                        onTap: () => _tampilkanKalkulator(
                          context,
                          currentBg,
                          currentSurface,
                          currentText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ==========================================
                // 4. MENU NAVIGASI UTAMA (LIST VIEW KECIL)
                // ==========================================
                Text(
                  'BANK & KORPORASI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _buildListModuleCard(
                      title: 'MANDIRI',
                      subtitle: 'Manajemen Berkas & Laporan',
                      icon: Icons.account_balance_rounded,
                      iconColor: Colors.blueAccent,
                      currentSurface: currentSurface,
                      currentText: currentText,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MandiriScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildListModuleCard(
                      title: 'BAPENDA',
                      subtitle: 'Pajak & Retribusi Daerah',
                      icon: Icons.domain_rounded,
                      iconColor: goldColor,
                      currentSurface: currentSurface,
                      currentText: currentText,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BapendaScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ==========================================
                // 5. RADAR JATUH TEMPO
                // ==========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BERKAS JATUH TEMPO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color.fromARGB(255, 0, 0, 0),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Icon(
                      Icons.radar_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRadarJatuhTempo(
                  context,
                  currentSurface,
                  currentText,
                  isDark,
                ),
                const SizedBox(height: 32),

                // ==========================================
                // 6. TOP PERFORMER TIM
                // ==========================================
                Text(
                  'TOP PERFORMER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLeaderboard(context, currentSurface, currentText, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: PINTASAN AKSI CEPAT (CHIPS)
  // ===========================================================================
  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color surfaceColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: Colors.grey.shade800) : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : navyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: KARTU NAVIGASI UTAMA (LIST VIEW RAMPING)
  // ===========================================================================
  Widget _buildListModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color currentSurface,
    required Color currentText,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: currentSurface,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: Colors.grey.shade800) : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: currentText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: RINGKASAN FINANSIAL (BULAN INI)
  // ===========================================================================
  Widget _buildWealthDashboard(BuildContext context) {
    final mandiriCtrl = context.watch<MandiriController>();

    double totalHT = 0;
    double totalBiaya = 0;
    int jumlahBerkasBulanIni = 0;

    // Filter Data Berdasarkan Bulan dan Tahun Berjalan
    DateTime waktuSekarang = DateTime.now();

    for (var item in mandiriCtrl.daftarOrder) {
      if (item.tglOrder != null &&
          item.tglOrder!.month == waktuSekarang.month &&
          item.tglOrder!.year == waktuSekarang.year) {
        String htStr = item.nilaiHT.replaceAll(RegExp(r'[^0-9]'), '');
        String biayaStr = item.biaya.replaceAll(RegExp(r'[^0-9]'), '');

        if (htStr.isNotEmpty) totalHT += double.parse(htStr);
        if (biayaStr.isNotEmpty) totalBiaya += double.parse(biayaStr);
        jumlahBerkasBulanIni++;
      }
    }

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: navyColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: navyColor.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: CustomPaint(
                painter: ChartBackgroundPainter(lineColor: goldColor),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: goldColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: goldColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TOTAL HT (BULAN INI)',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(totalHT)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BIAYA NOTARIS (BULAN INI)',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(totalBiaya)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: goldColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$jumlahBerkasBulanIni Berkas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.folder_special,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET: RADAR JATUH TEMPO
  // ===========================================================================
  Widget _buildRadarJatuhTempo(
    BuildContext context,
    Color surfaceColor,
    Color textColor,
    bool isDark,
  ) {
    final mandiriCtrl = context.watch<MandiriController>();

    var docs = mandiriCtrl.daftarOrder.where((item) {
      return item.progres != 'SELESAI' && item.deadline != null;
    }).toList();

    docs.sort((a, b) => a.deadline!.compareTo(b.deadline!));

    if (docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: Colors.grey.shade800) : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade400,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aman! Tidak ada berkas yang mendekati deadline.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          var item = docs[index];
          DateTime deadline = item.deadline!;
          int sisaHari = deadline.difference(DateTime.now()).inDays;

          Color statusColor = sisaHari < 0
              ? Colors.redAccent
              : (sisaHari <= 3 ? Colors.orangeAccent : Colors.blueAccent);
          String statusText = sisaHari < 0 ? 'TELAT' : 'H-$sisaHari';

          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16, bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(26),
              border: isDark ? Border.all(color: Colors.grey.shade800) : null,
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: statusColor.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.warning_rounded,
                      color: statusColor.withOpacity(0.5),
                      size: 16,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.debitur,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'SLA: ${DateFormat('dd MMM yyyy').format(deadline)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET: LEADERBOARD TIM
  // ===========================================================================
  Widget _buildLeaderboard(
    BuildContext context,
    Color surfaceColor,
    Color textColor,
    bool isDark,
  ) {
    final mandiriCtrl = context.watch<MandiriController>();

    Map<String, int> papanSkor = {};
    for (var item in mandiriCtrl.daftarOrder) {
      if (item.progres == 'SELESAI') {
        String pic = item.picInternal.trim();
        if (pic.isNotEmpty && pic != '-') {
          papanSkor[pic] = (papanSkor[pic] ?? 0) + 1;
        }
      }
    }

    if (papanSkor.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: Colors.grey.shade800) : null,
        ),
        child: const Text(
          'Belum ada pencapaian dari tim.',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    var listSkor = papanSkor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var top3 = listSkor.take(3).toList();

    List<String> medali = ['🥇', '🥈', '🥉'];
    List<Color> warnaMedali = [
      goldColor,
      Colors.grey.shade400,
      Colors.brown.shade300,
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(26),
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
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
        children: List.generate(top3.length, (index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: warnaMedali[index].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  medali[index],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Text(
              top3[index].key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              '${top3[index].value} Berkas',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: textColor,
                fontSize: 14,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: BOTTOM SHEET KALKULATOR PAJAK (ROUNDED)
  // ===========================================================================
  void _tampilkanKalkulator(
    BuildContext context,
    Color bgColor,
    Color surfaceColor,
    Color textColor,
  ) {
    TextEditingController njbCtrl = TextEditingController();
    String jenisSertifikat = 'AJB';
    String jenisPph = 'Komersil';
    int hasilBphtb = 0;
    int hasilPph = 0;
    bool isMBR = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void hitungOtomatis() {
              String cleanNJB = njbCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
              int njb = cleanNJB.isEmpty ? 0 : int.parse(cleanNJB);

              int subsidi = (jenisSertifikat == 'WARIS') ? 300000000 : 80000000;
              isMBR = (jenisSertifikat == 'AJB' && njb <= 140000000);
              hasilBphtb = isMBR ? 0 : ((njb - subsidi) * 0.05).toInt();
              if (hasilBphtb < 0) hasilBphtb = 0;

              double tarifPph = (jenisPph == 'Non Komersil') ? 0.01 : 0.025;
              hasilPph = (njb * tarifPph).toInt();
            }

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
              ),
              padding: EdgeInsets.only(
                top: 12,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kalkulator Cepat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        TextField(
                          controller: njbCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyFormat()],
                          decoration: InputDecoration(
                            labelText: 'Nilai Jual Beli (NJB)',
                            prefixText: 'Rp ',
                            filled: true,
                            fillColor: surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) => setState(() => hitungOtomatis()),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Jenis Transaksi',
                            filled: true,
                            fillColor: surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          value: jenisSertifikat,
                          items: ['AJB', 'WARIS', 'PROGRESIF']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) {
                            jenisSertifikat = v!;
                            setState(() => hitungOtomatis());
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Jenis PPh',
                            filled: true,
                            fillColor: surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          value: jenisPph,
                          items: ['Komersil', 'Non Komersil', 'Perorangan']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) {
                            jenisPph = v!;
                            setState(() => hitungOtomatis());
                          },
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: navyColor,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: navyColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ESTIMASI BIAYA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'BPHTB (5%)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    isMBR
                                        ? 'MBR (Rp 0)'
                                        : 'Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(hasilBphtb)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: goldColor,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(
                                  color: Colors.white24,
                                  height: 1,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PPh (${jenisPph == 'Non Komersil' ? '1%' : '2.5%'})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(hasilPph)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: goldColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
