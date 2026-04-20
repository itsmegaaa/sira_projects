// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sira_projects/controllers/sertifikat_controller.dart';
import 'package:sira_projects/controllers/form_sertifikat_controller.dart';

// Class untuk memaksa teks menjadi huruf Kapital (Capitalize)
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class FormSertifikatScreen extends StatefulWidget {
  final Map<String, dynamic>? dataAwal;
  const FormSertifikatScreen({super.key, this.dataAwal});

  @override
  State<FormSertifikatScreen> createState() => _FormSertifikatScreenState();
}

class _FormSertifikatScreenState extends State<FormSertifikatScreen> {
  final _formKey = GlobalKey<FormState>();
  late final FormSertifikatController _c;

  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color surfaceColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // Mengambil Repo dari Controller Utama
    _c = FormSertifikatController(
      repo: context.read<SertifikatController>().repo,
    );
    _c.inisialisasiData(widget.dataAwal);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    DateTime? initialDate,
    Function(DateTime) onPicked,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: navyColor)),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  void _simpanData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi kolom yang wajib!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Menyimpan data...')));

    // Memanggil fungsi simpan yang ada di Controller
    bool sukses = await _c.simpanDataFirebase(widget.dataAwal?['id']);

    if (sukses && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.pop(context); // Tutup layar jika berhasil
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.dataAwal != null;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color currentBg = isDark ? const Color(0xFF121212) : bgColor;
    Color currentSurface = isDark ? const Color(0xFF1E1E1E) : surfaceColor;
    Color currentText = isDark ? Colors.white : navyColor;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Data Sertifikat' : 'Input Sertifikat Baru',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: currentText,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: currentSurface,
        foregroundColor: currentText,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            if (_c.isLoading)
              return Center(child: CircularProgressIndicator(color: goldColor));

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionCard(
                  title: 'INFORMASI FISIK SERTIFIKAT',
                  icon: Icons.book_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    _buildDropdown(
                      'Tipe Sertifikat',
                      _c.typePilihan,
                      _c.listType,
                      (v) => _c.setType(v!),
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'No. Sertifikat',
                      _c.noSertifikatCtrl,
                      isRequired: true,
                      isNumber: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Nama Pemilik',
                      _c.pemilikCtrl,
                      isRequired: true,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Desa / Lokasi',
                      _c.desaCtrl,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                  ],
                ),
                _buildSectionCard(
                  title: 'KETERANGAN BANK & PROSES',
                  icon: Icons.account_balance_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    _buildTextField(
                      'Bank / Instansi',
                      _c.bankCtrl,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Debitur (Jika Berbeda)',
                      _c.debiturCtrl,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Proses SHM (Misal: Roya, Balik Nama)',
                      _c.prosesSHMCtrl,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Detail Proses (Misal: SKMHT)',
                      _c.detailCtrl,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                  ],
                ),
                _buildSectionCard(
                  title: 'LOKASI FISIK & STATUS',
                  icon: Icons.location_on_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    _buildTextField(
                      'Posisi Eksternal (Klewis / BPN)',
                      _c.klewisCtrl,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Posisi Internal (Staff / PIC)',
                      _c.pemegangBerkasCtrl,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                    _buildDateRow(
                      'Tanggal Masuk',
                      _c.tglMasuk,
                      () =>
                          _pickDate(_c.tglMasuk, (dt) => _c.updateTglMasuk(dt)),
                      isDark: isDark,
                    ),

                    if (isEdit)
                      _buildDateRow(
                        'Tanggal Keluar',
                        _c.tglKeluar,
                        () => _pickDate(
                          _c.tglKeluar ?? DateTime.now(),
                          (dt) => _c.updateTglKeluar(dt),
                        ),
                        isDark: isDark,
                      ),

                    _buildDropdown(
                      'Status Sertifikat',
                      _c.statusPilihan,
                      _c.listStatus,
                      (v) => _c.setStatus(v!),
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Catatan / Keterangan',
                      _c.catatanCtrl,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _simpanData,
                  icon: Icon(Icons.save_rounded, color: goldColor),
                  label: Text(
                    isEdit ? 'SIMPAN PERUBAHAN' : 'SIMPAN DATA BARU',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: navyColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
    required Color currentSurface,
    required Color currentText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: currentSurface,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: goldColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: currentText,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isRequired = false,
    bool isUpperCase = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        textCapitalization: isUpperCase
            ? TextCapitalization.characters
            : TextCapitalization.none,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (isNumber) FilteringTextInputFormatter.digitsOnly,
          if (isUpperCase) UpperCaseTextFormatter(),
        ],
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          filled: true,
          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: navyColor, width: 1.5),
          ),
        ),
        validator: (value) => isRequired && (value == null || value.isEmpty)
            ? '$label wajib diisi'
            : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged, {
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: navyColor, width: 1.5),
          ),
        ),
        items: items
            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateRow(
    String label,
    DateTime? date,
    VoidCallback onTap, {
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null
                    ? DateFormat('dd MMM yyyy').format(date)
                    : 'Pilih Tanggal',
                style: const TextStyle(fontSize: 15),
              ),
              Icon(Icons.calendar_month_rounded, color: navyColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
