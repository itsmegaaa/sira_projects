import 'package:cloud_firestore/cloud_firestore.dart';

class BapendaRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Pastikan koleksinya konsisten di data_bapenda
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('data_bapenda');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPekerjaan({
    int limit = 200,
  }) {
    return _collection
        .orderBy('waktuUpdate', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> simpanPekerjaan(Map<String, dynamic> data) async {
    data['waktuUpdate'] = FieldValue.serverTimestamp();
    await _collection.doc(data['id']).set(data, SetOptions(merge: true));
  }

  Future<void> hapusPekerjaan(String id) async {
    await _collection.doc(id).delete();
  }

  // ========================================================
  // CCTV LOG BAPENDA
  // ========================================================
  Future<void> catatAktivitas(
    String aksi,
    String detail,
    String userEmail,
  ) async {
    await _db.collection('logs_bapenda').add({
      'aksi': aksi,
      'detail': detail,
      'oleh': userEmail.isNotEmpty ? userEmail : 'Sistem',
      'waktu': FieldValue.serverTimestamp(),
    });
  }

  WriteBatch getBatch() => _db.batch();
  DocumentReference getDocRef(String id) => _collection.doc(id);

  Future<Map<String, dynamic>> getMasterDataMap(String idDokumen) async {
    try {
      final doc = await _db.collection('master_data').doc(idDokumen).get();
      return doc.exists ? (doc.data() ?? {}) : {};
    } catch (e) {
      return {};
    }
  }
}
