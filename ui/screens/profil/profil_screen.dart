import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  String _userRole = 'STAFF';
  String _namaPic = '';

  int _mandiriProses = 0;
  int _mandiriTelat = 0;
  int _bapendaProses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatDataProfil();
  }

  Future<void> _muatDataProfil() async {
    if (user == null) return;

    try {
      // 1. Ambil Role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userRole = userDoc.data()?['role'] ?? 'STAFF';
          _namaPic = userDoc.data()?['nama_pic'] ?? '';
        });
      }

      Query mandiriQuery = FirebaseFirestore.instance.collection(
        'data_mandiri',
      );
      if (_userRole != 'ADMIN' && _namaPic.isNotEmpty) {
        mandiriQuery = mandiriQuery.where('picInternal', isEqualTo: _namaPic);
      }

      // OPTIMASI 1: Hitung berkas Proses (1 READ SAJA dengan .count()!)
      final prosesQuery = await mandiriQuery
          .where('progres', isEqualTo: 'PROSES')
          .count()
          .get();
      int mProses = prosesQuery.count ?? 0;

      // OPTIMASI 2: Hitung berkas Telat (Hanya download berkas yang belum SELESAI, BUKAN SEMUA)
      final mBelumSelesaiSnap = await mandiriQuery
          .where('progres', isNotEqualTo: 'SELESAI')
          .get();
      int mTelat = 0;
      DateTime now = DateTime.now();
      for (var doc in mBelumSelesaiSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        try {
          String deadlineStr = data['deadline']?.toString() ?? '';
          if (deadlineStr.isNotEmpty) {
            DateTime deadline = DateTime.parse(deadlineStr);
            if (now.isAfter(
              DateTime(deadline.year, deadline.month, deadline.day, 23, 59, 59),
            ))
              mTelat++;
          }
        } catch (_) {}
      }

      // GANTI KODE PENGAMBILAN BAPENDA DI PROFIL_SCREEN MENJADI INI:
      final totalBapendaQuery = await FirebaseFirestore.instance
          .collection('pekerjaan_bapenda')
          .count()
          .get();
      final selesaiBapendaQuery = await FirebaseFirestore.instance
          .collection('pekerjaan_bapenda')
          .where('progresBphtb', isEqualTo: 'SELESAI')
          .where('progresPph', isEqualTo: 'SELESAI')
          .count()
          .get();

      int bProses =
          (totalBapendaQuery.count ?? 0) - (selesaiBapendaQuery.count ?? 0);
      if (mounted) {
        setState(() {
          _mandiriProses = mProses;
          _mandiriTelat = mTelat;
          _bapendaProses = bProses;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error muat profil: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String inisial = user?.email?.isNotEmpty == true
        ? user!.email![0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          inisial,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.email ?? 'Tidak diketahui',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Hak Akses: $_userRole',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_namaPic.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'PIC Internal: $_namaPic',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  'RINGKASAN PEKERJAAN (MANDIRI)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Berkas Aktif',
                        _mandiriProses,
                        Colors.blue,
                        Icons.autorenew,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        'Berkas Telat',
                        _mandiriTelat,
                        Colors.red,
                        Icons.warning_rounded,
                        isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Text(
                  'RINGKASAN PEKERJAAN (BAPENDA)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pekerjaan Berjalan',
                        _bapendaProses,
                        const Color.fromARGB(255, 202, 175, 51),
                        Icons.receipt_long,
                        isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted)
                      Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
    String judul,
    int angka,
    Color warna,
    IconData ikon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warna.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: warna.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: warna, size: 28),
          const SizedBox(height: 12),
          Text(
            angka.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: warna,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            judul,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
