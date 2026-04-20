import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sira_projects/data/models/sertifikat_model.dart';

class SertifikatRepository {
  // Disimpan dalam root collection yang sepenuhnya terpisah
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'monitoring_sertifikat',
  );

  String generateId() => _collection.doc().id;

  Stream<List<SertifikatModel>> streamData() {
    return _collection.orderBy('tglMasuk', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => SertifikatModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> simpanData(Map<String, dynamic> data) async {
    String id = data['id'] ?? generateId();
    await _collection.doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> hapusData(String id) async {
    await _collection.doc(id).delete();
  }
}
