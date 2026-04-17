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
import 'package:sira_projects/ui/screens/admin/master_data_screen.dart'; // Import layar Master Data

class HalamanPengaturan extends StatefulWidget {
  const HalamanPengaturan({super.key});
  @override
  State<HalamanPengaturan> createState() => _HalamanPengaturanState();
}

class _HalamanPengaturanState extends State<HalamanPengaturan> {
  int _targetSLA = 30;
  String _userRole = 'STAFF';
  bool _isLoadingRole = true;

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
            title: const Text('Restore Data'),
            content: Text('Upload ${dataBaru.length} data ke Cloud?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
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
        title: const Text(
          'Hapus Semua Data',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text('Yakin ingin menghapus semua data di Cloud?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    bool isDark = themeCtrl.themeMode == ThemeMode.dark;
    bool isAdmin = _userRole == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ==========================================
                // SECTION 1: MASTER DATA (KHUSUS ADMIN)
                // ==========================================
                if (isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'ADMINISTRATOR PANEL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.indigo, width: 1),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.storage, color: Colors.white),
                      ),
                      title: const Text(
                        'Kelola Master Data',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Atur daftar KCU, Notaris, dan PIC Internal',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MasterDataScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ==========================================
                // SECTION 2: PENGATURAN UMUM
                // ==========================================
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'PENGATURAN APLIKASI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Tema Gelap'),
                        value: isDark,
                        onChanged: (val) => themeCtrl.toggleTema(val),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Target SLA'),
                        trailing: DropdownButton<int>(
                          value: _targetSLA,
                          items: [14, 30, 45, 60, 90]
                              .map(
                                (int val) => DropdownMenuItem<int>(
                                  value: val,
                                  child: Text('$val Hari'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) _simpanSLA(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ==========================================
                // SECTION 3: MANAJEMEN DATABASE
                // ==========================================
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8, left: 8),
                  child: Text(
                    'MANAJEMEN DATA MANDIRI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.table_chart,
                          color: Colors.green,
                        ),
                        title: const Text('Ekspor Excel Mandiri'),
                        onTap: _backupDataExcel,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.code, color: Colors.orange),
                        title: const Text('Backup JSON Mandiri'),
                        onTap: _backupDataJSON,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.restore, color: Colors.blue),
                        title: const Text('Restore JSON Mandiri'),
                        onTap: _restoreDataJSON,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text(
                          'Reset Database Mandiri',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: _hapusSemuaData,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
