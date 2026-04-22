// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sira_projects/data/models/sertifikat_model.dart';
import 'package:sira_projects/data/repositories/sertifikat_repository.dart';

class SertifikatController extends ChangeNotifier {
  final SertifikatRepository repo;
  SertifikatController({required this.repo});

  StreamSubscription? _streamSub;
  List<SertifikatModel> daftarSertifikat = [];
  bool isLoading = true;
  String kataKunci = '';
  String filterLokasi = 'SEMUA';

  void inisialisasiData() {
    _streamSub?.cancel();
    _streamSub = repo.streamData().listen(
      (data) {
        daftarSertifikat = data;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Error stream sertifikat: $e");
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> hapusData(String id) async {
    try {
      await repo.hapusData(id);
    } catch (e) {
      debugPrint("Error hapus sertifikat: $e");
      rethrow;
    }
  }

  void setFilterLokasi(String status) {
    filterLokasi = status;
    notifyListeners();
  }

  void setKataKunci(String keyword) {
    kataKunci = keyword.toLowerCase();
    notifyListeners();
  }

  bool cekTelat(SertifikatModel item) {
    if (item.status.toUpperCase() == 'SELESAI' || item.tglMasuk == null)
      return false;
    final deadline = item.tglMasuk!.add(const Duration(days: 90));
    return DateTime.now().isAfter(deadline);
  }

  int hitungSisaHari(SertifikatModel item) {
    if (item.tglMasuk == null) return 0;
    final deadline = item.tglMasuk!.add(const Duration(days: 90));
    return deadline.difference(DateTime.now()).inDays;
  }

  List<SertifikatModel> get filteredData {
    return daftarSertifikat.where((item) {
      bool cocokKata =
          kataKunci.isEmpty ||
          item.noSertifikat.toLowerCase().contains(kataKunci) ||
          item.pemilik.toLowerCase().contains(kataKunci) ||
          item.desa.toLowerCase().contains(kataKunci);

      bool cocokLokasi = true;
      if (filterLokasi == 'SELESAI') {
        cocokLokasi = item.status.toUpperCase() == 'SELESAI';
      } else if (filterLokasi == 'INTERNAL') {
        cocokLokasi =
            item.status.toUpperCase() != 'SELESAI' &&
            item.pemegangBerkas.isNotEmpty;
      } else if (filterLokasi == 'EKSTERNAL') {
        cocokLokasi =
            item.status.toUpperCase() != 'SELESAI' && item.klewis.isNotEmpty;
      }

      return cocokKata && cocokLokasi;
    }).toList();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
