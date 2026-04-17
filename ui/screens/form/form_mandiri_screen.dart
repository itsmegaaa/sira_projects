import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:gabut_tracker/controllers/form_mandiri_controller.dart';
import 'package:gabut_tracker/data/repositories/mandiri_repository.dart';

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
    );
    if (picked != null) onPicked(picked);
  }

  void _simpanData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi form yang wajib diisi!'),
          backgroundColor: Colors.red,
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
                  borderRadius: BorderRadius.circular(16),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isRequired = false,
    bool isUpperCase = false,
    bool isTitleCase = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixText: isNumber ? 'Rp ' : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade50,
        ),
        validator: (value) => isRequired && (value == null || value.isEmpty)
            ? '$label wajib diisi'
            : null,
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade50,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null
                    ? DateFormat('dd MMM yyyy').format(date)
                    : 'Pilih Tanggal',
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(
                Icons.calendar_month,
                color: Colors.blueAccent,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.dataAwal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Data Order' : 'Input Order Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black12
            : Colors.grey.shade100,
        child: Form(
          key: _formKey,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              // FITUR BARU: Tampilkan Loading saat menarik Master Data
              if (_c.isLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Menyiapkan Formulir...",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Logika pengunci status dropdown
              bool isInputBaru = widget.dataAwal == null;
              bool isLockedByRole =
                  widget.userRole != 'ADMIN' &&
                  (_c.progresPilihan == 'MENUNGGU APPROVAL' ||
                      _c.progresPilihan == 'DRAFT');
              bool kunciDropdownStatus = isInputBaru || isLockedByRole;

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionCard(
                    'Informasi Pihak Terkait',
                    Icons.people_alt,
                    [
                      _buildTextField(
                        'Nama Debitur',
                        _c.debiturCtrl,
                        isRequired: true,
                        isUpperCase: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
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
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.search,
                                      size: 18,
                                    ),
                                    filled: true,
                                    fillColor:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade50,
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
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DropdownButtonFormField<String>(
                          value: _c.kcuPilihan,
                          decoration: InputDecoration(
                            labelText: 'KCU / KCP',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade50,
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
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DropdownButtonFormField<String>(
                          value: _c.picInternalPilihan,
                          decoration: InputDecoration(
                            labelText: 'PIC Internal / Akad',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade50,
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

                  _buildSectionCard('Detail Surat & Waktu', Icons.description, [
                    _buildTextField(
                      'No. Surat Order',
                      _c.noSuratCtrl,
                      isUpperCase: true,
                      isRequired: true,
                    ),
                    _buildTextField(
                      'No. Covernote',
                      _c.covernoteCtrl,
                      isUpperCase: true,
                      isRequired: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: DropdownButtonFormField<String>(
                        value: _c.jenisPilihan,
                        decoration: InputDecoration(
                          labelText: 'Jenis Order',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
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
                    ),
                    _buildDateRow(
                      'Tgl. Order',
                      _c.tglOrder,
                      () => _pickDate(
                        _c.tglOrder,
                        (dt) => _c.updateTglOrder(dt, widget.targetSLADefault),
                      ),
                    ),
                    _buildDateRow(
                      'Tgl. Pelaksanaan',
                      _c.tglPelaksanaan,
                      () => _pickDate(
                        _c.tglPelaksanaan ?? _c.tglOrder,
                        (dt) => _c.updateTglPelaksanaan(dt),
                        firstDate: _c.tglOrder,
                      ),
                    ),
                    _buildDateRow(
                      'Batas SLA (Deadline)',
                      _c.deadline,
                      () =>
                          _pickDate(_c.deadline, (dt) => _c.updateDeadline(dt)),
                    ),
                  ]),

                  _buildSectionCard('Finansial', Icons.monetization_on, [
                    _buildTextField(
                      'Limit Kredit',
                      _c.limitCtrl,
                      isNumber: true,
                      isRequired: true,
                    ),
                    _buildTextField(
                      'Nilai Hak Tanggungan (HT)',
                      _c.nilaiHTCtrl,
                      isNumber: true,
                    ),
                    _buildTextField(
                      'Biaya Notaris',
                      _c.biayaCtrl,
                      isNumber: true,
                    ),
                  ]),

                  _buildSectionCard(
                    'Status & Laporan',
                    Icons.assignment_turned_in,
                    [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DropdownButtonFormField<String>(
                          value: _c.progresPilihan,
                          decoration: InputDecoration(
                            labelText: 'Status Pekerjaan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: kunciDropdownStatus
                                ? Colors.grey.withOpacity(0.2)
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50),
                          ),
                          onChanged: kunciDropdownStatus
                              ? null
                              : (v) => _c.setProgres(v!),
                          items: _c.listProgres
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                        ),
                      ),

                      _buildTextField(
                        'Detail Progres (Contoh: SKMHT)',
                        _c.progresKeteranganCtrl,
                      ),

                      // TANGGAL BAST HANYA MUNCUL SAAT EDIT DATA
                      if (!isInputBaru)
                        _buildDateRow(
                          'Tanggal BAST',
                          _c.tglBAST,
                          () => _pickDate(
                            _c.tglBAST,
                            (dt) => _c.updateTglBAST(dt),
                          ),
                        ),

                      _buildTextField(
                        'Catatan / Per Kasus',
                        _c.perKasusCtrl,
                        isUpperCase: true,
                      ),
                      _buildTextField(
                        'Kekurangan Berkas',
                        _c.noteCtrl,
                        isUpperCase: true,
                      ),
                    ],
                  ),

                  ElevatedButton.icon(
                    onPressed: _simpanData,
                    icon: const Icon(Icons.save),
                    label: Text(
                      isEdit ? 'Simpan Perubahan' : 'Simpan Data Baru',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              );
            },
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
