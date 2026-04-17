import 'package:flutter/material.dart';
import 'package:sira_projects/data/repositories/mandiri_repository.dart';

class FormMandiriController extends ChangeNotifier {
  final MandiriRepository repo;
  FormMandiriController({required this.repo});

  bool isLoading = true;

  // --- CONTROLLER TEKS ---
  final debiturCtrl = TextEditingController();
  final notarisCtrl = TextEditingController();
  final noSuratCtrl = TextEditingController();
  final covernoteCtrl = TextEditingController();
  final rincianCtrl = TextEditingController();
  final limitCtrl = TextEditingController();
  final nilaiHTCtrl = TextEditingController();
  final biayaCtrl = TextEditingController();
  final progresKeteranganCtrl = TextEditingController();
  final perKasusCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final picBankCtrl = TextEditingController();

  // --- VARIABEL TANGGAL ---
  DateTime? tglOrder, tglPelaksanaan, deadline, tglBAST;

  // --- VARIABEL DROPDOWN & MASTER DATA ---
  List<String> listKcu = [];
  Map<String, String> mapKcuPicBank = {}; // Untuk Auto-fill PIC Bank
  String? kcuPilihan;

  List<String> listPicInternal = [];
  String? picInternalPilihan;

  List<String> listJenisOrder = [
    'SKMHT',
    'APHT',
    'AJB',
    'ROYA',
    'FIDUSIA',
    'SHT',
    'LAINNYA',
  ];
  String? jenisPilihan;

  List<String> listProgres = [
    'DRAFT',
    'PROSES',
    'MENUNGGU APPROVAL',
    'PENDING',
    'SELESAI',
    'BATAL',
  ];
  String progresPilihan = 'PROSES';

  List<String> saranNotaris = [];

  // ===========================================================================
  // INISIALISASI DATA (MASTER DATA + DATA EDIT)
  // ===========================================================================
  Future<void> inisialisasiData(
    Map<String, dynamic>? dataAwal,
    int targetSLA,
  ) async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Tarik Master Data dari Firebase
      // Kami menggunakan getMasterDataMap untuk menangani struktur Key-Value pada KCU
      final resKcu = await repo.getMasterDataMap('kcu');
      final resPic = await repo.getMasterDataMap('pic');
      final resNotaris = await repo.getMasterDataMap('notaris');

      // Proses Master Data KCU (Format: { "Nama KCU": "Nama PIC Bank" })
      if (resKcu.isNotEmpty) {
        mapKcuPicBank = resKcu.map(
          (key, value) => MapEntry(key.trim(), value.toString().trim()),
        );
        listKcu = mapKcuPicBank.keys.toList()..sort();
      }

      // Proses Master Data PIC & Notaris (Format: { "daftar": [...] })
      if (resPic.containsKey('daftar')) {
        listPicInternal = List<String>.from(resPic['daftar'])..sort();
      }
      if (resNotaris.containsKey('daftar')) {
        saranNotaris = List<String>.from(resNotaris['daftar'])..sort();
      }

