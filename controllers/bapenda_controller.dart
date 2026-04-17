import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart'; // Tambahan untuk deteksi email

import 'package:gabut_tracker/data/repositories/bapenda_repository.dart';
import 'package:gabut_tracker/data/models/bapenda_model.dart';

class BapendaController extends ChangeNotifier {
  final BapendaRepository _repo;
  BapendaController({required BapendaRepository repo}) : _repo = repo;

  StreamSubscription? _streamSub;

  List<BapendaModel> listBapenda = [];
  List<BapendaModel> listFiltered = [];
  bool sedangMemuat = true;
  bool sedangProsesEkspor = false;

  // --- VARIABEL FILTER ---
  String kataKunci = '';
  String filterDeveloper = 'SEMUA';
  String filterProgresBphtb = 'SEMUA';
  DateTime? filterTanggalMulai;
  DateTime? filterTanggalAkhir;

  void mulaiListen() {
    sedangMemuat = true;
    notifyListeners();

    _streamSub?.cancel();

    _streamSub = _repo
        .streamPekerjaan(limit: 200)
        .listen(
          (snapshot) {
            listBapenda = snapshot.docs
                .map((doc) => BapendaModel.fromFirestore(doc))
                .toList();
            _terapkanFilter();
            sedangMemuat = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Error Bapenda: $e");
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

  void cariData(String teks) {
    kataKunci = teks.toLowerCase();
    _terapkanFilter();
  }

  void setFilterDropdown({String? developer, String? progres}) {
    if (developer != null) filterDeveloper = developer;
    if (progres != null) filterProgresBphtb = progres;
    _terapkanFilter();
  }

  void setRentangTanggal(DateTime? mulai, DateTime? akhir) {
    filterTanggalMulai = mulai;
    filterTanggalAkhir = akhir;
    _terapkanFilter();
  }

  void resetFilter() {
    kataKunci = '';
    filterDeveloper = 'SEMUA';
    filterProgresBphtb = 'SEMUA';
    filterTanggalMulai = null;
    filterTanggalAkhir = null;
    _terapkanFilter();
  }

  void _terapkanFilter() {
    listFiltered = listBapenda.where((item) {
      bool matchSearch =
          kataKunci.isEmpty ||
          item.namaDebitur.toLowerCase().contains(kataKunci) ||
          item.developer.toLowerCase().contains(kataKunci);

      bool matchDeveloper =
          filterDeveloper == 'SEMUA' ||
          item.developer.trim() == filterDeveloper;
      bool matchProgres =
          filterProgresBphtb == 'SEMUA' ||
          item.progresBphtb.trim() == filterProgresBphtb;

      bool matchTanggal = true;
      if (filterTanggalMulai != null && filterTanggalAkhir != null) {
        try {
          if (item.tglBayar.isNotEmpty && item.tglBayar.contains('-')) {
            List<String> parts = item.tglBayar.split('-');
            if (parts.length == 3) {
              DateTime tgl = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
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
              matchTanggal =
                  (tgl.isAfter(start) || tgl.isAtSameMomentAs(start)) &&
                  (tgl.isBefore(end) || tgl.isAtSameMomentAs(end));
            } else {
              matchTanggal = false;
            }
          } else {
            matchTanggal = false;
          }
        } catch (e) {
          matchTanggal = false;
        }
      }

      return matchSearch && matchDeveloper && matchProgres && matchTanggal;
    }).toList();

    notifyListeners();
  }

  // ===========================================================================
  // FUNGSI CRUD & LOGIKA PENCATATAN LOG (RIWAYAT)
  // ===========================================================================
  Future<void> hapusData(BapendaModel item) async {
    await _repo.hapusPekerjaan(item.id);

    // Pencatatan Log Hapus
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Sistem';
    await _repo.catatAktivitas(
      'HAPUS',
      'Menghapus data Bapenda: ${item.namaDebitur}',
      userEmail,
    );
  }

  Future<void> simpanData(
    Map<String, dynamic> dataBaru, {
    BapendaModel? dataAwal,
  }) async {
    // Simpan ke database
    await _repo.simpanPekerjaan(dataBaru);

    // Pencatatan Log Tambah/Edit
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Sistem';
    String aksi = dataAwal == null ? 'TAMBAH' : 'EDIT';
    String detail = '';

    if (dataAwal == null) {
      detail =
          'Menambahkan data Bapenda baru atas nama: ${dataBaru['namaDebitur']}';
    } else {
      // Deteksi perubahan kolom (Diff Check)
      List<String> kolomBerubah = [];
      if (dataAwal.namaDebitur != dataBaru['namaDebitur'])
        kolomBerubah.add('Nama Debitur');
      if (dataAwal.developer != dataBaru['developer'])
        kolomBerubah.add('Developer');
      if (dataAwal.tglBayar != dataBaru['tglBayar'])
        kolomBerubah.add('Tanggal Bayar');
      if (dataAwal.nilaiBphtb != dataBaru['nilaiBphtb'])
        kolomBerubah.add('Nilai BPHTB');
      if (dataAwal.progresBphtb != dataBaru['progresBphtb'])
        kolomBerubah.add('Progres BPHTB');
      if (dataAwal.setorBphtb != dataBaru['setorBphtb'])
        kolomBerubah.add('Setor BPHTB');
      if (dataAwal.nilaiPph != dataBaru['nilaiPph'])
        kolomBerubah.add('Nilai PPH');
      if (dataAwal.progresPph != dataBaru['progresPph'])
        kolomBerubah.add('Progres PPH');
      if (dataAwal.setorPph != dataBaru['setorPph'])
        kolomBerubah.add('Setor PPH');
      if (dataAwal.nilaiJualBeli != dataBaru['nilaiJualBeli'])
        kolomBerubah.add('Nilai Jual Beli');
      if (dataAwal.ntpnPph != dataBaru['ntpnPph']) kolomBerubah.add('NTPN');
      if (dataAwal.jenisSertifikat != dataBaru['jenisSertifikat'])
        kolomBerubah.add('Jenis Sertifikat');
      if (dataAwal.jenisPph != dataBaru['jenisPph'])
        kolomBerubah.add('Jenis PPH');

      if (kolomBerubah.isNotEmpty) {
        detail =
            'Mengedit berkas ${dataAwal.namaDebitur}. Kolom yang dirubah: ${kolomBerubah.join(', ')}';
      } else {
        detail =
            'Mengedit berkas ${dataAwal.namaDebitur} (Tanpa ada perubahan data)';
      }
    }

    await _repo.catatAktivitas(aksi, detail, userEmail);
  }

  Future<int> imporExcelBapenda(PlatformFile fileInfo) async {
    var bytes = await File(fileInfo.path!).readAsBytes();
    var excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) throw Exception("File Excel kosong");

    var batch = _repo.getBatch();
    int count = 0;

    for (int i = 1; i < excel.tables.values.first.rows.length; i++) {
      var row = excel.tables.values.first.rows[i];
      if (row.isEmpty || row.length < 2 || row[1]?.value == null) continue;

      String idBaru = _repo.getDocRef('temp').parent.doc().id;
      String safeStr(int index) =>
          (index < row.length && row[index]?.value != null)
          ? row[index]!.value.toString().trim()
          : '';

      batch.set(_repo.getDocRef(idBaru), {
        'id': idBaru,
        'waktuUpdate': FieldValue.serverTimestamp(),
        'namaDebitur': safeStr(1),
        'developer': safeStr(2),
        'tglBayar': safeStr(3),
        'nilaiBphtb': safeStr(4),
        'progresBphtb': safeStr(5).isEmpty ? 'Proses' : safeStr(5),
        'setorBphtb': safeStr(6),
        'nilaiPph': safeStr(7),
        'progresPph': safeStr(8),
        'setorPph': safeStr(9),
        'nilaiJualBeli': safeStr(10),
        'ntpnPph': safeStr(11),
        'sumber': safeStr(12),
      });
      count++;
      if (count % 400 == 0) {
        await batch.commit();
        batch = _repo.getBatch();
      }
    }
    await batch.commit();
    return count;
  }

  Future<void> eksporDanBagikanCSV() async {
    try {
      sedangProsesEkspor = true;
      notifyListeners();

      String csvData =
          "NO,NAMA DEBITUR,DEVELOPER,TANGGAL BAYAR,NILAI BPHTB,PROGRESS BPHTB,SETOR BPHTB,NILAI PPH,PROGRES PPH,SETOR PPH,NO NTPN PPH\n";

      String escapeCsv(String? value) {
        if (value == null) return '';
        String sanitized = value.replaceAll('"', '""');
        return (sanitized.contains(',') || sanitized.contains('\n'))
            ? '"$sanitized"'
            : sanitized;
      }

      int no = 1;
      for (var item in listFiltered) {
        csvData +=
            "${no++},"
            "${escapeCsv(item.namaDebitur)},"
            "${escapeCsv(item.developer)},"
            "${escapeCsv(item.tglBayar)},"
            "${escapeCsv(item.nilaiBphtb)},"
            "${escapeCsv(item.progresBphtb)},"
            "${escapeCsv(item.setorBphtb)},"
            "${escapeCsv(item.nilaiPph)},"
            "${escapeCsv(item.progresPph)},"
            "${escapeCsv(item.setorPph)},"
            "${escapeCsv(item.ntpnPph)}\n";
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Laporan_Bapenda.csv');
      await file.writeAsString(csvData);

      sedangProsesEkspor = false;
      notifyListeners();

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Laporan Bapenda (CSV)');
    } catch (e) {
      sedangProsesEkspor = false;
      notifyListeners();
      debugPrint("Error CSV Bapenda: $e");
      rethrow;
    }
  }

  Future<void> eksporDanBagikanPDF() async {
    try {
      sedangProsesEkspor = true;
      notifyListeners();

      final pdf = pw.Document();
      int no = 1;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(15),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "LAPORAN BAPENDA",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                'NO',
                'DEBITUR',
                'DEVELOPER',
                'TGL BAYAR',
                'NILAI B',
                'PROG B',
                'SETOR B',
                'NILAI P',
                'PROG P',
                'SETOR P',
                'NTPN',
              ],
              data: listFiltered.map((item) {
                return [
                  no++,
                  item.namaDebitur.toUpperCase(),
                  item.developer,
                  item.tglBayar.isEmpty ? '-' : item.tglBayar,
                  item.nilaiBphtb,
                  item.progresBphtb,
                  item.setorBphtb,
                  item.nilaiPph,
                  item.progresPph,
                  item.setorPph,
                  item.ntpnPph,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 6,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey900,
              ),
              cellStyle: const pw.TextStyle(fontSize: 6),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(4),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),
                1: const pw.FlexColumnWidth(2.0),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.0),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.0),
                6: const pw.FlexColumnWidth(1.2),
                7: const pw.FlexColumnWidth(1.2),
                8: const pw.FlexColumnWidth(1.0),
                9: const pw.FlexColumnWidth(1.2),
                10: const pw.FlexColumnWidth(1.5),
              },
            ),
            pw.SizedBox(height: 15),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Total Dokumen: ${listFiltered.length} Berkas",
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
      final file = File('${dir.path}/Laporan_Bapenda.pdf');

      final bytes = await pdf.save();
      await file.writeAsBytes(bytes, flush: true);

      sedangProsesEkspor = false;
      notifyListeners();

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Laporan Bapenda PDF');
    } catch (e) {
      sedangProsesEkspor = false;
      notifyListeners();
      debugPrint("CRASH PDF BAPENDA: $e");
      throw Exception("Gagal membuat PDF. Pastikan data valid.");
    }
  }
}
