import 'package:cloud_firestore/cloud_firestore.dart';

class BapendaModel {
  final String id;
  final String namaDebitur;
  final String developer;
  final String tglBayar;
  final String nilaiBphtb;
  final String progresBphtb;
  final String setorBphtb;
  final String nilaiPph;
  final String progresPph;
  final String setorPph;
  final String nilaiJualBeli;
  final String ntpnPph;
  final String jenisSertifikat; // <-- Field baru untuk menggantikan sumber
  final String jenisPph; // <-- Field baru

  BapendaModel({
    required this.id,
    required this.namaDebitur,
    required this.developer,
    required this.tglBayar,
    required this.nilaiBphtb,
    required this.progresBphtb,
    required this.setorBphtb,
    required this.nilaiPph,
    required this.progresPph,
    required this.setorPph,
    required this.nilaiJualBeli,
    required this.ntpnPph,
    required this.jenisSertifikat,
    required this.jenisPph,
  });

  factory BapendaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BapendaModel(
      id: doc.id,
      namaDebitur: data['namaDebitur'] ?? '-',
      developer: data['developer'] ?? '-',
      tglBayar: data['tglBayar'] ?? '-',
      nilaiBphtb: data['nilaiBphtb'] ?? '0',
      progresBphtb: data['progresBphtb'] ?? 'PROSES',
      setorBphtb: data['setorBphtb'] ?? '-',
      nilaiPph: data['nilaiPph'] ?? '0',
      progresPph: data['progresPph'] ?? 'PROSES',
      setorPph: data['setorPph'] ?? '-',
      nilaiJualBeli: data['nilaiJualBeli'] ?? '0',
      ntpnPph: data['ntpnPph'] ?? '-',
      // Menangkap data lama (sumber) sebagai jenisSertifikat, default AJB
      jenisSertifikat: data['jenisSertifikat'] ?? data['sumber'] ?? 'AJB',
      jenisPph: data['jenisPph'] ?? 'Komersil',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaDebitur': namaDebitur,
      'developer': developer,
      'tglBayar': tglBayar,
      'nilaiBphtb': nilaiBphtb,
      'progresBphtb': progresBphtb,
      'setorBphtb': setorBphtb,
      'nilaiPph': nilaiPph,
      'progresPph': progresPph,
      'setorPph': setorPph,
      'nilaiJualBeli': nilaiJualBeli,
      'ntpnPph': ntpnPph,
      'jenisSertifikat': jenisSertifikat,
      'jenisPph': jenisPph,
      'waktuUpdate': FieldValue.serverTimestamp(),
    };
  }
}
