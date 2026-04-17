import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gabut_tracker/controllers/bapenda_controller.dart';
import 'package:gabut_tracker/ui/screens/dashboard/log_bapenda_screen.dart'; // Import Riwayat Log
import 'package:gabut_tracker/ui/screens/form/form_bapenda_screen.dart';
import 'package:gabut_tracker/ui/screens/dashboard/mandiri_screen.dart';
import './pengaturan_screen.dart';

class BapendaScreen extends StatefulWidget {
  const BapendaScreen({super.key});

  @override
  State<BapendaScreen> createState() => _BapendaScreenState();
}

class _BapendaScreenState extends State<BapendaScreen> {
  final Color _warnaBapenda = const Color.fromARGB(255, 202, 175, 51);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BapendaController>().mulaiListen();
    });
  }

  void _unduhTemplate() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Template_Import_Bapenda.csv');

      String header =
          "NO,NAMA DEBITUR,DEVELOPER,TANGGAL BAYAR,NILAI BPHTB,PROGRESS BPHTB,SETOR BPHTB,NILAI PPH,PROGRES PPH,SETOR PPH,NO NTPN PPH\n";
      String contoh =
          "1,Budi Santoso,Perum Indah,15-04-2026,5000000,PROSES,Petugas A,2500000,PROSES,Petugas B,12345678\n";

      await file.writeAsString(header + contoh);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Template CSV berhasil dibuat! (PENTING: Save As ke format .xlsx sebelum diimpor)',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: _warnaBapenda,
          ),
        );
      }
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Template Import Bapenda');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat template.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BapendaController>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna Latar Belakang Clean
    Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF2D3142);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BAPENDA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Manajemen Pajak & Retribusi',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            tooltip: 'Menu Data',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) async {
              if (value == 'import') {
                FilePickerResult? result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['xlsx'],
                );
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mengimpor data Bapenda...')),
                  );
                  try {
                    int count = await context
                        .read<BapendaController>()
                        .imporExcelBapenda(result.files.single);
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Berhasil impor $count data!')),
                      );
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal impor Excel: $e')),
                      );
                  }
                }
              } else if (value == 'template') {
                _unduhTemplate();
              } else if (value == 'csv') {
                controller.eksporDanBagikanCSV();
              } else if (value == 'pdf') {
                controller.eksporDanBagikanPDF();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(
                      Icons.upload_file,
                      color: Color.fromARGB(255, 202, 175, 51),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('Impor Data (Excel)', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.table_view, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Unduh Template Impor',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Ekspor Laporan (CSV)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Ekspor Laporan (PDF)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buatSideMenuBaru(controller, isDark),
      body: controller.sedangMemuat
          ? Center(child: CircularProgressIndicator(color: _warnaBapenda))
          : Column(
              children: [
                // SEARCH & FILTER BAR (Clean UI)
                Container(
                  color: surfaceColor,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Cari debitur atau developer...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey.shade500,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            onChanged: (v) => controller.cariData(v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: _warnaBapenda.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _warnaBapenda.withOpacity(0.3),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.tune, color: _warnaBapenda),
                          tooltip: 'Filter Data',
                          onPressed: () =>
                              _tampilkanModalFilter(context, controller),
                        ),
                      ),
                    ],
                  ),
                ),

                // LIST BAPENDA (Clean UI)
                Expanded(
                  child: controller.listFiltered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada data',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: controller.listFiltered.length,
                          itemBuilder: (context, index) {
                            final item = controller.listFiltered[index];

                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.red.withOpacity(0.2)
                                      : const Color(0xFFFFECEC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.red.shade900
                                        : Colors.red.shade100,
                                  ),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: isDark
                                      ? Colors.red.shade300
                                      : Colors.red,
                                  size: 28,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: const Text(
                                        'Hapus Data?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        'Hapus berkas milik "${item.namaDebitur}" secara permanen?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text(
                                            'BATAL',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red.shade50,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text(
                                            'HAPUS',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) async {
                                try {
                                  await context
                                      .read<BapendaController>()
                                      .hapusData(item);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Data ${item.namaDebitur} dihapus!',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menghapus: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: GestureDetector(
                                onTap: () async {
                                  final bapendaCtrl = context
                                      .read<BapendaController>();
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FormBapendaScreen(dataAwal: item),
                                    ),
                                  );

                                  if (res != null) {
                                    try {
                                      if (mounted)
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Menyimpan...'),
                                          ),
                                        );
                                      await bapendaCtrl.simpanData(
                                        res,
                                        dataAwal: item,
                                      );
                                      if (mounted)
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Data diperbarui!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                    } catch (e) {
                                      if (mounted)
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Gagal Update!'),
                                            content: Text(e.toString()),
                                          ),
                                        );
                                    }
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isDark
                                        ? Border.all(
                                            color: Colors.grey.shade800,
                                          )
                                        : Border.all(
                                            color: Colors.grey.shade200,
                                          ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.namaDebitur,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: textColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (item.tglBayar.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.tglBayar,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.business,
                                            size: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item.developer.isEmpty
                                                  ? '-'
                                                  : item.developer,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Divider(height: 1, thickness: 1),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildInfoColumn(
                                            'BPHTB',
                                            item.nilaiBphtb,
                                            item.progresBphtb,
                                          ),
                                          _buildInfoColumn(
                                            'PPH',
                                            item.nilaiPph,
                                            item.progresPph,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bapendaCtrl = context.read<BapendaController>();
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormBapendaScreen()),
          );

          if (res != null) {
            try {
              if (mounted)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Menyimpan...')));
              await bapendaCtrl.simpanData(res);
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data berhasil disimpan!'),
                    backgroundColor: Colors.green,
                  ),
                );
            } catch (e) {
              if (mounted)
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text(
                      'Error',
                      style: TextStyle(color: Colors.red),
                    ),
                    content: Text(e.toString()),
                  ),
                );
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Data',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: _warnaBapenda,
        foregroundColor: Colors.white,
        elevation: 0, // Clean UI FAB
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // --- WIDGET HELPER UNTUK KOLOM INFO (CLEAN UI) ---
  Widget _buildInfoColumn(String title, String value, String status) {
    bool isSelesai = status.toLowerCase().contains('selesai');
    Color statusColor = isSelesai ? Colors.green : Colors.orange.shade700;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value == 'MBR' ? 'MBR' : (value.isEmpty ? 'Rp 0' : 'Rp $value'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- FILTER MODAL (Sesuai Bawaan dengan sedikit perapihan radius) ---
  void _tampilkanModalFilter(
    BuildContext context,
    BapendaController controller,
  ) {
    List<String> listDev = ['SEMUA'];
    List<String> listProgres = ['SEMUA'];

    for (var item in controller.listBapenda) {
      if (item.developer.trim().isNotEmpty) listDev.add(item.developer.trim());
      if (item.progresBphtb.trim().isNotEmpty)
        listProgres.add(item.progresBphtb.trim());
    }

    listDev = listDev.toSet().toList()..sort();
    listProgres = listProgres.toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        height: MediaQuery.of(context).size.height * 0.70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () {
                    controller.resetFilter();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Developer / Perumahan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    value: controller.filterDeveloper,
                    items: listDev
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        controller.setFilterDropdown(developer: v),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Progres BPHTB',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    value: controller.filterProgresBphtb,
                    items: listProgres
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => controller.setFilterDropdown(progres: v),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'RENTANG TANGGAL BAYAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.date_range, color: _warnaBapenda),
                      title: Text(
                        controller.filterTanggalMulai != null &&
                                controller.filterTanggalAkhir != null
                            ? '${DateFormat('dd MMM yyyy').format(controller.filterTanggalMulai!)} - ${DateFormat('dd MMM yyyy').format(controller.filterTanggalAkhir!)}'
                            : 'Pilih Rentang Waktu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: controller.filterTanggalMulai != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: controller.filterTanggalMulai != null
                              ? _warnaBapenda
                              : null,
                        ),
                      ),
                      trailing: controller.filterTanggalMulai != null
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () =>
                                  controller.setRentangTanggal(null, null),
                            )
                          : const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () async {
                        DateTimeRange? pickedRange = await showDateRangePicker(
                          context: context,
                          initialDateRange:
                              controller.filterTanggalMulai != null &&
                                  controller.filterTanggalAkhir != null
                              ? DateTimeRange(
                                  start: controller.filterTanggalMulai!,
                                  end: controller.filterTanggalAkhir!,
                                )
                              : null,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: _warnaBapenda,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (pickedRange != null)
                          controller.setRentangTanggal(
                            pickedRange.start,
                            pickedRange.end,
                          );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _warnaBapenda,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Terapkan Filter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DRAWER CLEAN UI ---
  Widget _buatSideMenuBaru(BapendaController controller, bool isDark) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Memuat...';

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            width: double.infinity,
            color: _warnaBapenda.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _warnaBapenda,
                  radius: 30,
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userEmail)
                      .get(),
                  builder: (context, snapshot) {
                    String role = 'Memuat...'; // Teks awal saat masih loading

                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        role =
                            data?['role'] ??
                            'STAFF'; // Ambil role dari Firestore
                      } else {
                        role = 'STAFF'; // Default jika data tidak ditemukan
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _warnaBapenda.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Akses: $role',
                        style: TextStyle(
                          color: _warnaBapenda,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ], // 👆 =================================== 👆              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerTitle('NAVIGASI'),
                _buildDrawerItem(
                  Icons.home_outlined,
                  'Beranda',
                  () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                _buildDrawerItem(Icons.domain, 'Mandiri', () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MandiriScreen(),
                    ),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(height: 30),
                ),

                _buildDrawerTitle('SISTEM'),
                _buildDrawerItem(
                  Icons.history,
                  'Riwayat Aktivitas Bapenda',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LogBapendaScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.settings_outlined,
                  'Pengaturan',
                  () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HalamanPengaturan(),
                      ),
                    );
                    controller.mulaiListen();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Colors.red.withOpacity(0.05),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (mounted)
                  Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade600, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