      // 2. Jika Mode EDIT: Isi Form dengan Data Awal
      if (dataAwal != null) {
        debiturCtrl.text = dataAwal['debitur'] ?? '';
        notarisCtrl.text = dataAwal['notaris'] ?? '';
        noSuratCtrl.text = dataAwal['noSurat'] ?? '';
        covernoteCtrl.text = dataAwal['covernote'] ?? '';
        rincianCtrl.text = dataAwal['rincian'] ?? '';
        progresKeteranganCtrl.text = dataAwal['progresKeterangan'] ?? '';
        perKasusCtrl.text = dataAwal['perKasus'] ?? '';
        noteCtrl.text = dataAwal['note'] ?? '';
        picBankCtrl.text = dataAwal['picBank'] ?? '';

        // Format angka agar langsung muncul titik ribuan
        limitCtrl.text = _formatAngkaAwal(dataAwal['limit']?.toString());
        nilaiHTCtrl.text = _formatAngkaAwal(dataAwal['nilaiHT']?.toString());
        biayaCtrl.text = _formatAngkaAwal(dataAwal['biaya']?.toString());

        // Parse Tanggal
        tglOrder = _parseDate(dataAwal['tglOrder']);
        tglPelaksanaan = _parseDate(dataAwal['tglPelaksanaan']);
        deadline = _parseDate(dataAwal['deadline']);
        tglBAST = _parseDate(dataAwal['tglBAST']);

        // Amankan Dropdown dari Red Screen
        kcuPilihan = _getSafeDropdown(dataAwal['kcu'], listKcu);
        picInternalPilihan = _getSafeDropdown(
          dataAwal['picInternal'],
          listPicInternal,
        );
        jenisPilihan = _getSafeDropdown(dataAwal['jenis'], listJenisOrder);
        progresPilihan =
            _getSafeDropdown(dataAwal['progres'], listProgres) ?? 'PROSES';
      } else {
        // Jika Mode TAMBAH BARU
        tglOrder = DateTime.now();
        deadline = tglOrder!.add(Duration(days: targetSLA));
        progresPilihan = 'MENUNGGU APPROVAL';
      }
    } catch (e) {
      debugPrint("Error inisialisasi: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // FUNGSI HELPER (FORMATTER & SAFETY)
  // ===========================================================================

  // Format angka ke ribuan (1.000.000) untuk inisialisasi awal
  String _formatAngkaAwal(String? val) {
    if (val == null || val.trim().isEmpty || val == '0') return '';
    String clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return '';

    String formatted = '';
    int count = 0;
    for (int i = clean.length - 1; i >= 0; i--) {
      formatted = clean[i] + formatted;
      count++;
      if (count == 3 && i > 0) {
        formatted = '.$formatted';
        count = 0;
      }
    }
    return formatted;
  }

  // Mencegah error jika nilai dari DB tidak ada di list dropdown
  String? _getSafeDropdown(String? valFromDb, List<String> targetList) {
    if (valFromDb == null || valFromDb.trim().isEmpty || valFromDb == '-')
      return null;
    String valClean = valFromDb.trim();

    for (var item in targetList) {
      if (item.toUpperCase() == valClean.toUpperCase()) return item;
    }

    // Jika data baru/asing, tambahkan ke list sementara agar tidak crash
    targetList.add(valClean);
    return valClean;
  }

  DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().trim().isEmpty || dateStr == '-')
      return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // FUNGSI UPDATE STATE (SETTER)
  // ===========================================================================

  // AUTO-FILL PIC BANK SAAT KCU DIPILIH
  void setKcu(String? val) {
    kcuPilihan = val;
    if (val != null && mapKcuPicBank.containsKey(val)) {
      picBankCtrl.text = mapKcuPicBank[val]!;
    }
    notifyListeners();
  }

  void updateTglOrder(DateTime dt, int sla) {
    tglOrder = dt;
    deadline = dt.add(Duration(days: sla));
    notifyListeners();
  }

  void updateTglPelaksanaan(DateTime dt) {
    tglPelaksanaan = dt;
    notifyListeners();
  }

  void updateDeadline(DateTime dt) {
    deadline = dt;
    notifyListeners();
  }

  void updateTglBAST(DateTime dt) {
    tglBAST = dt;
    notifyListeners();
  }

  void setPicInternal(String? val) {
    picInternalPilihan = val;
    notifyListeners();
  }

  void setJenisOrder(String? val) {
    jenisPilihan = val;
    notifyListeners();
  }

  void setProgres(String val) {
    progresPilihan = val;
    notifyListeners();
  }

  Future<bool> cekKemungkinanDuplikat() async {
    if (noSuratCtrl.text.isNotEmpty) {
      return await repo.cekDuplikatNoSurat(noSuratCtrl.text.trim());
    }
    return false;
  }

  // Menyiapkan Map data untuk dikirim ke MandiriController -> Repository
  Map<String, dynamic> siapkanDataSimpan(String? idAwal) {
    return {
      'id': idAwal ?? repo.generateId(),
      'debitur': debiturCtrl.text.trim(),
      'notaris': notarisCtrl.text.trim(),
      'noSurat': noSuratCtrl.text.trim(),
      'covernote': covernoteCtrl.text.trim(),
      'rincian': rincianCtrl.text.trim(),
      'limit': limitCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
      'nilaiHT': nilaiHTCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
      'biaya': biayaCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
      'progresKeterangan': progresKeteranganCtrl.text.trim(),
      'perKasus': perKasusCtrl.text.trim(),
      'note': noteCtrl.text.trim(),
      'picBank': picBankCtrl.text.trim(),
      'tglOrder': tglOrder?.toIso8601String() ?? '',
      'tglPelaksanaan': tglPelaksanaan?.toIso8601String() ?? '',
      'deadline': deadline?.toIso8601String() ?? '',
      'tglBAST': tglBAST?.toIso8601String() ?? '',
      'kcu': kcuPilihan ?? '',
      'picInternal': picInternalPilihan ?? '',
      'jenis': jenisPilihan ?? '',
      'progres': progresPilihan,
    };
  }

  @override
  void dispose() {
    debiturCtrl.dispose();
    notarisCtrl.dispose();
    noSuratCtrl.dispose();
    covernoteCtrl.dispose();
    rincianCtrl.dispose();
    limitCtrl.dispose();
    nilaiHTCtrl.dispose();
    biayaCtrl.dispose();
    progresKeteranganCtrl.dispose();
    perKasusCtrl.dispose();
    noteCtrl.dispose();
    picBankCtrl.dispose();
    super.dispose();
  }
}
