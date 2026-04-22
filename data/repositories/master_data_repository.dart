import 'package:cloud_firestore/cloud_firestore.dart';

class MasterDataRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('master_data');

  // Mengambil daftar item dari dokumen tertentu (misal: 'list_kcu')
  Future<List<String>> getListItems(String docId) async {
    try {
      final snap = await _col.doc(docId).get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        return List<String>.from(data['items'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> tambahKcu(String namaBank, String picBank) async {
    await _col.doc('kcu').set({namaBank: picBank}, SetOptions(merge: true));
  }

  // Menyimpan perubahan daftar item kembali ke Firestore
  Future<void> updateListItems(String docId, List<String> items) async {
    await _col.doc(docId).set({
      'items': items,
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
