import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, WriteBatch;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:gabut_tracker/core/utils/notifikasi_service.dart';
import 'package:gabut_tracker/data/repositories/mandiri_repository.dart';
import 'package:gabut_tracker/data/models/mandiri_model.dart'; // IMPORT MODEL

class MandiriController extends ChangeNotifier {
  final MandiriRepository _repo;
  MandiriController({required MandiriRepository repo}) : _repo = repo;

  StreamSubscription? _streamSub;
  List<OrderModel> daftarOrder = []; // MENGGUNAKAN MODEL
  bool sedangMemuat = true;
  bool sedangProsesEkspor = false;

  String filterStatus = 'SEMUA';
  String filterTahun = 'SEMUA';
  String filterPIC = 'SEMUA';
  String filterKCU = 'SEMUA';
  String kataKunciPencarian = '';
  DateTime? filterTanggalMulai;
  DateTime? filterTanggalAkhir;

  String userRole = 'STAFF';
  String userEmail = '';
  String namaPICUser = '';
  int targetSLA = 30;

  Future<void> inisialisasiData() async {
    sedangMemuat = true;
    notifyListeners();
    await _muatPengaturanLokal();
    await _cekRoleUser();
    _mulaiMendengarkanCloud();
  }

  Future<void> _muatPengaturanLokal() async {
    final prefs = await SharedPreferences.getInstance();
    targetSLA = prefs.getInt('target_sla') ?? 30;
    notifyListeners();
  }

