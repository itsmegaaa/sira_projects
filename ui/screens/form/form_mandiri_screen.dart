import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sira_projects/controllers/form_mandiri_controller.dart';
import 'package:sira_projects/data/repositories/mandiri_repository.dart';

class FormMandiriScreen extends StatefulWidget {
  final Map<String, dynamic>? dataAwal;
  final int targetSLADefault;
  final String userRole;

  const FormMandiriScreen({
    super.key,
    this.dataAwal,
    this.targetSLADefault = 30,
    required this.userRole,
  });

  @override
  State<FormMandiriScreen> createState() => _FormOrderScreenState();
}

class _FormOrderScreenState extends State<FormMandiriScreen> {
  final _formKey = GlobalKey<FormState>();
  late final FormMandiriController _c;

  // Palet Warna Premium (Navy & Gold)
  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color surfaceColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _c = FormMandiriController(repo: context.read<MandiriRepository>());
    _c.inisialisasiData(widget.dataAwal, widget.targetSLADefault);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    DateTime? initialDate,
    Function(DateTime) onPicked, {
    DateTime? firstDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(2000),
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
        SnackBar(
          content: const Text('Lengkapi form yang wajib diisi!'),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (widget.dataAwal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengecek duplikasi data...')),
      );
      bool isDuplikat = await _c.cekKemungkinanDuplikat();

      if (isDuplikat) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        bool lanjutSimpan =
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 28,
                    ),
                    SizedBox(width: 8),
                    Text('Data Duplikat?'),
                  ],
                ),
                content: const Text(
                  'Data dengan No. Surat atau Debitur di tanggal yang sama kemungkinan sudah ada di database.\n\nApakah Anda yakin ingin tetap menyimpannya?',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'BATAL',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('TETAP SIMPAN'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!lanjutSimpan) return;
      }
    }

    if (!mounted) return;
    final dataOrder = _c.siapkanDataSimpan(widget.dataAwal?['id']);
    Navigator.pop(context, dataOrder);
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
          isEdit ? 'Edit Data Mandiri' : 'Input Order Baru',
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
            if (_c.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: goldColor),
                    const SizedBox(height: 16),
                    Text(
                      "Menyiapkan Formulir...",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            bool isInputBaru = widget.dataAwal == null;
            bool isLockedByRole =
                widget.userRole != 'ADMIN' &&
                (_c.progresPilihan == 'MENUNGGU APPROVAL' ||
                    _c.progresPilihan == 'DRAFT');
            bool kunciDropdownStatus = isInputBaru || isLockedByRole;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionCard(
                  title: 'PIHAK TERKAIT',
                  icon: Icons.people_alt_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    _buildTextField(
                      'Nama Debitur',
                      _c.debiturCtrl,
                      isRequired: true,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue t) => t.text == ''
                            ? const Iterable<String>.empty()
                            : _c.saranNotaris.where(
                                (o) => o.toLowerCase().contains(
                                  t.text.toLowerCase(),
                                ),
                              ),
                        onSelected: (String s) => _c.notarisCtrl.text = s,
                        fieldViewBuilder:
                            (ctx, ctrl, focusNode, onFieldSubmitted) {
                              if (ctrl.text.isEmpty &&
                                  _c.notarisCtrl.text.isNotEmpty)
                                ctrl.text = _c.notarisCtrl.text;
                              return TextFormField(
                                controller: ctrl,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Nama Notaris *',
                                  suffixIcon: const Icon(
                                    Icons.search,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: navyColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (val) => _c.notarisCtrl.text = val,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Nama Notaris wajib diisi'
                                    : null,
                              );
                            },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: _c.kcuPilihan,
                        decoration: InputDecoration(
                          labelText: 'KCU / KCP',
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: navyColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        hint: const Text('Pilih KCU'),
                        items: _c.listKcu
                            .map(
                              (val) => DropdownMenuItem(
                                value: val,
                                child: Text(
                                  val,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => _c.setKcu(val),
                      ),
                    ),
                    _buildTextField(
                      'PIC Bank',
                      _c.picBankCtrl,
                      isRequired: true,
                      isDark: isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: _c.picInternalPilihan,
                        decoration: InputDecoration(
                          labelText: 'PIC Internal / Akad',
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: navyColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        hint: const Text('Pilih PIC'),
                        items: _c.listPicInternal
                            .map(
                              (val) => DropdownMenuItem(
                                value: val,
                                child: Text(val),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => _c.setPicInternal(val),
                      ),
                    ),
                  ],
                ),

                _buildSectionCard(
                  title: 'DETAIL SURAT & WAKTU',
                  icon: Icons.description_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    _buildTextField(
                      'No. Surat Order',
                      _c.noSuratCtrl,
                      isUpperCase: true,
                      isRequired: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'No. Covernote',
                      _c.covernoteCtrl,
                      isUpperCase: true,
                      isRequired: true,
                      isDark: isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: _c.jenisPilihan,
                        decoration: InputDecoration(
                          labelText: 'Jenis Order',
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: navyColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        hint: const Text('Pilih Jenis'),
                        items: _c.listJenisOrder
                            .map(
                              (val) => DropdownMenuItem(
                                value: val,
                                child: Text(val),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => _c.setJenisOrder(val),
                      ),
                    ),
                    _buildTextField(
                      'Rincian Order',
                      _c.rincianCtrl
                        ..text = _c.rincianCtrl.text.isEmpty
                            ? 'SHM'
                            : _c.rincianCtrl.text,
                      isTitleCase: true,
                      isDark: isDark,
                    ),
                    _buildDateRow(
                      'Tgl. Order',
                      _c.tglOrder,
                      () => _pickDate(
                        _c.tglOrder,
                        (dt) => _c.updateTglOrder(dt, widget.targetSLADefault),
                      ),
                      isDark: isDark,
                    ),
                    _buildDateRow(
                      'Tgl. Pelaksanaan',
                      _c.tglPelaksanaan,
                      () => _pickDate(
                        _c.tglPelaksanaan ?? _c.tglOrder,
                        (dt) => _c.updateTglPelaksanaan(dt),
                        firstDate: _c.tglOrder,
                      ),
                      isDark: isDark,
                    ),
                    _buildDateRow(
                      'Batas SLA (Deadline)',
                      _c.deadline,
                      () =>
                          _pickDate(_c.deadline, (dt) => _c.updateDeadline(dt)),
                      isDark: isDark,
                    ),
                  ],
                ),

                _buildSectionCard(
                  title: 'FINANSIAL',
                  icon: Icons.monetization_on_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    _buildTextField(
                      'Limit Kredit',
                      _c.limitCtrl,
                      isNumber: true,
                      isRequired: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Nilai Hak Tanggungan (HT)',
                      _c.nilaiHTCtrl,
                      isNumber: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Biaya Notaris',
                      _c.biayaCtrl,
                      isNumber: true,
                      isDark: isDark,
                    ),
                  ],
                ),

                _buildSectionCard(
                  title: 'STATUS & LAPORAN',
                  icon: Icons.assignment_turned_in_rounded,
                  isDark: isDark,
                  currentSurface: currentSurface,
                  currentText: currentText,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: _c.progresPilihan,
                        decoration: InputDecoration(
                          labelText: 'Status Pekerjaan',
                          filled: true,
                          fillColor: kunciDropdownStatus
                              ? Colors.grey.withOpacity(0.2)
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade50),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: navyColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: kunciDropdownStatus
                            ? null
                            : (v) => _c.setProgres(v!),
                        items: _c.listProgres
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                      ),
                    ),
                    _buildTextField(
                      'Detail Progres (Contoh: SKMHT)',
                      _c.progresKeteranganCtrl,
                      isDark: isDark,
                    ),
                    if (!isInputBaru)
                      _buildDateRow(
                        'Tanggal BAST',
                        _c.tglBAST,
                        () =>
                            _pickDate(_c.tglBAST, (dt) => _c.updateTglBAST(dt)),
                        isDark: isDark,
                      ),
                    _buildTextField(
                      'Catatan / Per Kasus',
                      _c.perKasusCtrl,
                      isUpperCase: true,
                      isDark: isDark,
                    ),
                    _buildTextField(
                      'Kekurangan Berkas',
                      _c.noteCtrl,
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
                      letterSpacing: 1.0,
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

  // --- WIDGET HELPER KARTU & INPUT (CLEAN UI) ---
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
    bool isTitleCase = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        textCapitalization: isUpperCase
            ? TextCapitalization.characters
            : (isTitleCase
                  ? TextCapitalization.words
                  : TextCapitalization.none),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (isUpperCase) UpperCaseTextFormatter(),
          if (isTitleCase) TitleCaseTextFormatter(),
          if (isNumber) CurrencyFormatIdr(),
        ],
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixText: isNumber ? 'Rp ' : null,
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

// === UTILITIES FORMATTER ===
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

class CurrencyFormatIdr extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
    String formatted = '';
    int hitung = 0;
    for (int i = cleanText.length - 1; i >= 0; i--) {
      formatted = cleanText[i] + formatted;
      hitung++;
      if (hitung == 3 && i > 0) {
        formatted = '.$formatted';
        hitung = 0;
      }
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TitleCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String text = newValue.text;
    StringBuffer newText = StringBuffer();
    bool isNextUpper = true;
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (char == ' ' || char == '\n' || char == '-') {
        isNextUpper = true;
        newText.write(char);
      } else if (isNextUpper) {
        newText.write(char.toUpperCase());
        isNextUpper = false;
      } else {
        newText.write(char);
      }
    }
    return TextEditingValue(
      text: newText.toString(),
      selection: newValue.selection,
    );
  }
}
