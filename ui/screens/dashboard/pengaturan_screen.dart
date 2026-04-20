// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sira_projects/core/utils/globals.dart';
import 'package:sira_projects/data/repositories/mandiri_repository.dart';
import 'package:sira_projects/ui/screens/admin/master_data_screen.dart';

class HalamanPengaturan extends StatefulWidget {
  const HalamanPengaturan({super.key});
  @override
  State<HalamanPengaturan> createState() => _HalamanPengaturanState();
}

class _HalamanPengaturanState extends State<HalamanPengaturan> {
  int _targetSLA = 30;
  String _userRole = 'STAFF';
  bool _isLoadingRole = true;

  // Palet Warna Premium
  final Color navyColor = const Color(0xFF0A192F);
  final Color goldAccent = const Color(0xFFC5A059);

  @override
  void initState() {
    super.initState();
    _muatPengaturan();
    _cekRolePengguna();
  }

  Future<void> _muatPengaturan() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetSLA = prefs.getInt('target_sla') ?? 30;
    });
  }

  Future<void> _cekRolePengguna() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _userRole = doc.data()?['role'] ?? 'STAFF';
            _isLoadingRole = false;
          });
          return;
        }
      } catch (e) {
        debugPrint("Gagal cek role: $e");
      }
    }
    if (mounted) setState(() => _isLoadingRole = false);
  }

  Future<void> _simpanSLA(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_sla', val);
    setState(() => _targetSLA = val);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Target SLA Default diperbarui!')),
    );
  }

  // Fungsi yang dimodifikasi untuk menampilkan peringatan Hubungi Admin
  void _resetKataSandi() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'INFO KEAMANAN',
          style: TextStyle(color: navyColor, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bila Anda ingin melakukan reset password, silakan hubungi Administrator.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navyColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('MENGERTI'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupDataJSON() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Menyiapkan backup JSON...')));
    try {
      final repo = context.read<MandiriRepository>();
      final allData = await repo.getAllData();
      if (allData.isEmpty) return;
      String dataJson = json.encode(allData);
      final direktori = await getTemporaryDirectory();
      final pathFile =
          '${direktori.path}/Backup_Notaris_${DateTime.now().millisecondsSinceEpoch}.json';
      await File(pathFile).writeAsString(dataJson);
      await Share.shareXFiles([XFile(pathFile)], text: 'Backup JSON');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _backupDataExcel() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Menyiapkan backup Excel...')));
    try {
      final repo = context.read<MandiriRepository>();
      final allData = await repo.getAllData();
      if (allData.isEmpty) return;
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Data_Notaris'];
      excel.setDefaultSheet('Data_Notaris');
      sheetObject.appendRow(
        [
          'ID',
          'Debitur',
          'Notaris',
          'KCU',
          'PIC Bank',
        ].map((e) => TextCellValue(e)).toList(),
      );

      for (var d in allData) {
        sheetObject.appendRow(
          [
            d['id'],
            d['debitur'],
            d['notaris'],
            d['kcu'],
            d['picBank'],
          ].map((e) => TextCellValue(e?.toString() ?? '')).toList(),
        );
      }
      var fileBytes = excel.save();
      if (fileBytes != null) {
        final direktori = await getTemporaryDirectory();
        final pathFile =
            '${direktori.path}/Laporan_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        File(pathFile).writeAsBytesSync(fileBytes);
        await Share.shareXFiles([XFile(pathFile)]);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _restoreDataJSON() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        String isiJson = await File(result.files.single.path!).readAsString();
        List<dynamic> dataBaru = json.decode(isiJson);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'RESTORE DATA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text('Upload ${dataBaru.length} data ke Cloud?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final repo = this.context.read<MandiriRepository>();
                  await repo.restoreData(dataBaru);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Berhasil direstore!')),
                    );
                  }
                },
                child: const Text('RESTORE'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _hapusSemuaData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'HAPUS SEMUA DATA',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Yakin ingin menghapus semua data di Cloud? Aksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final repo = this.context.read<MandiriRepository>();
              await repo.hapusSemuaData();
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Data dibersihkan!')),
                );
              }
            },
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? navyColor).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? navyColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: iconColor == Colors.redAccent ? Colors.redAccent : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, size: 20, color: Colors.grey)
              : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    bool isDark = themeCtrl.themeMode == ThemeMode.dark;
    bool isAdmin = _userRole == 'ADMIN';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'PENGATURAN',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
        backgroundColor: navyColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingRole
          ? Center(child: CircularProgressIndicator(color: navyColor))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ==========================================
                // SECTION 1: MASTER DATA (KHUSUS ADMIN)
                // ==========================================
                if (isAdmin) ...[
                  _buildSectionHeader('ADMINISTRATOR PANEL'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: goldAccent.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: _buildListTile(
                      icon: Icons.storage_rounded,
                      iconColor: goldAccent,
                      title: 'Kelola Master Data',
                      subtitle: 'Atur daftar KCU, Notaris, dan PIC Internal',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MasterDataScreen(),
                        ),
                      ),
                    ),
                  ),
                ],

                // ==========================================
                // SECTION 2: PENGATURAN UMUM
                // ==========================================
                _buildSectionHeader('PENGATURAN APLIKASI'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: navyColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.dark_mode_outlined,
                            color: navyColor,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Tema Gelap',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Switch(
                          value: isDark,
                          activeColor: goldAccent,
                          onChanged: (val) => themeCtrl.toggleTema(val),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: navyColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.timer_outlined,
                            color: navyColor,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Target SLA Default',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _targetSLA,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: goldAccent,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: goldAccent,
                            ),
                            items: [14, 30, 45, 60, 90].map((int val) {
                              return DropdownMenuItem<int>(
                                value: val,
                                child: Text('$val Hari'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) _simpanSLA(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // SECTION 3: KEAMANAN
                // ==========================================
                _buildSectionHeader('KEAMANAN AKUN'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: _buildListTile(
                    icon: Icons.lock_outline,
                    title: 'Ganti Kata Sandi',
                    subtitle: 'Hubungi Administrator untuk reset',
                    onTap: _resetKataSandi,
                  ),
                ),

                // ==========================================
                // SECTION 4: MANAJEMEN DATABASE MANDIRI
                // ==========================================
                _buildSectionHeader('MANAJEMEN DATA MANDIRI'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: Icons.table_chart_outlined,
                        iconColor: Colors.green,
                        title: 'Ekspor Excel Mandiri',
                        onTap: _backupDataExcel,
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildListTile(
                        icon: Icons.data_object,
                        iconColor: Colors.orange,
                        title: 'Backup JSON Mandiri',
                        onTap: _backupDataJSON,
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildListTile(
                        icon: Icons.restore_page_outlined,
                        iconColor: Colors.blueAccent,
                        title: 'Restore JSON Mandiri',
                        onTap: _restoreDataJSON,
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildListTile(
                        icon: Icons.delete_forever_outlined,
                        iconColor: Colors.redAccent,
                        title: 'Reset Database Mandiri',
                        onTap: _hapusSemuaData,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Versi 1.0.0 (Laporan Tracker)\nLogin sebagai: $_userRole',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
