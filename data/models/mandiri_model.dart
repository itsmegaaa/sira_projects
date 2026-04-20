// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String kodeDuplikat;
  final String debitur;
  final String debiturLower;
  final String notaris;
  final String kcu;
  final String picBank;
  final String picInternal;
  final String noSurat;
  final String covernote;
  final String jenis;
  final String rincian;

  // Finansial (Disimpan sebagai string angka murni)
  final String limit;
  final String nilaiHT;
  final String biaya;

  // Waktu
  final DateTime? tglOrder;
  final DateTime? tglPelaksanaan;
  final DateTime? deadline;
  final DateTime? tglBAST;

  // Status & Laporan
  final String progres;
  final String progresKeterangan;
  final String perKasus;
  final String note;

  OrderModel({
    required this.id,
    required this.kodeDuplikat,
    required this.debitur,
    required this.debiturLower,
    required this.notaris,
    required this.kcu,
    required this.picBank,
    required this.picInternal,
    required this.noSurat,
    required this.covernote,
    required this.jenis,
    required this.rincian,
    required this.limit,
    required this.nilaiHT,
    required this.biaya,
    this.tglOrder,
    this.tglPelaksanaan,
    this.deadline,
    this.tglBAST,
    required this.progres,
    required this.progresKeterangan,
    required this.perKasus,
    required this.note,
  });

  // ==========================================
  // 1. DARI FIRESTORE KE DART (Deserialisasi)
  // ==========================================
  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? parseDate(dynamic dateString) {
      if (dateString == null ||
          dateString.toString().isEmpty ||
          dateString == '-')
        return null;
      try {
        return DateTime.parse(dateString.toString());
      } catch (e) {
        return null;
      }
    }

    return OrderModel(
      id: documentId,
      kodeDuplikat: map['kode_duplikat'] ?? map['id'] ?? documentId,
      debitur: map['debitur'] ?? '-',
      debiturLower:
          map['debitur_lower'] ??
          (map['debitur']?.toString().toLowerCase() ?? '-'),
      notaris: map['notaris'] ?? '-',
      kcu: map['kcu'] ?? '-',
      picBank: map['picBank'] ?? '-',
      picInternal: map['picInternal'] ?? '-',
      noSurat: map['noSurat'] ?? '-',
      covernote: map['covernote'] ?? '-',
      jenis: map['jenis'] ?? '-',
      rincian: map['rincian'] ?? '-',
      limit: map['limit']?.toString() ?? '0',
      nilaiHT: map['nilaiHT']?.toString() ?? '0',
      biaya: map['biaya']?.toString() ?? '0',
      tglOrder: parseDate(map['tglOrder']),
      tglPelaksanaan: parseDate(map['tglPelaksanaan']),
      deadline: parseDate(map['deadline']),
      tglBAST: parseDate(map['tglBAST']),
      progres: map['progres'] ?? 'PROSES',
      progresKeterangan: map['progresKeterangan'] ?? '',
      perKasus: map['perKasus'] ?? '',
      note: map['note'] ?? '',
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ==========================================
  // 2. DARI DART KE FIRESTORE (Serialisasi)
  // ==========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_duplikat': kodeDuplikat,
      'debitur': debitur,
      'debitur_lower': debiturLower,
      'notaris': notaris,
      'kcu': kcu,
      'picBank': picBank,
      'picInternal': picInternal,
      'noSurat': noSurat,
      'covernote': covernote,
      'jenis': jenis,
      'rincian': rincian,
      'limit': limit,
      'nilaiHT': nilaiHT,
      'biaya': biaya,
      'tglOrder': tglOrder?.toIso8601String(),
      'tglPelaksanaan': tglPelaksanaan?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'tglBAST': tglBAST?.toIso8601String(),
      'progres': progres,
      'progresKeterangan': progresKeterangan,
      'perKasus': perKasus,
      'note': note,
    };
  }

  // ==========================================
  // 3. COPY WITH (Untuk Memperbarui State Parsial)
  // ==========================================
  OrderModel copyWith({
    String? progres,
    String? progresKeterangan,
    DateTime? tglBAST,
  }) {
    return OrderModel(
      id: id,
      kodeDuplikat: kodeDuplikat,
      debitur: debitur,
      debiturLower: debiturLower,
      notaris: notaris,
      kcu: kcu,
      picBank: picBank,
      picInternal: picInternal,
      noSurat: noSurat,
      covernote: covernote,
      jenis: jenis,
      rincian: rincian,
      limit: limit,
      nilaiHT: nilaiHT,
      biaya: biaya,
      tglOrder: tglOrder,
      tglPelaksanaan: tglPelaksanaan,
      deadline: deadline,
      tglBAST: tglBAST ?? this.tglBAST,
      progres: progres ?? this.progres,
      progresKeterangan: progresKeterangan ?? this.progresKeterangan,
      perKasus: perKasus,
      note: note,
    );
  }
}
