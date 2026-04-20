import 'package:cloud_firestore/cloud_firestore.dart';

class SertifikatModel {
  final String id;
  final String typeSertifikat;
  final String noSertifikat;
  final String desa;
  final String pemilik;
  final String bank;
  final String prosesSHM;
  final String debitur;
  final String detail;
  final String klewis; // Pihak Eksternal
  final String status;
  final DateTime? tglMasuk;
  final DateTime? tglKeluar;
  final String catatan;
  final String akad;
  final String pemegangBerkas; // Pihak Internal

  SertifikatModel({
    required this.id,
    this.typeSertifikat = '',
    this.noSertifikat = '',
    this.desa = '',
    this.pemilik = '',
    this.bank = '',
    this.prosesSHM = '',
    this.debitur = '',
    this.detail = '',
    this.klewis = '',
    this.status = 'Dalam proses',
    this.tglMasuk,
    this.tglKeluar,
    this.catatan = '',
    this.akad = '',
    this.pemegangBerkas = '',
  });

  factory SertifikatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return SertifikatModel(
      id: doc.id,
      typeSertifikat: data['typeSertifikat'] ?? '',
      noSertifikat: data['noSertifikat'] ?? '',
      desa: data['desa'] ?? '',
      pemilik: data['pemilik'] ?? '',
      bank: data['bank'] ?? '',
      prosesSHM: data['prosesSHM'] ?? '',
      debitur: data['debitur'] ?? '',
      detail: data['detail'] ?? '',
      klewis: data['klewis'] ?? '',
      status: data['status'] ?? 'Dalam proses',
      tglMasuk: data['tglMasuk'] != null ? (data['tglMasuk'] as Timestamp).toDate() : null,
      tglKeluar: data['tglKeluar'] != null ? (data['tglKeluar'] as Timestamp).toDate() : null,
      catatan: data['catatan'] ?? '',
      akad: data['akad'] ?? '',
      pemegangBerkas: data['pemegangBerkas'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'typeSertifikat': typeSertifikat,
      'noSertifikat': noSertifikat,
      'desa': desa,
      'pemilik': pemilik,
      'bank': bank,
      'prosesSHM': prosesSHM,
      'debitur': debitur,
      'detail': detail,
      'klewis': klewis,
      'status': status,
      'tglMasuk': tglMasuk != null ? Timestamp.fromDate(tglMasuk!) : null,
      'tglKeluar': tglKeluar != null ? Timestamp.fromDate(tglKeluar!) : null,
      'catatan': catatan,
      'akad': akad,
      'pemegangBerkas': pemegangBerkas,
    };
  }
}