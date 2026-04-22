// ignore_for_file: curly_braces_in_flow_control_structures

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
  Map<String, String> mapKcuPicBank = {};
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
      // 1. Tarik Master Data berdasarkan struktur master_data/{docId}
      final resKcu = await repo.getMasterDataMap('kcu');
      final resPic = await repo.getMasterDataMap('pic');
      final resNotaris = await repo.getMasterDataMap('notaris');

      // Proses Master Data KCU
      if (resKcu.isNotEmpty) {
        mapKcuPicBank = {};
        resKcu.forEach((key, value) {
          if (key != 'lastUpdate' && value is String) {
            mapKcuPicBank[key.trim()] = value.trim();
          }
        });
        listKcu = mapKcuPicBank.keys.toList()..sort();
      }

      // Ekstraksi otomatis untuk PIC dan Notaris (Mencegah Dropdown Kosong)
      listPicInternal = _ekstrakDataMaster(resPic)..sort();
      saranNotaris = _ekstrakDataMaster(resNotaris)..sort();

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

        limitCtrl.text = _formatAngkaAwal(dataAwal['limit']?.toString());
        nilaiHTCtrl.text = _formatAngkaAwal(dataAwal['nilaiHT']?.toString());
        biayaCtrl.text = _formatAngkaAwal(dataAwal['biaya']?.toString());

        tglOrder = _parseDate(dataAwal['tglOrder']);
        tglPelaksanaan = _parseDate(dataAwal['tglPelaksanaan']);
        deadline = _parseDate(dataAwal['deadline']);
        tglBAST = _parseDate(dataAwal['tglBAST']);

        kcuPilihan = _getSafeDropdown(dataAwal['kcu'], listKcu);
        picInternalPilihan = _getSafeDropdown(
          dataAwal['picInternal'],
          listPicInternal,
        );
        jenisPilihan = _getSafeDropdown(dataAwal['jenis'], listJenisOrder);
        progresPilihan =
            _getSafeDropdown(dataAwal['progres'], listProgres) ?? 'PROSES';
      } else {
        tglOrder = DateTime.now();
        deadline = tglOrder!.add(Duration(days: targetSLA));
        progresPilihan = 'MENUNGGU APPROVAL';
      }
    } catch (e) {
      debugPrint("Error inisialisasi master data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // FUNGSI HELPER (CERDAS & AMAN)
  // ===========================================================================

  // Mendeteksi data baik di dalam Field Array maupun di dalam Key dokumen
  List<String> _ekstrakDataMaster(Map<String, dynamic> dataMap) {
    if (dataMap.isEmpty) return [];

    // Prioritas 1: Cari field list/array yang umum digunakan
    for (String key in ['daftar', 'items', 'list', 'data']) {
      if (dataMap.containsKey(key) && dataMap[key] is List) {
        return List<String>.from(dataMap[key]);
      }
    }

    // Prioritas 2: Ambil field list apa saja yang ditemukan di dokumen
    for (var value in dataMap.values) {
      if (value is List) return List<String>.from(value);
    }

    // Prioritas 3: Jika tidak ada array, ambil Key dokumen (seperti struktur KCU)
    return dataMap.keys.where((k) => k != 'lastUpdate').toList();
  }

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

  String? _getSafeDropdown(String? valFromDb, List<String> targetList) {
    if (valFromDb == null || valFromDb.trim().isEmpty || valFromDb == '-')
      return null;
    String valClean = valFromDb.trim();
    for (var item in targetList) {
      if (item.toUpperCase() == valClean.toUpperCase()) return item;
    }
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
  // SETTER & LOGIKA BISNIS
  // ===========================================================================

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
    if (noSuratCtrl.text.isNotEmpty)
      return await repo.cekDuplikatNoSurat(noSuratCtrl.text.trim());
    return false;
  }

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
