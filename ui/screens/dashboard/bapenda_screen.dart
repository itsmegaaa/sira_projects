// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sira_projects/controllers/bapenda_controller.dart';
import 'package:sira_projects/ui/screens/form/form_bapenda_screen.dart';
import 'package:sira_projects/ui/widgets/custom_drawer.dart';
import 'package:sira_projects/ui/widgets/expandable_fab.dart';
import 'package:sira_projects/ui/screens/dashboard/log_bapenda_screen.dart';

class BapendaScreen extends StatefulWidget {
  const BapendaScreen({super.key});

  @override
  State<BapendaScreen> createState() => _BapendaScreenState();
}

class _BapendaScreenState extends State<BapendaScreen> {
  // Palet Warna Premium Clean UI
  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color surfaceColor = Colors.white;

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
            backgroundColor: navyColor,
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

    Color currentBg = isDark ? const Color(0xFF121212) : bgColor;
    Color currentSurface = isDark ? const Color(0xFF1E1E1E) : surfaceColor;
    Color currentText = isDark ? Colors.white : navyColor;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        backgroundColor: currentSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: currentText),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BAPENDA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: currentText,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Manajemen Pajak & Retribusi',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: currentText),
            tooltip: 'Menu Data',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
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
                        SnackBar(
                          content: Text('Berhasil impor $count data!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal impor Excel: $e'),
                          backgroundColor: Colors.red,
                        ),
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
              PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: goldColor, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Impor Data (Excel)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'template',
                child: Row(
                  children: [
                    const Icon(
                      Icons.table_view,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Unduh Template Impor',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(
                      Icons.table_chart,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Ekspor Laporan (CSV)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
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
      drawer: const CustomDrawer(activeRoute: 'BAPENDA'),
      body: controller.sedangMemuat
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : Column(
              children: [
                // SEARCH & FILTER BAR
                Container(
                  color: currentSurface,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                              hintText: 'Cari Debitur atau Developer...',
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
                      GestureDetector(
                        onTap: () => _tampilkanModalFilter(context, controller),
                        child: Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: navyColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.tune_rounded, color: goldColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // LIST BAPENDA
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
                                'Belum ada data / Tidak ditemukan',
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
                                  borderRadius: BorderRadius.circular(30),
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
                                        'Hapus Data Bapenda?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        'Anda yakin ingin menghapus berkas milik "${item.namaDebitur}" secara permanen?',
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
                                          'Data ${item.namaDebitur} berhasil dihapus!',
                                        ),
                                        backgroundColor: Colors.redAccent,
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
                                            content: Text(
                                              'Menyimpan pembaruan...',
                                            ),
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
                                            content: Text(
                                              'Data Bapenda diperbarui!',
                                            ),
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
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: currentSurface,
                                    borderRadius: BorderRadius.circular(30),
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
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
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
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                color: currentText,
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
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _formatTanggalCerdas(
                                                  item.tglBayar,
                                                ),
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
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16,
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
                                          const SizedBox(width: 20),
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

      // GANTI FloatingActionButton.extended LAMA DENGAN INI
      floatingActionButton: ExpandableFab(
        distance: 110.0,
        children: [
          // 1. TOMBOL RIWAYAT (LOG)
          ActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LogBapendaScreen()),
            ),
            icon: const Icon(Icons.history_rounded),
            color: Colors.orange,
          ),

          // 2. TOMBOL UNDUH TEMPLATE
          ActionButton(
            onPressed: () => _unduhTemplate(),
            icon: const Icon(Icons.table_view_rounded),
            color: Colors.green,
          ),

          // 3. TOMBOL TAMBAH DATA
          ActionButton(
            onPressed: () async {
              final bapendaCtrl = context.read<BapendaController>();
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FormBapendaScreen(),
                ),
              );

              if (res != null) {
                try {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menyimpan data baru...')),
                    );
                  await bapendaCtrl.simpanData(res);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data Bapenda berhasil disimpan!'),
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
            icon: const Icon(Icons.add_rounded),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

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
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
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
          const SizedBox(height: 6),
          Text(
            value == 'MBR' ? 'MBR' : (value.isEmpty ? 'Rp 0' : 'Rp $value'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                width: 50,
                height: 5,
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
                  'Saring Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: navyColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    controller.resetFilter();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Filter dikembalikan ke awal'),
                        backgroundColor: navyColor,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
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
                  Text(
                    'RENTANG TANGGAL BAYAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.date_range, color: navyColor),
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
                              ? navyColor
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
                                primary: navyColor,
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
                  backgroundColor: navyColor,
                  foregroundColor: goldColor,
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

  // =================================================================
  // FUNGSI PENERJEMAH TANGGAL CERDAS
  // =================================================================
  String _formatTanggalCerdas(String tanggalRaw) {
    if (tanggalRaw.isEmpty || tanggalRaw == '-') return '-';

    try {
      // Skenario 1: Jika formatnya bawaan sistem/Firebase (Contoh: "2026-04-15 00:00:00.000")
      DateTime parsedDate = DateTime.parse(tanggalRaw);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      try {
        // Skenario 2: Jika format bawaan Excel manual (Contoh: "15-04-2026" atau "15/04/2026")
        String cleanDate = tanggalRaw.replaceAll('/', '-');
        List<String> parts = cleanDate.split('-');

        if (parts.length == 3) {
          // Asumsi formatnya Hari-Bulan-Tahun (dd-MM-yyyy)
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);

          DateTime manualDate = DateTime(year, month, day);
          return DateFormat('dd MMM yyyy').format(manualDate);
        }
      } catch (e2) {
        // Jika formatnya benar-benar hancur/tidak dikenali, tampilkan apa adanya daripada error
        return tanggalRaw;
      }
    }
    return tanggalRaw;
  }
}
