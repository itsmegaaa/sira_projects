import 'package:cloud_firestore/cloud_firestore.dart';

class MandiriRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('data_mandiri');

  // OPTIMASI: Stream dibatasi hanya 200 data terbaru agar ringan
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDataNotaris({
    int limit = 200,
  }) {
    return _col.orderBy('tglOrder', descending: true).limit(limit).snapshots();
  }

  Future<void> simpanOrder(Map<String, dynamic> data) async {
    await _col.doc(data['id']).set(data, SetOptions(merge: true));
  }

  Future<void> hapusData(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> updateProgres(String id, String progres) async {
    await _col.doc(id).update({'progres': progres});
  }

  Future<void> tambahHistori(String id, String teks) async {
    await _col.doc(id).collection('histori').add({
      'teks': teks,
      'waktu': FieldValue.serverTimestamp(),
    });
  }

  Future<void> catatAktivitas(
    String aksi,
    String detail,
    String userEmail,
  ) async {
    await _db.collection('logs_notaris').add({
      'aksi': aksi,
      'detail': detail,
      'oleh': userEmail.isNotEmpty ? userEmail : 'Sistem',
      'waktu': FieldValue.serverTimestamp(),
    });
  }

  // --- FUNGSI KHUSUS UNTUK BACKUP & PENGATURAN ---
  Future<List<Map<String, dynamic>>> getAllData() async {
    final snap = await _col.get();
    return snap.docs.map((e) => e.data()).toList();
  }

  Future<void> restoreData(List<dynamic> dataBaru) async {
    WriteBatch batch = _db.batch();
    int count = 0;
    for (var item in dataBaru) {
      if (item is Map<String, dynamic> && item.containsKey('id')) {
        batch.set(_col.doc(item['id'].toString()), item);
        count++;
        if (count % 400 == 0) {
          await batch.commit();
          batch = _db.batch();
        }
      }
    }
    await batch.commit();
  }

  Future<void> hapusSemuaData() async {
    final snap = await _col.get();
    WriteBatch batch = _db.batch();
    int count = 0;
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
      count++;
      if (count % 400 == 0) {
        await batch.commit();
        batch = _db.batch();
      }
    }
    await batch.commit();
  }

  // Expose Batch untuk Import Excel
  WriteBatch getBatch() => _db.batch();
  DocumentReference getDocRef(String id) => _col.doc(id);

  // --- FUNGSI CEK DUPLIKAT (Digunakan oleh FormOrderController) ---
  Future<bool> cekDuplikatNoSurat(String noSurat) async {
    final result = await _col
        .where('noSurat', isEqualTo: noSurat)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<bool> cekDuplikatKodeUnik(String kodeUnik) async {
    final result = await _col
        .where('kode_duplikat', isEqualTo: kodeUnik)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  String generateId() => _col.doc().id;

  Future<Map<String, dynamic>> getMasterDataMap(String idDokumen) async {
    try {
      final doc = await _db.collection('master_data').doc(idDokumen).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
    } catch (e) {
      // Abaikan jika error/offline
    }
    return {};
  }
}
