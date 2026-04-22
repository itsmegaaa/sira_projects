// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sira_projects/controllers/sertifikat_controller.dart';
import 'package:sira_projects/ui/widgets/stat_pill.dart';
import 'package:sira_projects/ui/screens/form/form_sertifikat_screen.dart';
import 'package:sira_projects/ui/screens/dashboard/log_sertifikat_screen.dart';
import 'package:sira_projects/ui/widgets/custom_drawer.dart'; // Import Drawer
import 'package:sira_projects/ui/widgets/expandable_fab.dart'; // Import FAB Baru
import 'package:sira_projects/controllers/user_provider.dart';

class SertifikatScreen extends StatefulWidget {
  const SertifikatScreen({super.key});
  @override
  State<SertifikatScreen> createState() => _SertifikatScreenState();
}

class _SertifikatScreenState extends State<SertifikatScreen> {
  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SertifikatController>().inisialisasiData();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<SertifikatController>();
    Color currentBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF8FAFC);
    Color currentSurface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color currentText = isDark ? Colors.white : navyColor;

    int totalInternal = 0, totalEksternal = 0, totalSelesai = 0;
    for (var item in controller.daftarSertifikat) {
      if (item.status.toUpperCase() == 'SELESAI') {
        totalSelesai++;
      } else {
        if (item.pemegangBerkas.isNotEmpty) totalInternal++;
        if (item.klewis.isNotEmpty) totalEksternal++;
      }
    }

    return Scaffold(
      backgroundColor: currentBg,
      drawer: const CustomDrawer(activeRoute: 'SERTIFIKAT'),
      appBar: AppBar(
        backgroundColor: currentSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: currentText),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MONITORING SERTIFIKAT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: currentText,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Pelacakan Fisik Berkas SHM',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: controller.isLoading
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : Column(
              children: [
                Container(
                  color: currentSurface,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            StatPill(
                              judul: 'Di Internal',
                              angka: totalInternal,
                              warna: Colors.blue,
                              isAktif: controller.filterLokasi == 'INTERNAL',
                              ikon: Icons.business_center,
                              isDark: isDark,
                              onTap: () =>
                                  controller.setFilterLokasi('INTERNAL'),
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              judul: 'Di Eksternal',
                              angka: totalEksternal,
                              warna: Colors.orange,
                              isAktif: controller.filterLokasi == 'EKSTERNAL',
                              ikon: Icons.local_shipping,
                              isDark: isDark,
                              onTap: () =>
                                  controller.setFilterLokasi('EKSTERNAL'),
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              judul: 'Selesai',
                              angka: totalSelesai,
                              warna: Colors.green,
                              isAktif: controller.filterLokasi == 'SELESAI',
                              ikon: Icons.task_alt,
                              isDark: isDark,
                              onTap: () =>
                                  controller.setFilterLokasi('SELESAI'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              hintText: 'Cari No Sertifikat, Desa, Pemilik...',
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
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.filteredData.length,
                    itemBuilder: (context, index) {
                      final item = controller.filteredData[index];
                      bool isSelesai = item.status.toUpperCase() == 'SELESAI';
                      bool isTelat = controller.cekTelat(item);
                      int sisaHari = controller.hitungSisaHari(item);
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          final roleAsli = context.read<UserProvider>().role;
                          if (roleAsli.toUpperCase() != 'ADMIN' &&
                              roleAsli.toUpperCase() != 'PIC') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Akses Ditolak: Hanya Admin dan PIC yang dapat menghapus data',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return false;
                          }
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  "Konfirmasi Hapus",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  "Apakah Anda yakin ingin menghapus data sertifikat milik ${item.pemilik}?",
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text(
                                      "Batal",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      "Hapus",
                                      style: TextStyle(
                                        color: Colors.white,
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
                            await controller.hapusData(item.id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Data sertifikat berhasil dihapus',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menghapus: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: InkWell(
                          onTap: () {
                            final dataEdit = item.toMap();
                            dataEdit['id'] = item.id;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FormSertifikatScreen(dataAwal: dataEdit),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: currentSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: isDark
                                  ? Border.all(color: Colors.grey.shade800)
                                  : null,
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isSelesai
                                                    ? Colors.green
                                                    : (isTelat
                                                          ? Colors.red
                                                          : Colors.blue))
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isSelesai
                                            ? 'SELESAI'
                                            : (isTelat
                                                  ? 'TELAT SLA'
                                                  : '${item.typeSertifikat} - SISA $sisaHari HARI'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelesai
                                              ? Colors.green
                                              : (isTelat
                                                    ? Colors.red
                                                    : Colors.blue),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.bank,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No. ${item.noSertifikat.isEmpty ? '-' : item.noSertifikat}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: currentText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.pemilik} • Desa ${item.desa}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Posisi Eksternal (Klewis)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.klewis.isEmpty
                                              ? '-'
                                              : item.klewis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: currentText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Posisi Internal (Staff)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.pemegangBerkas.isEmpty
                                              ? '-'
                                              : item.pemegangBerkas,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: goldColor,
                                          ),
                                        ),
                                      ],
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
      // GUNAKAN EXPANDABLE FAB
      floatingActionButton: ExpandableFab(
        distance: 100.0,
        children: [
          ActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LogSertifikatScreen(),
              ),
            ),
            icon: const Icon(Icons.history_rounded),
            color: Colors.orange,
          ),
          ActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FormSertifikatScreen(),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