  Future<void> _cekRoleUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email ?? '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .get();
        if (doc.exists && doc.data() != null) {
          userRole = doc.data()!['role'] ?? 'STAFF';
          namaPICUser = doc.data()!['nama_pic'] ?? '';
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Gagal cek role: $e");
      }
    }
  }

  void _mulaiMendengarkanCloud() {
    _streamSub?.cancel();

    _streamSub = _repo
        .streamDataNotaris(limit: 200)
        .listen(
          (snapshot) async {
            // DESERIALISASI KE MODEL
            daftarOrder = snapshot.docs
                .map((doc) => OrderModel.fromFirestore(doc))
                .toList();
            sedangMemuat = false;
            notifyListeners();

            int jumlahWarning = 0, jumlahTelat = 0;
            for (var item in daftarOrder) {
              if (item.progres != 'SELESAI') {
                int sisa = hitungSisaHari(item);
                if (sisa < 0)
                  jumlahTelat++;
                else if (sisa <= 3)
                  jumlahWarning++;
              }
            }

            if (jumlahWarning > 0 || jumlahTelat > 0) {
              final prefs = await SharedPreferences.getInstance();
              String tglTerakhirNotif = prefs.getString('terakhir_notif') ?? '';
              String tglHariIni = DateTime.now().toString().substring(0, 10);
              if (tglTerakhirNotif != tglHariIni) {
                await NotifikasiService.tampilkanNotif(
                  '⚠️ Laporan Notaris',
                  'Ada $jumlahWarning berkas H-3 SLA dan $jumlahTelat berkas TELAT.',
                );
                await prefs.setString('terakhir_notif', tglHariIni);
              }
            }
          },
          onError: (e) {
            sedangMemuat = false;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> catatAktivitas(String aksi, String detail) async {
    await _repo.catatAktivitas(aksi, detail, userEmail);
  }

  // ===========================================================================
  // FUNGSI SIMPAN ORDER DENGAN CCTV (DIFF CHECKER)
  // ===========================================================================
  Future<void> simpanOrder(
    Map<String, dynamic> dataBaru, {
    OrderModel? dataAwal,
  }) async {
    await _repo.simpanOrder(dataBaru);

    String aksi = dataAwal == null ? 'TAMBAH' : 'EDIT';
    String detail = '';

    if (dataAwal == null) {
      detail =
          'Menambahkan data Mandiri baru atas nama: ${dataBaru['debitur']}';
    } else {
      List<String> kolomBerubah = [];

      // Deteksi perubahan kolom
      if (dataAwal.debitur != dataBaru['debitur']) kolomBerubah.add('Debitur');
      if (dataAwal.notaris != dataBaru['notaris']) kolomBerubah.add('Notaris');
      if (dataAwal.noSurat != dataBaru['noSurat']) kolomBerubah.add('No Surat');
      if (dataAwal.covernote != dataBaru['covernote'])
        kolomBerubah.add('Covernote');
      if (dataAwal.rincian != dataBaru['rincian']) kolomBerubah.add('Rincian');
      if (dataAwal.limit != dataBaru['limit']) kolomBerubah.add('Limit');
      if (dataAwal.nilaiHT != dataBaru['nilaiHT']) kolomBerubah.add('Nilai HT');
      if (dataAwal.biaya != dataBaru['biaya']) kolomBerubah.add('Biaya');
      if (dataAwal.progresKeterangan != dataBaru['progresKeterangan'])
        kolomBerubah.add('Ket. Progres');
      if (dataAwal.perKasus != dataBaru['perKasus'])
        kolomBerubah.add('Per Kasus');
      if (dataAwal.note != dataBaru['note'])
        kolomBerubah.add('Note/Kekurangan');
      if (dataAwal.picBank != dataBaru['picBank']) kolomBerubah.add('PIC Bank');
      if (dataAwal.kcu != dataBaru['kcu']) kolomBerubah.add('KCU');
      if (dataAwal.picInternal != dataBaru['picInternal'])
        kolomBerubah.add('PIC Internal');
      if (dataAwal.jenis != dataBaru['jenis']) kolomBerubah.add('Jenis');
      if (dataAwal.progres != dataBaru['progres']) kolomBerubah.add('Progres');

      // Helper untuk format tanggal aman
      String formatIso(DateTime? dt) => dt?.toIso8601String() ?? '';

      if (formatIso(dataAwal.tglOrder) != dataBaru['tglOrder'])
        kolomBerubah.add('Tgl Order');
      if (formatIso(dataAwal.tglPelaksanaan) != dataBaru['tglPelaksanaan'])
        kolomBerubah.add('Tgl Pelaksanaan');
      if (formatIso(dataAwal.deadline) != dataBaru['deadline'])
        kolomBerubah.add('Deadline');
      if (formatIso(dataAwal.tglBAST) != dataBaru['tglBAST'])
        kolomBerubah.add('Tgl BAST');

      if (kolomBerubah.isNotEmpty) {
        detail =
            'Mengedit berkas ${dataAwal.debitur}. Kolom yang dirubah: ${kolomBerubah.join(', ')}';
      } else {
        detail =
            'Mengedit berkas ${dataAwal.debitur} (Tanpa ada perubahan data)';
      }
    }
    await catatAktivitas(aksi, detail);
  }

  Future<void> tandaiSelesai(String id, String debitur) async {
    await _repo.updateProgres(id, 'SELESAI');
    await catatAktivitas('SELESAI', 'Menyelesaikan berkas: $debitur');
  }

  Future<void> approveBerkas(String id, String debitur) async {
    await _repo.updateProgres(id, 'PROSES');
    await catatAktivitas('APPROVE', 'Meng-approve data: $debitur');
  }

  Future<void> hapusData(String id, String debitur) async {
    await _repo.hapusData(id);
    await catatAktivitas('HAPUS', 'Menghapus data: $debitur');
  }

  Future<void> tambahHistori(String id, String teks) async {
    await _repo.tambahHistori(id, teks);
    await catatAktivitas('EDIT', 'Update kendala histori pada sebuah berkas');
  }

  // --- LOGIKA HITUNG UMUR DENGAN MODEL ---
  int hitungSisaHari(OrderModel item) {
    if (item.progres == 'SELESAI' || item.deadline == null) return 999;
    DateTime now = DateTime.now();
    return DateTime(
      item.deadline!.year,
      item.deadline!.month,
      item.deadline!.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool cekTelat(OrderModel item) {
    if (item.progres == 'SELESAI' || item.deadline == null) return false;
    return DateTime.now().isAfter(
      DateTime(
        item.deadline!.year,
        item.deadline!.month,
        item.deadline!.day,
        23,
        59,
        59,
      ),
    );
  }

  void setKataKunci(String kata) {
    kataKunciPencarian = kata;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    filterStatus = filterStatus == status ? 'SEMUA' : status;
    notifyListeners();
  }

  void setFilterDropdown({String? tahun, String? pic, String? kcu}) {
    if (tahun != null) filterTahun = tahun;
    if (pic != null) filterPIC = pic;
    if (kcu != null) filterKCU = kcu;
    notifyListeners();
  }

  void setRentangTanggal(DateTime? mulai, DateTime? akhir) {
    filterTanggalMulai = mulai;
    filterTanggalAkhir = akhir;
    notifyListeners();
  }

  void resetFilter() {
    filterStatus = 'SEMUA';
    filterTahun = 'SEMUA';
    filterPIC = 'SEMUA';
    filterKCU = 'SEMUA';
    filterTanggalMulai = null;
    filterTanggalAkhir = null;
    notifyListeners();
  }

  // --- FILTER MENGGUNAKAN MODEL ---
  List<OrderModel> get filteredData {
    List<OrderModel> filtered = daftarOrder.where((item) {
      String s = kataKunciPencarian.toLowerCase();
      bool mSearch =
          item.debitur.toLowerCase().contains(s) ||
          item.noSurat.toLowerCase().contains(s) ||
          item.kcu.toLowerCase().contains(s);

      bool isSelesai = item.progres == 'SELESAI';
      bool isMenunggu = item.progres == 'MENUNGGU APPROVAL';
      bool matchesTahun =
          filterTahun == 'SEMUA' ||
          (item.tglOrder != null &&
              item.tglOrder!.year.toString() == filterTahun);
      bool matchesPIC = filterPIC == 'SEMUA' || item.picInternal == filterPIC;
      bool matchesKCU = filterKCU == 'SEMUA' || item.kcu == filterKCU;
      bool matchesRentangTanggal = true;

      if (filterTanggalMulai != null && filterTanggalAkhir != null) {
        DateTime tglCek = item.tglOrder ?? DateTime.now();
        tglCek = DateTime(tglCek.year, tglCek.month, tglCek.day);
        DateTime start = DateTime(
          filterTanggalMulai!.year,
          filterTanggalMulai!.month,
          filterTanggalMulai!.day,
        );
        DateTime end = DateTime(
          filterTanggalAkhir!.year,
          filterTanggalAkhir!.month,
          filterTanggalAkhir!.day,
        );
        matchesRentangTanggal =
            (tglCek.isAfter(start) || tglCek.isAtSameMomentAs(start)) &&
            (tglCek.isBefore(end) || tglCek.isAtSameMomentAs(end));
      }

      if (filterStatus == "SELESAI" && !isSelesai) return false;
      if (filterStatus == "APPROVAL" && !isMenunggu) return false;
      if (filterStatus == "PROSES" &&
          (isSelesai || isMenunggu || cekTelat(item)))
        return false;
      if (filterStatus == "TELAT" && !cekTelat(item)) return false;

      return mSearch &&
          matchesTahun &&
          matchesPIC &&
          matchesKCU &&
          matchesRentangTanggal;
    }).toList();

    filtered.sort((a, b) {
      int getPriority(OrderModel item) {
        if (item.progres == "MENUNGGU APPROVAL") return 0;
        if (cekTelat(item)) return 1;
        if (item.progres == "SELESAI") return 3;
        return 2;
      }

      int priorityA = getPriority(a), priorityB = getPriority(b);
      if (priorityA != priorityB) return priorityA.compareTo(priorityB);
      return (a.tglOrder ?? DateTime.now()).compareTo(
        b.tglOrder ?? DateTime.now(),
      );
    });
    return filtered;
  }

  Future<int> imporExcel(PlatformFile fileInfo) async {
    var bytes = await File(fileInfo.path!).readAsBytes();
    var excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) throw Exception("File kosong");

    WriteBatch batch = _repo.getBatch();
    int count = 0;

    for (int i = 1; i < excel.tables.values.first.rows.length; i++) {
      var row = excel.tables.values.first.rows[i];
      if (row.isEmpty || row[0] == null) continue;

      String idBaru = _repo.getDocRef('temp').parent.doc().id;
      String safeStr(int index) =>
          (index < row.length && row[index]?.value != null)
          ? row[index]!.value.toString().trim()
          : '';
      String? parseDate(int index) {
        String s = safeStr(index);
        if (s.isEmpty || s == '-') return null;
        try {
          return DateTime.parse(s).toIso8601String();
        } catch (e) {
          return null;
        }
      }

      String getNum(int index) {
        String s = safeStr(index).replaceAll(RegExp(r'[^0-9]'), '');
        return s.isEmpty ? '0' : s;
      }

      String prog = safeStr(15).toUpperCase();
      prog = ['SELESAI', 'PENDING', 'MENUNGGU APPROVAL'].contains(prog)
          ? prog
          : 'PROSES';

      String? strTglOrder = parseDate(5);
      DateTime tglUntukKode = DateTime.now();
      if (strTglOrder != null) {
        try {
          tglUntukKode = DateTime.parse(strTglOrder);
        } catch (_) {}
      }
      String tglStr = DateFormat('yyyy-MM-dd').format(tglUntukKode);
      String kodeUnik = "${safeStr(0).toLowerCase()}_$tglStr";

      batch.set(_repo.getDocRef(idBaru), {
        'id': idBaru,
        'kode_duplikat': kodeUnik,
        'debitur': safeStr(0),
        'notaris': safeStr(1),
        'kcu': safeStr(2),
        'picBank': safeStr(3),
        'noSurat': safeStr(4),
        'tglOrder': strTglOrder,
        'jenis': safeStr(6),
        'rincian': safeStr(7),
        'covernote': safeStr(8),
        'limit': getNum(9),
        'nilaiHT': getNum(10),
        'biaya': getNum(11),
        'tglPelaksanaan': parseDate(12),
        'deadline': parseDate(13),
        'progres': prog,
        'progresKeterangan': safeStr(16),
        'tglBAST': parseDate(17),
        'perKasus': safeStr(18),
        'note': safeStr(19),
        'picInternal': safeStr(20),
      });
      count++;
      if (count % 400 == 0) {
        await batch.commit();
        batch = _repo.getBatch();
      }
    }
    await batch.commit();
    await catatAktivitas('TAMBAH', 'Impor massal $count data Excel');
    return count;
  }

  Future<void> eksporDanBagikanCSV() async {
    try {
      sedangProsesEkspor = true;
      notifyListeners();

      String csvData =
          "DEBITUR,Nama Notaris,KCU/KCP,PIC,No. Surat Order,Tgl. Order,Jenis,Rincian Order,No. Covernote,Limit,Nilai HT,Biaya,Tgl. Pelaksanaan,Batas SLA Laporan,Umur Pekerjaan,Progres Pekerjaan,PROGRES/KETERANGAN,TANGGAL BAST,Per kasus,PIC AKAD\n";
      String escapeCsv(String? value) {
        if (value == null) return '';
        String sanitized = value.replaceAll('"', '""');
        return (sanitized.contains(',') || sanitized.contains('\n'))
            ? '"$sanitized"'
            : sanitized;
      }

      for (var item in filteredData) {
        String strUmur = item.progres == 'SELESAI'
            ? 'SELESAI'
            : (item.tglOrder != null
                  ? '${DateTime.now().difference(item.tglOrder!).inDays} Hari'
                  : 'Tak Diketahui');
        String formatTgl(DateTime? dt) =>
            dt != null ? DateFormat('dd/MM/yyyy').format(dt) : '-';

        csvData +=
            "${escapeCsv(item.debitur)},${escapeCsv(item.notaris)},${escapeCsv(item.kcu)},${escapeCsv(item.picBank)},${escapeCsv(item.noSurat)},${formatTgl(item.tglOrder)},${escapeCsv(item.jenis)},${escapeCsv(item.rincian)},${escapeCsv(item.covernote)},${item.limit},${item.nilaiHT},${item.biaya},${formatTgl(item.tglPelaksanaan)},${formatTgl(item.deadline)},$strUmur,${escapeCsv(item.progres)},${escapeCsv(item.progresKeterangan)},${formatTgl(item.tglBAST)},${escapeCsv(item.perKasus)},${escapeCsv(item.picInternal)}\n";
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Laporan_Tracker.csv');
      await file.writeAsString(csvData);

      sedangProsesEkspor = false;
      notifyListeners();

      await Share.shareXFiles([XFile(file.path)]);
      await catatAktivitas('EXPORT', 'Mengekspor laporan ke CSV');
    } catch (e) {
      sedangProsesEkspor = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> eksporDanBagikanPDF() async {
    try {
      sedangProsesEkspor = true;
      notifyListeners();

      final pdf = pw.Document();
      final dataList = daftarOrder
          .where((item) => item.progres != 'SELESAI')
          .toList();
      dataList.sort(
        (a, b) => (b.tglOrder ?? DateTime.now()).compareTo(
          a.tglOrder ?? DateTime.now(),
        ),
      );

      String formatDateSafe(DateTime? dt) =>
          dt != null ? DateFormat('dd/MM/yyyy').format(dt) : '-';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "LAPORAN TRACKER NOTARIS (OUTSTANDING)",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "Daftar Pekerjaan Belum Selesai (Proses & Telat)",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Text(
                    "Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.TableHelper.fromTextArray(
              headers: [
                'NAMA DEBITUR',
                'KCU / KCP',
                'JENIS ORDER',
                'TGL ORDER',
                'STATUS PROGRESS',
                'PER KASUS',
                'PIC INTERNAL',
                'CATATAN',
              ],
              data: dataList.map((item) {
                bool isTelat = cekTelat(item);
                String status = item.progres;
                if (isTelat) status = "TELAT ($status)";
                return [
                  item.debitur.toUpperCase(),
                  item.kcu.replaceAll('Micro Garut ', ''),
                  item.jenis,
                  formatDateSafe(item.tglOrder),
                  status,
                  item.perKasus,
                  item.picInternal,
                  '',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey900,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.4),
                1: const pw.FlexColumnWidth(1.4),
                2: const pw.FlexColumnWidth(1.1),
                3: const pw.FlexColumnWidth(0.9),
                4: const pw.FlexColumnWidth(1.1),
                5: const pw.FlexColumnWidth(2.3),
                6: const pw.FlexColumnWidth(1.0),
                7: const pw.FlexColumnWidth(2.0),
              },
            ),
            pw.SizedBox(height: 15),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Total Dokumen: ${dataList.length} Berkas",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Laporan_Outstanding_Notaris.pdf');
      await file.writeAsBytes(await pdf.save(), flush: true);

      sedangProsesEkspor = false;
      notifyListeners();

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Laporan Outstanding Notaris');
      await catatAktivitas('EXPORT', 'Mengekspor laporan PDF (Outstanding)');
    } catch (e) {
      sedangProsesEkspor = false;
      notifyListeners();
      throw Exception("Gagal membuat PDF.");
    }
  }
}
