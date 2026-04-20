// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sira_projects/controllers/form_bapenda_controller.dart';
import 'package:sira_projects/data/repositories/bapenda_repository.dart';
import 'package:sira_projects/data/models/bapenda_model.dart';

// =====================================================================
// KELAS FORMATTER
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
      selection: newValue.selection,
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

  // Palet Warna Premium (Navy & Gold)
  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color surfaceColor = Colors.white;

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

  void _simpan() {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        String clean(String v) => v.replaceAll(RegExp(r'[^0-9]'), '');
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
          SnackBar(
            content: const Text(
              'Gagal! Nama Debitur Wajib Diisi.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Crash Form: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color currentBg = isDark ? const Color(0xFF121212) : bgColor;
    Color currentSurface = isDark ? const Color(0xFF1E1E1E) : surfaceColor;
    Color currentText = isDark ? Colors.white : navyColor;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        backgroundColor: currentSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: currentText),
        title: Text(
          widget.dataAwal == null ? 'Tambah Bapenda' : 'Edit Bapenda',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: currentText,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          if (_c.isLoading)
            return Center(child: CircularProgressIndicator(color: goldColor));

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionCard(
                  title: 'INFORMASI UMUM',
                  icon: Icons.person_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    _buildField(
                      _c.debiturCtrl,
                      'Nama Debitur',
                      isWajib: true,
                      textCapitalization: TextCapitalization.characters,
                      isDark: isDark,
                    ),
                    _buildField(
                      _c.developerCtrl,
                      'Developer / Perumahan',
                      textCapitalization: TextCapitalization.characters,
                      isDark: isDark,
                    ),
                    _buildField(
                      _c.nilaiJualBeliCtrl,
                      'Nilai Jual Beli',
                      keyboardType: TextInputType.number,
                      isCurrency: true,
                      inputFormatters: [CurrencyFormat()],
                      onChanged: (v) => _c.hitungOtomatis(),
                      isDark: isDark,
                    ),
                    _buildDropdown(
                      'Jenis Sertifikat',
                      _c.jenisSertifikat,
                      _c.listSertifikat,
                      (v) {
                        _c.jenisSertifikat = v!;
                        _c.hitungOtomatis();
                      },
                      isDark: isDark,
                    ),
                  ],
                ),

                _buildSectionCard(
                  title: 'DATA BPHTB',
                  icon: Icons.receipt_long_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    _buildField(
                      _c.nilaiBphtbCtrl,
                      'Nilai BPHTB',
                      isCurrency: true,
                      readOnly: false,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyFormat()],
                      isDark: isDark,
                    ),
                    _buildDropdown(
                      'Progres BPHTB',
                      _c.progresBphtb,
                      _c.listProgres,
                      (v) => setState(() => _c.progresBphtb = v!),
                      isDark: isDark,
                    ),
                    _buildField(
                      _c.setorBphtbCtrl,
                      'Petugas Setor BPHTB',
                      textCapitalization: TextCapitalization.characters,
                      isDark: isDark,
                    ),
                  ],
                ),

                _buildSectionCard(
                  title: 'DATA PPH',
                  icon: Icons.request_quote_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    _buildDropdown('Jenis PPH', _c.jenisPph, _c.listJenisPph, (
                      v,
                    ) {
                      _c.jenisPph = v!;
                      _c.hitungOtomatis();
                    }, isDark: isDark),
                    _buildField(
                      _c.nilaiPphCtrl,
                      'Nilai PPH',
                      isCurrency: true,
                      readOnly: false,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyFormat()],
                      isDark: isDark,
                    ),
                    _buildDropdown(
                      'Progres PPH',
                      _c.progresPph,
                      _c.listProgres,
                      (v) => setState(() => _c.progresPph = v!),
                      isDark: isDark,
                    ),
                    _buildField(
                      _c.setorPphCtrl,
                      'Petugas Setor PPH',
                      textCapitalization: TextCapitalization.characters,
                      isDark: isDark,
                    ),
                    _buildField(
                      _c.ntpnPphCtrl,
                      'NTPN PPH',
                      textCapitalization: TextCapitalization.characters,
                      isDark: isDark,
                    ),
                  ],
                ),

                if (widget.dataAwal != null)
                  _buildSectionCard(
                    title: 'JADWAL PEMBAYARAN',
                    icon: Icons.calendar_today_rounded,
                    isDark: isDark,
                    currentSurface: currentSurface,
                    currentText: currentText,
                    children: [
                      _buildField(
                        _c.tglBayarCtrl,
                        'Tanggal Bayar',
                        ikon: Icons.calendar_month_rounded,
                        readOnly: true,
                        onTap: () => _pilihTanggal(),
                        isDark: isDark,
                      ),
                    ],
                  ),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.save_rounded, color: goldColor),
                  label: Text(
                    'SIMPAN DATA BAPENDA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _simpan,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- KARTU SEKSI FORMULIR (CLEAN UI) ---
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
    required bool isDark,
  }) {
    List<TextInputFormatter> finalFormatters = inputFormatters != null
        ? List.from(inputFormatters)
        : [];
    if (textCapitalization == TextCapitalization.characters)
      finalFormatters.add(UpperCaseTextFormatter());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: finalFormatters,
        onChanged: onChanged,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: isWajib ? '$label *' : label,
          prefixIcon: ikon != null ? Icon(ikon, color: navyColor) : null,
          prefixText: (isCurrency && ctrl.text != 'MBR' && ctrl.text.isNotEmpty)
              ? 'Rp '
              : null,
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
    void Function(String?) onChanged, {
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
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
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: navyColor)),
        child: child!,
      ),
    );
    if (picked != null)
      setState(
        () => _c.tglBayarCtrl.text = DateFormat('dd-MM-yyyy').format(picked),
      );
  }
}
