import 'package:flutter/material.dart';
import 'package:sira_projects/data/repositories/master_data_repository.dart';

class MasterDataController extends ChangeNotifier {
  final MasterDataRepository repo;
  MasterDataController({required this.repo});

  bool isLoading = false;

  // Data Master
  List<String> listKcu = [];
  List<String> listNotaris = [];
  List<String> listPic = [];

  Future<void> loadAllData() async {
    isLoading = true;
    notifyListeners();

    // Mengambil data secara paralel agar lebih cepat
    final results = await Future.wait([
      repo.getListItems('list_kcu'),
      repo.getListItems('list_notaris'),
      repo.getListItems('list_pic_internal'),
    ]);

    listKcu = results[0]..sort();
    listNotaris = results[1]..sort();
    listPic = results[2]..sort();

    isLoading = false;
    notifyListeners();
  }

  Future<void> tambahItem(String docId, String value) async {
    if (value.isEmpty) return;

    List<String> targetList;
    if (docId == 'list_kcu')
      targetList = listKcu;
    else if (docId == 'list_notaris')
      targetList = listNotaris;
    else
      targetList = listPic;

    if (!targetList.contains(value.toUpperCase())) {
      targetList.add(value.toUpperCase());
      targetList.sort();
      await repo.updateListItems(docId, targetList);
      notifyListeners();
    }
  }

  Future<void> hapusItem(String docId, String value) async {
    List<String> targetList;
    if (docId == 'list_kcu')
      targetList = listKcu;
    else if (docId == 'list_notaris')
      targetList = listNotaris;
    else
      targetList = listPic;

    targetList.remove(value);
    await repo.updateListItems(docId, targetList);
    notifyListeners();
  }
}
