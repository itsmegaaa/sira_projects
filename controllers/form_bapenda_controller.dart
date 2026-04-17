import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sira_projects/data/repositories/bapenda_repository.dart';
import 'package:sira_projects/data/models/bapenda_model.dart';

class FormBapendaController extends ChangeNotifier {
  final BapendaRepository repo;
  FormBapendaController({required this.repo});

  bool isLoading = true;

  // Controller Teks
  final debiturCtrl = TextEditingController();
  final developerCtrl = TextEditingController();
  final tglBayarCtrl = TextEditingController();
  final nilaiBphtbCtrl = TextEditingController();
  final setorBphtbCtrl = TextEditingController();
  final nilaiPphCtrl = TextEditingController();
  final setorPphCtrl = TextEditingController();
  final nilaiJualBeliCtrl = TextEditingController();
  final ntpnPphCtrl = TextEditingController();

  String progresBphtb = 'PROSES';
  String progresPph = 'PROSES';
  String jenisSertifikat = 'AJB';
  String jenisPph = 'Komersil';

  final List<String> listProgres = [
    'PROSES',
    'SUDAH BAYAR',
    'BELUM BAYAR',
    'BATAL',
    'SELESAI',
  ];
  final List<String> listSertifikat = ['AJB', 'WARIS', 'PROGRESIF'];
  final List<String> listJenisPph = ['Komersil', 'Non Komersil', 'Perorangan'];

  Future<void> inisialisasiData(BapendaModel? d) async {
    isLoading = true;
    notifyListeners();

    if (d != null) {
      debiturCtrl.text = d.namaDebitur;
      developerCtrl.text = d.developer;
      tglBayarCtrl.text = d.tglBayar;
      setorBphtbCtrl.text = d.setorBphtb;
      setorPphCtrl.text = d.setorPph;
      ntpnPphCtrl.text = d.ntpnPph;

      progresBphtb = _getSafeValue(d.progresBphtb, listProgres);
      progresPph = _getSafeValue(d.progresPph, listProgres);
      jenisSertifikat = _getSafeValue(d.jenisSertifikat, listSertifikat);
      jenisPph = _getSafeValue(d.jenisPph, listJenisPph);

      _formatRupiah(nilaiJualBeliCtrl, d.nilaiJualBeli);
      _formatRupiah(nilaiPphCtrl, d.nilaiPph);
      if (d.nilaiBphtb == 'MBR') {
        nilaiBphtbCtrl.text = 'MBR';
      } else {
        _formatRupiah(nilaiBphtbCtrl, d.nilaiBphtb);
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void _formatRupiah(TextEditingController ctrl, String v) {
    String clean = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      ctrl.text = '';
      return;
    }
    ctrl.text = NumberFormat.currency(
      locale: 'id',
      symbol: '',
      decimalDigits: 0,
    ).format(int.parse(clean));
  }

  String _getSafeValue(String valFromDb, List<String> targetList) {
    if (valFromDb.trim().isEmpty) return targetList.first;
    String valClean = valFromDb.trim();
    for (var item in targetList) {
      if (item.toUpperCase() == valClean.toUpperCase()) return item;
    }

    targetList.add(valClean);
    return valClean;
  }

  void hitungOtomatis() {
    String cleanNJB = nilaiJualBeliCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNJB.isEmpty) {
      nilaiBphtbCtrl.text = '';
      nilaiPphCtrl.text = '';
      notifyListeners();
      return;
    }

    int njb = int.parse(cleanNJB);

    // Logika BPHTB
    int subsidi = (jenisSertifikat == 'WARIS')
        ? 300000000
        : (jenisSertifikat == 'AJB' ? 80000000 : 0);
    bool paksaMBR = (jenisSertifikat == 'AJB' && njb <= 140000000);
    int hasilBphtb = ((njb - subsidi) * 0.05).toInt();

    nilaiBphtbCtrl.text = (paksaMBR || hasilBphtb <= 0)
        ? 'MBR'
        : NumberFormat.currency(
            locale: 'id',
            symbol: '',
            decimalDigits: 0,
          ).format(hasilBphtb);

    // Logika PPH
    double tarif = (jenisPph == 'Non Komersil') ? 0.01 : 0.025;
    _formatRupiah(nilaiPphCtrl, (njb * tarif).toInt().toString());
    notifyListeners();
  }

  @override
  void dispose() {
    // Membasmi Memory Leak
    debiturCtrl.dispose();
    developerCtrl.dispose();
    tglBayarCtrl.dispose();
    nilaiBphtbCtrl.dispose();
    setorBphtbCtrl.dispose();
    nilaiPphCtrl.dispose();
    setorPphCtrl.dispose();
    nilaiJualBeliCtrl.dispose();
    ntpnPphCtrl.dispose();
    super.dispose();
  }
}
