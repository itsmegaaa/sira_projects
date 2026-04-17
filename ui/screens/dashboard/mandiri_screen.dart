import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:sira_projects/data/models/mandiri_model.dart';
import 'package:sira_projects/ui/screens/form/form_mandiri_screen.dart';
import 'package:sira_projects/ui/screens/dashboard/bapenda_screen.dart';
import './pengaturan_screen.dart';
import 'package:sira_projects/controllers/mandiri_controller.dart';
import 'package:sira_projects/ui/widgets/order_card.dart';
import 'package:sira_projects/ui/widgets/stat_pill.dart';

class MandiriScreen extends StatefulWidget {
  const MandiriScreen({super.key});
  @override
  State<MandiriScreen> createState() => _MandiriScreenState();
}

class _MandiriScreenState extends State<MandiriScreen> {
  final TextEditingController _catatanCtrl = TextEditingController();
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // Palet Warna Premium Clean UI
  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color surfaceColor = Colors.white;

  @override
  void dispose() {
    _connSub?.cancel();
    _catatanCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MandiriController>().inisialisasiData();
    });

    _connSub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (mounted)
        setState(() => _isOnline = !result.contains(ConnectivityResult.none));
    });
  }

  void _tandaiSelesai(String idDokumen, String namaDebitur) async {
    final controller = context.read<MandiriController>();
    try {
      await controller.tandaiSelesai(idDokumen, namaDebitur);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status.')),
        );
    }
  }

  void _hapusData(String idDokumen, String namaDebitur) async {
    final controller = context.read<MandiriController>();
    try {
      await controller.hapusData(idDokumen, namaDebitur);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menghapus data.')));
    }
  }

  void _tambahHistori(String idDokumen) async {
    if (_catatanCtrl.text.trim().isEmpty) return;
    final controller = context.read<MandiriController>();
    try {
      await controller.tambahHistori(idDokumen, _catatanCtrl.text.trim());
      _catatanCtrl.clear();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambah catatan.')),
        );
    }
  }

  void _eksporDanBagikanCSV() async {
    final controller = context.read<MandiriController>();
    try {
      await controller.eksporDanBagikanCSV();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal ekspor data.')));
    }
  }

  void _imporExcel() async {
    final controller = context.read<MandiriController>();
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengunggah data ke Cloud...')),
      );
      try {
        int count = await controller.imporExcel(result.files.single);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil impor $count data!'),
              backgroundColor: Colors.green,
            ),
          );
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal impor Excel: $e'),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  void _unduhTemplate() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Template_Import_Mandiri.csv');

      String header =
          "DEBITUR,NOTARIS,KCU,PIC BANK,NO SURAT,TGL ORDER (YYYY-MM-DD),JENIS,RINCIAN,COVERNOTE,LIMIT,NILAI HT,BIAYA,TGL PELAKSANAAN,DEADLINE SLA,UMUR PEKERJAAN,PROGRES,PROGRES KETERANGAN,TGL BAST,PER KASUS,NOTE,PIC INTERNAL\n";
      String contoh =
          "Budi Santoso,Notaris A,KCU Garut,PIC Bank A,001/SK,2024-01-01,AJB,Rincian,CVR-01,100000000,100000000,5000000,2024-01-05,2024-02-05,30,PROSES,Ket,2024-01-10,Kasus,Note,ALDY\n";

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
      ], subject: 'Template Import Mandiri');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat template.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<MandiriController>();

    Color currentBg = isDark ? const Color(0xFF121212) : bgColor;
    Color currentSurface = isDark ? const Color(0xFF1E1E1E) : surfaceColor;
    Color currentText = isDark ? Colors.white : navyColor;

    List<OrderModel> filteredData = controller.filteredData;
    int totalSelesai = 0, totalTelat = 0, totalProses = 0, totalApproval = 0;

    for (var item in controller.daftarOrder) {
      String progres = item.progres;
      if (progres == 'SELESAI')
        totalSelesai++;
      else if (progres == 'MENUNGGU APPROVAL')
        totalApproval++;
      else if (controller.cekTelat(item))
        totalTelat++;
      else
        totalProses++;
    }

    bool isAdmin = controller.userRole == 'ADMIN';
    bool isPIC = controller.userRole == 'PIC';
    bool canApprove = isAdmin || isPIC;
    bool canEdit = true;

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
              'MANDIRI',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: currentText,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Manajemen Berkas Notaris',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          if (canApprove)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: currentText),
              tooltip: 'Menu Data',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (value) {
                if (value == 'import')
                  _imporExcel();
                else if (value == 'template')
                  _unduhTemplate();
                else if (value == 'csv')
                  _eksporDanBagikanCSV();
                else if (value == 'pdf')
                  controller.eksporDanBagikanPDF();
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
      drawer: _buatSideMenuBaru(controller, isDark),

      body: controller.sedangMemuat
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : Column(
              children: [
                if (!_isOnline)
                  Container(
                    width: double.infinity,
                    color: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 14),
                        SizedBox(width: 8),
                        Text(
                          'Tidak Ada Koneksi Internet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // STAT PILL & SEARCH BAR (Disamakan dengan Bapenda)
                Container(
                  color: currentSurface,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            if (canApprove) ...[
                              StatPill(
                                judul: 'Approval',
                                angka: totalApproval,
                                warna: Colors.purple,
                                isAktif: controller.filterStatus == 'APPROVAL',
                                ikon: Icons.pending_actions,
                                isDark: isDark,
                                onTap: () =>
                                    controller.setFilterStatus('APPROVAL'),
                              ),
                              const SizedBox(width: 10),
                            ],
                            StatPill(
                              judul: 'Selesai',
                              angka: totalSelesai,
                              warna: Colors.green,
                              isAktif: controller.filterStatus == 'SELESAI',
                              ikon: Icons.check_circle,
                              isDark: isDark,
                              onTap: () =>
                                  controller.setFilterStatus('SELESAI'),
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              judul: 'Proses',
                              angka: totalProses,
                              warna: Colors.orange,
                              isAktif: controller.filterStatus == 'PROSES',
                              ikon: Icons.autorenew,
                              isDark: isDark,
                              onTap: () => controller.setFilterStatus('PROSES'),
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              judul: 'Telat',
                              angka: totalTelat,
                              warna: Colors.red,
                              isAktif: controller.filterStatus == 'TELAT',
                              ikon: Icons.warning_rounded,
                              isDark: isDark,
                              onTap: () => controller.setFilterStatus('TELAT'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                    hintText: 'Cari debitur, no surat, KCU...',
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
                                  onChanged: (v) => controller.setKataKunci(v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () =>
                                  _tampilkanModalFilter(context, controller),
                              child: Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: navyColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: goldColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // LIST ORDER MANDIRI
                Expanded(
                  child: filteredData.isEmpty
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
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            final item = filteredData[index];
                            bool isSelesai = item.progres == 'SELESAI';
                            bool isTelat = controller.cekTelat(item);
                            int sisaHari = controller.hitungSisaHari(item);
                            bool isMenunggu =
                                item.progres == 'MENUNGGU APPROVAL';
                            bool isHampirTelat =
                                !isSelesai && !isTelat && sisaHari <= 3;

                            Color col = isSelesai
                                ? Colors.green
                                : (isTelat
                                      ? Colors.red
                                      : (isMenunggu
                                            ? Colors.purple
                                            : (item.progres == 'DRAFT'
                                                  ? Colors.grey
                                                  : (isHampirTelat
                                                        ? Colors.orange.shade800
                                                        : Colors.blueAccent))));
                            String teksStatus = isHampirTelat
                                ? 'WARNING H-$sisaHari'
                                : (isTelat ? 'TELAT' : item.progres);

                            return OrderCard(
                              item: item,
                              isDark: isDark,
                              isSelesai: isSelesai,
                              isTelat: isTelat,
                              isMenunggu: isMenunggu,
                              sisaHari: sisaHari,
                              warnaStatus: col,
                              teksStatus: teksStatus,
                              dismissDirection: isAdmin
                                  ? DismissDirection.endToStart
                                  : DismissDirection.none,
                              onTap: () => _tampilkanDetail(item),
                              onLongPress: (!isSelesai && canEdit)
                                  ? () => showDialog(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        title: const Text(
                                          'Tandai Selesai?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Text(
                                          'Berkas debitur ${item.debitur} sudah beres?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(c),
                                            child: const Text(
                                              'BATAL',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green.shade50,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(c);
                                              _tandaiSelesai(
                                                item.id,
                                                item.debitur,
                                              );
                                            },
                                            child: const Text(
                                              'YA, SELESAI',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                              confirmDismiss: (d) => showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Text(
                                    'Hapus?',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'Hapus berkas atas nama ${item.debitur}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text(
                                        'BATAL',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text(
                                        'HAPUS',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (d) =>
                                  _hapusData(item.id, item.debitur),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormMandiriScreen(
                targetSLADefault: controller.targetSLA,
                userRole: controller.userRole,
              ),
            ),
          );
          if (res != null) {
            await controller.simpanOrder(res);
          }
        },
        icon: Icon(Icons.add_rounded, color: goldColor),
        label: Text(
          'TAMBAH DATA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: goldColor,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: navyColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _tampilkanModalFilter(
    BuildContext context,
    MandiriController controller,
  ) {
    List<String> listTahun = ['SEMUA'],
        listPIC = ['SEMUA'],
        listKCU = ['SEMUA'];

    for (var item in controller.daftarOrder) {
      if (item.tglOrder != null) listTahun.add(item.tglOrder!.year.toString());
      if (item.picInternal.isNotEmpty) listPIC.add(item.picInternal);
      if (item.kcu.isNotEmpty) listKCU.add(item.kcu);
    }

    listTahun = listTahun.toSet().toList()..sort();
    listPIC = listPIC.toSet().toList()..sort();
    listKCU = listKCU.toSet().toList()..sort();

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
        height: MediaQuery.of(context).size.height * 0.75,
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
                    decoration: InputDecoration(
                      labelText: 'Tahun',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    value: controller.filterTahun,
                    items: listTahun
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => controller.setFilterDropdown(tahun: v),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'PIC Internal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    value: controller.filterPIC,
                    items: listPIC
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => controller.setFilterDropdown(pic: v),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'KCU / KCP',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    value: controller.filterKCU,
                    items: listKCU
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Text(k, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => controller.setFilterDropdown(kcu: v),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'RENTANG TANGGAL ORDER',
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
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
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

  Widget _buatSideMenuBaru(MandiriController controller, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            width: double.infinity,
            color: navyColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: goldColor,
                  radius: 30,
                  child: Icon(
                    Icons.account_balance,
                    color: navyColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  controller.userEmail.isEmpty
                      ? 'Memuat...'
                      : controller.userEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Akses: ${controller.userRole}',
                    style: TextStyle(
                      color: goldColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildDrawerTitle('NAVIGASI'),
                _buildDrawerItem(Icons.home_rounded, 'Beranda Utama', () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.domain_rounded, 'Pindah ke Bapenda', () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BapendaScreen(),
                    ),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(height: 30),
                ),
                _buildDrawerTitle('AKTIVITAS & BANTUAN'),
                _buildDrawerItem(
                  Icons.history,
                  'Riwayat Aktivitas Notaris',
                  () {
                    Navigator.pop(context);
                    _tampilkanRiwayatLog();
                  },
                  iconColor: Colors.orange,
                ),
                _buildDrawerItem(
                  Icons.settings_outlined,
                  'Pengaturan Target SLA',
                  () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HalamanPengaturan(),
                      ),
                    );
                    controller.inisialisasiData();
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
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: Colors.red.withOpacity(0.05),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Keluar Aplikasi',
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
      leading: Icon(icon, color: iconColor ?? navyColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }

  void _tampilkanDetail(OrderModel item) {
    _catatanCtrl.clear();
    final controller = context.read<MandiriController>();
    String umurStr = 'SELESAI';
    if (item.progres != 'SELESAI' && item.tglOrder != null)
      umurStr = '${DateTime.now().difference(item.tglOrder!).inDays} Hari';
    bool isAdmin = controller.userRole == 'ADMIN';
    bool isPIC = controller.userRole == 'PIC';
    bool canApprove = isAdmin || isPIC;
    bool canEdit = true;

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
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
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
                  'Detail Order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: navyColor,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.green),
                      onPressed: () {
                        String text =
                            "📄 *DETAIL ORDER NOTARIS*\n\n👤 *Debitur:* ${item.debitur}\n🏦 *KCU/KCP:* ${item.kcu}\n⚖️ *Notaris:* ${item.notaris}\n📖 *No. Covernote:* ${item.covernote}\n📑 *Jenis:* ${item.jenis}\n📝 *Rincian:* ${item.rincian}\n💰 *Limit:* Rp ${_formatRupiah(item.limit)}\n🧾 *Biaya:* Rp ${_formatRupiah(item.biaya)}\n\n📌 *Status:* ${item.progres}\n📅 *Tgl Order:* ${_formatTanggal(item.tglOrder)}\n⏳ *Deadline:* ${_formatTanggal(item.deadline)}\n📝 *Catatan:* ${item.note.isEmpty ? '-' : item.note}\n\n👨‍💼 *PIC Internal:* ${item.picInternal}";
                        Share.share(text);
                      },
                    ),
                    if (canEdit)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyColor.withOpacity(0.1),
                          foregroundColor: navyColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormMandiriScreen(
                                dataAwal: item.toMap(),
                                targetSLADefault: controller.targetSLA,
                                userRole: controller.userRole,
                              ),
                            ),
                          );
                          if (res != null)
                            await controller.simpanOrder(res, dataAwal: item);
                        },
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),
            if (item.progres == 'MENUNGGU APPROVAL' && canApprove)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(
                    'APPROVE BERKAS INI',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.purple.shade50,
                    foregroundColor: Colors.purple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await controller.approveBerkas(item.id, item.debitur);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berkas di-Approve!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal melakukan Approve!'),
                        ),
                      );
                    }
                  },
                ),
              ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _barisDetail('Debitur', item.debitur),
                  _barisDetail('Notaris', item.notaris),
                  _barisDetail('KCU/KCP', item.kcu),
                  _barisDetail('PIC Bank', item.picBank),
                  _barisDetail('No Surat', item.noSurat),
                  _barisDetail('No Covernote', item.covernote),
                  _barisDetail('Jenis', item.jenis),
                  _barisDetail('Rincian', item.rincian),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  _barisDetail('Limit', 'Rp ${_formatRupiah(item.limit)}'),
                  _barisDetail('Nilai HT', 'Rp ${_formatRupiah(item.nilaiHT)}'),
                  _barisDetail(
                    'Biaya Notaris',
                    'Rp ${_formatRupiah(item.biaya)}',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  _barisDetail('Tgl Order', _formatTanggal(item.tglOrder)),
                  _barisDetail(
                    'Tgl Pelaksanaan',
                    _formatTanggal(item.tglPelaksanaan),
                  ),
                  _barisDetail('Deadline SLA', _formatTanggal(item.deadline)),
                  _barisDetail('Umur Pekerjaan', umurStr),
                  _barisDetail('Progres', item.progres),
                  _barisDetail('Progres/Ket', item.progresKeterangan),
                  _barisDetail('Tgl BAST', _formatTanggal(item.tglBAST)),
                  _barisDetail('Catatan', item.perKasus),
                  _barisDetail('Kekurangan', item.note),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(thickness: 2),
                  ),
                  Text(
                    'Update Kendala',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _catatanCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Ketik update di sini...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: navyColor),
                          onPressed: () => _tambahHistori(item.id),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('data_notaris')
                        .doc(item.id)
                        .collection('histori')
                        .orderBy('waktu', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      var docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty)
                        return const Text(
                          'Belum ada histori.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var doc = docs[index].data() as Map<String, dynamic>;
                          DateTime? tgl = (doc['waktu'] as Timestamp?)
                              ?.toDate();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: navyColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tgl != null
                                      ? DateFormat(
                                          'dd MMM yyyy • HH:mm',
                                        ).format(tgl)
                                      : 'Baru',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: navyColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  doc['teks'] ?? '-',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _barisDetail('PIC Akad', item.picInternal),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tampilkanRiwayatLog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Aktivitas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: navyColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 30),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('logs_notaris')
                    .orderBy('waktu', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;
                  if (docs.isEmpty) return _buildEmptyLog();
                  return ListView.builder(
                    itemCount: docs.length,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemBuilder: (context, index) => _buildLogItem(
                      docs[index].data() as Map<String, dynamic>,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    String aksi = (log['aksi'] ?? 'INFO').toUpperCase();
    String detail = log['detail'] ?? '-';
    String oleh = log['oleh'] ?? 'Sistem';
    DateTime? waktu = (log['waktu'] as Timestamp?)?.toDate();

    IconData ikon;
    Color warna;
    switch (aksi) {
      case 'TAMBAH':
        ikon = Icons.add_circle_outline;
        warna = Colors.green;
        break;
      case 'EDIT':
        ikon = Icons.edit_note;
        warna = Colors.blue;
        break;
      case 'HAPUS':
        ikon = Icons.delete_forever;
        warna = Colors.red;
        break;
      case 'SELESAI':
        ikon = Icons.check_circle;
        warna = Colors.teal;
        break;
      case 'APPROVE':
        ikon = Icons.verified_user;
        warna = Colors.purple;
        break;
      case 'EXPORT':
        ikon = Icons.file_download;
        warna = Colors.orange;
        break;
      default:
        ikon = Icons.info_outline;
        warna = Colors.grey;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warna.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, color: warna, size: 16),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.grey.withOpacity(0.15),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: warna.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          aksi,
                          style: TextStyle(
                            color: warna,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        waktu != null ? DateFormat('HH:mm').format(waktu) : '-',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            oleh,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (waktu != null)
                        Text(
                          DateFormat('dd MMM yyyy').format(waktu),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLog() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade200),
        const SizedBox(height: 16),
        Text(
          'Belum ada riwayat aktivitas.',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _barisDetail(String label, dynamic nilai) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            nilai?.toString() ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  String _formatTanggal(DateTime? dt, {String fallback = '-'}) {
    if (dt == null) return fallback;
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  String _formatRupiah(String? angkaString) {
    if (angkaString == null || angkaString.isEmpty) return '0';
    try {
      return NumberFormat.currency(
        locale: 'id',
        symbol: '',
        decimalDigits: 0,
      ).format(int.parse(angkaString));
    } catch (e) {
      return angkaString;
    }
  }
}
