import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gabut_tracker/controllers/form_bapenda_controller.dart';
import 'package:gabut_tracker/data/repositories/bapenda_repository.dart';
import 'package:gabut_tracker/data/models/bapenda_model.dart';

// =====================================================================
// KELAS FORMATTER: Antipelah terhadap Error Titik Koma
// =====================================================================
class CurrencyFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String cleanNumber = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.isEmpty) return newValue.copyWith(text: '');

    try {
      final formatter = NumberFormat.currency(
        locale: 'id',
        symbol: '',
        decimalDigits: 0,
      );
      String newText = formatter.format(int.parse(cleanNumber));
      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } catch (e) {
      // Jika angka terlalu besar atau error, kembalikan ke nilai aman sebelumnya
      return oldValue;
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection, // Memastikan kursor tidak loncat ke awal
    );
  }
}

class FormBapendaScreen extends StatefulWidget {
  final BapendaModel? dataAwal;
  const FormBapendaScreen({super.key, this.dataAwal});

  @override
  State<FormBapendaScreen> createState() => _FormBapendaScreenState();
}

class _FormBapendaScreenState extends State<FormBapendaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final FormBapendaController _c;

  @override
  void initState() {
    super.initState();
    _c = FormBapendaController(repo: context.read<BapendaRepository>());
    _c.inisialisasiData(widget.dataAwal);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // =====================================================================
  // FUNGSI SIMPAN ANTIPELURU
  // =====================================================================
  void _simpan() {
    try {
      // Pastikan validasi berjalan (Nama Debitur tidak boleh kosong)
      if (_formKey.currentState?.validate() ?? false) {
        String clean(String v) => v.replaceAll(RegExp(r'[^0-9]'), '');

        // Generate ID aman terintegrasi dengan Repository Bapenda
        final idBaru =
            widget.dataAwal?.id ?? _c.repo.getDocRef('temp').parent.doc().id;

        final Map<String, dynamic> data = {
          'id': idBaru,
          'namaDebitur': _c.debiturCtrl.text.trim(),
          'developer': _c.developerCtrl.text.trim(),
          'tglBayar': _c.tglBayarCtrl.text.trim(),
          'nilaiBphtb': _c.nilaiBphtbCtrl.text == 'MBR'
              ? 'MBR'
              : clean(_c.nilaiBphtbCtrl.text),
          'progresBphtb': _c.progresBphtb,
          'setorBphtb': _c.setorBphtbCtrl.text.trim(),
          'nilaiPph': clean(_c.nilaiPphCtrl.text),
          'progresPph': _c.progresPph,
          'setorPph': _c.setorPphCtrl.text.trim(),
          'nilaiJualBeli': clean(_c.nilaiJualBeliCtrl.text),
          'ntpnPph': _c.ntpnPphCtrl.text.trim(),
          'jenisSertifikat': _c.jenisSertifikat,
          'jenisPph': _c.jenisPph,
        };

        Navigator.pop(context, data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal! Nama Debitur Wajib Diisi.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Tangkap error jika ada kegagalan proses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Crash Form: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dataAwal == null ? 'Tambah Bapenda' : 'Edit Bapenda',
        ),
        backgroundColor: const Color.fromARGB(255, 202, 175, 51),
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          if (_c.isLoading)
            return const Center(child: CircularProgressIndicator());

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'INFORMASI UMUM',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                _buildField(
                  _c.debiturCtrl,
                  'Nama Debitur',
                  isWajib: true,
                  textCapitalization: TextCapitalization.characters,
                ),
                _buildField(
                  _c.developerCtrl,
                  'Developer / Perumahan',
                  textCapitalization: TextCapitalization.characters,
                ),

                _buildField(
                  _c.nilaiJualBeliCtrl,
                  'Nilai Jual Beli',
                  keyboardType: TextInputType.number,
                  isCurrency: true,
                  inputFormatters: [CurrencyFormat()],
                  onChanged: (v) => _c.hitungOtomatis(),
                ),

                _buildDropdown(
                  'Jenis Sertifikat',
                  _c.jenisSertifikat,
                  _c.listSertifikat,
                  (v) {
                    _c.jenisSertifikat = v!;
                    _c.hitungOtomatis();
                  },
                ),

                const Divider(height: 30, thickness: 2),
                const Text(
                  'DATA BPHTB',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                _buildField(
                  _c.nilaiBphtbCtrl,
                  'Nilai BPHTB',
                  isCurrency: true,
                  readOnly: true,
                ),
                _buildDropdown(
                  'Progres BPHTB',
                  _c.progresBphtb,
                  _c.listProgres,
                  (v) => setState(() => _c.progresBphtb = v!),
                ),
                _buildField(
                  _c.setorBphtbCtrl,
                  'Petugas Setor BPHTB',
                  textCapitalization: TextCapitalization.characters,
                ),

                const Divider(height: 30, thickness: 2),
                const Text(
                  'DATA PPH',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                _buildDropdown('Jenis PPH', _c.jenisPph, _c.listJenisPph, (v) {
                  _c.jenisPph = v!;
                  _c.hitungOtomatis();
                }),
                _buildField(
                  _c.nilaiPphCtrl,
                  'Nilai PPH',
                  isCurrency: true,
                  readOnly: true,
                ),
                _buildDropdown(
                  'Progres PPH',
                  _c.progresPph,
                  _c.listProgres,
                  (v) => setState(() => _c.progresPph = v!),
                ),
                _buildField(
                  _c.setorPphCtrl,
                  'Petugas Setor PPH',
                  textCapitalization: TextCapitalization.characters,
                ),
                _buildField(
                  _c.ntpnPphCtrl,
                  'NTPN PPH',
                  textCapitalization: TextCapitalization.characters,
                ),

                const Divider(height: 30, thickness: 2),

                if (widget.dataAwal != null)
                  _buildField(
                    _c.tglBayarCtrl,
                    'Tanggal Bayar',
                    ikon: Icons.calendar_today,
                    readOnly: true,
                    onTap: () => _pilihTanggal(),
                  ),

                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 202, 175, 51),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _simpan,
                  child: const Text(
                    'SIMPAN DATA BAPENDA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    bool isWajib = false,
    IconData? ikon,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    bool isCurrency = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    List<TextInputFormatter> finalFormatters = inputFormatters != null
        ? List.from(inputFormatters)
        : [];

    if (textCapitalization == TextCapitalization.characters) {
      finalFormatters.add(UpperCaseTextFormatter());
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters:
            finalFormatters, // 👈 Gunakan finalFormatters yang sudah disuntik
        onChanged: onChanged,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: isWajib ? '$label *' : label,
          prefixIcon: ikon != null ? Icon(ikon) : null,
          prefixText: (isCurrency && ctrl.text != 'MBR' && ctrl.text.isNotEmpty)
              ? 'Rp '
              : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: isWajib
            ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade50,
        ),
      ),
    );
  }

  Future<void> _pilihTanggal() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color.fromARGB(255, 202, 175, 51),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(
        () => _c.tglBayarCtrl.text = DateFormat('dd-MM-yyyy').format(picked),
      );
    }
  }
}
