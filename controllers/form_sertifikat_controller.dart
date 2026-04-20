// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 Tambahan penting untuk format waktu Firebase
import 'package:sira_projects/data/repositories/sertifikat_repository.dart';

class FormSertifikatController extends ChangeNotifier {
  final SertifikatRepository repo;
  FormSertifikatController({required this.repo});

  bool isLoading = true;

  // --- CONTROLLER TEKS ---
  final noSertifikatCtrl = TextEditingController();
  final desaCtrl = TextEditingController();
  final pemilikCtrl = TextEditingController();
  final bankCtrl = TextEditingController();
  final prosesSHMCtrl = TextEditingController();
  final debiturCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  final klewisCtrl = TextEditingController();
  final catatanCtrl = TextEditingController();
  final pemegangBerkasCtrl = TextEditingController();

  // --- VARIABEL TANGGAL ---
  DateTime? tglMasuk, tglKeluar;

  // --- VARIABEL DROPDOWN ---
  List<String> listType = ['Hak Milik', 'HGB', 'Strata Title', 'Lainnya'];
  String typePilihan = 'Hak Milik';

  List<String> listStatus = ['Dalam proses', 'Selesai', 'Batal', 'Dipinjam'];
  String statusPilihan = 'Dalam proses';

  // ===========================================================================
  // INISIALISASI DATA
  // ===========================================================================
  Future<void> inisialisasiData(Map<String, dynamic>? dataAwal) async {
    isLoading = true;
    notifyListeners();

    try {
      if (dataAwal != null) {
        noSertifikatCtrl.text = dataAwal['noSertifikat'] ?? '';
        desaCtrl.text = dataAwal['desa'] ?? '';
        pemilikCtrl.text = dataAwal['pemilik'] ?? '';
        bankCtrl.text = dataAwal['bank'] ?? '';
        prosesSHMCtrl.text = dataAwal['prosesSHM'] ?? '';
        debiturCtrl.text = dataAwal['debitur'] ?? '';
        detailCtrl.text = dataAwal['detail'] ?? '';
        klewisCtrl.text = dataAwal['klewis'] ?? '';
        catatanCtrl.text = dataAwal['catatan'] ?? '';
        pemegangBerkasCtrl.text = dataAwal['pemegangBerkas'] ?? '';

        tglMasuk = _parseDate(dataAwal['tglMasuk']);
        tglKeluar = _parseDate(dataAwal['tglKeluar']);

        typePilihan =
            _getSafeDropdown(dataAwal['typeSertifikat'], listType) ??
            'Hak Milik';
        statusPilihan =
            _getSafeDropdown(dataAwal['status'], listStatus) ?? 'Dalam proses';
      } else {
        tglMasuk = DateTime.now();
      }
    } catch (e) {
      debugPrint("Error inisialisasi form: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // FUNGSI HELPER
  // ===========================================================================
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
  // SETTER & SIMPAN DATA LANGSUNG KE FIREBASE
  // ===========================================================================
  void setType(String val) {
    typePilihan = val;
    notifyListeners();
  }

  void setStatus(String val) {
    statusPilihan = val;
    notifyListeners();
  }

  void updateTglMasuk(DateTime dt) {
    tglMasuk = dt;
    notifyListeners();
  }

  void updateTglKeluar(DateTime dt) {
    tglKeluar = dt;
    notifyListeners();
  }

  Future<bool> simpanDataFirebase(String? idAwal) async {
    try {
      final data = {
        'id': idAwal ?? repo.generateId(),
        'typeSertifikat': typePilihan,
        'noSertifikat': noSertifikatCtrl.text.trim(),
        'desa': desaCtrl.text.trim(),
        'pemilik': pemilikCtrl.text.trim(),
        'bank': bankCtrl.text.trim(),
        'prosesSHM': prosesSHMCtrl.text.trim(),
        'debitur': debiturCtrl.text.trim(),
        'detail': detailCtrl.text.trim(),
        'klewis': klewisCtrl.text.trim(),
        'status': statusPilihan,

        // 👈 PERBAIKAN FORMAT TANGGAL MENGGUNAKAN TIMESTAMP FIREBASE
        'tglMasuk': tglMasuk != null ? Timestamp.fromDate(tglMasuk!) : null,
        'tglKeluar': tglKeluar != null ? Timestamp.fromDate(tglKeluar!) : null,

        'catatan': catatanCtrl.text.trim(),
        'pemegangBerkas': pemegangBerkasCtrl.text.trim(),
      };

      await repo.simpanData(data);
      return true;
    } catch (e) {
      debugPrint("Gagal menyimpan data: $e");
      return false;
    }
  }

  @override
  void dispose() {
    noSertifikatCtrl.dispose();
    desaCtrl.dispose();
    pemilikCtrl.dispose();
    bankCtrl.dispose();
    prosesSHMCtrl.dispose();
    debiturCtrl.dispose();
    detailCtrl.dispose();
    klewisCtrl.dispose();
    catatanCtrl.dispose();
    pemegangBerkasCtrl.dispose();
    super.dispose();
  }
}
