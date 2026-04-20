// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sira_projects/controllers/master_data_controller.dart';
import 'package:sira_projects/data/repositories/master_data_repository.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> {
  late final MasterDataController _c;

  // Palet Warna Premium
  final Color navyColor = const Color(0xFF0A192F);
  final Color goldAccent = const Color(0xFFC5A059);

  @override
  void initState() {
    super.initState();
    _c = MasterDataController(repo: context.read<MasterDataRepository>());
    _c.loadAllData();
  }

  // =====================================================================
  // DIALOG KHUSUS KCU (Premium Style)
  // =====================================================================
  void _showAddKcuDialog() {
    final bankCtrl = TextEditingController();
    final picCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'TAMBAH KCU & PIC',
          style: TextStyle(
            color: navyColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Nama KCU/Bank',
                labelStyle: TextStyle(color: navyColor),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: goldAccent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: picCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Nama PIC Bank',
                labelStyle: TextStyle(color: navyColor),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: goldAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('BATAL', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navyColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (bankCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('master_data')
                  .doc('kcu')
                  .set({
                    bankCtrl.text.trim().toUpperCase(): picCtrl.text
                        .trim()
                        .toUpperCase(),
                  }, SetOptions(merge: true));

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('KCU Berhasil Ditambahkan!')),
                );
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // DIALOG MASTER DATA UMUM (Premium Style)
  // =====================================================================
  void _showAddDialog(String docId, String title) {
    final inputCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'TAMBAH $title',
          style: TextStyle(
            color: navyColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: inputCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Masukkan nama $title baru',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: goldAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('BATAL', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navyColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _c.tambahItem(docId, inputCtrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'PANEL MASTER DATA',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
          ),
          backgroundColor: navyColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: goldAccent,
            indicatorWeight: 4,
            labelColor: goldAccent,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'KCU/KCP'),
              Tab(text: 'NOTARIS'),
              Tab(text: 'PIC'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            if (_c.isLoading) {
              return Center(child: CircularProgressIndicator(color: navyColor));
            }
            return TabBarView(
              children: [
                _buildKcuView(),
                _buildListView('notaris', _c.listNotaris, 'NOTARIS'),
                _buildListView('pic', _c.listPic, 'PIC'),
              ],
            );
          },
        ),
      ),
    );
  }

  // =====================================================================
  // VIEW KHUSUS KCU (Card Based)
  // =====================================================================
  Widget _buildKcuView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('master_data')
          .doc('kcu')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator(color: navyColor));

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        data.remove('lastUpdate');

        final listKeys = data.keys.toList()..sort();

        return Column(
          children: [
            _buildHeaderStats(listKeys.length, 'KCU / KCP', _showAddKcuDialog),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: listKeys.length,
                itemBuilder: (context, index) {
                  final namaBank = listKeys[index];
                  final picBank = data[namaBank];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      title: Text(
                        namaBank,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      subtitle: Text(
                        'PIC Bank: $picBank',
                        style: TextStyle(
                          color: goldAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _confirmDeleteKcu(namaBank),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================================
  // VIEW MASTER DATA UMUM (Card Based)
  // =====================================================================
  Widget _buildListView(String docId, List<String> data, String title) {
    return Column(
      children: [
        _buildHeaderStats(
          data.length,
          title,
          () => _showAddDialog(docId, title),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: data.length,
            itemBuilder: (context, index) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text(
                  data[index],
                  style: TextStyle(
                    color: navyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(docId, data[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pembantu untuk header agar senada (Pill Style)
  Widget _buildHeaderStats(int count, String label, VoidCallback onAdd) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '$count Item Terdaftar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: navyColor,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('TAMBAH'),
            style: ElevatedButton.styleFrom(
              backgroundColor: navyColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKcu(String bankKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('HAPUS DATA?'),
        content: Text('Yakin ingin menghapus "$bankKey" dari Master Data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('master_data')
                  .doc('kcu')
                  .update({bankKey: FieldValue.delete()});
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'HAPUS',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String docId, String val) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('HAPUS ITEM?'),
        content: Text('Yakin ingin menghapus "$val"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () {
              _c.hapusItem(docId, val);
              Navigator.pop(context);
            },
            child: const Text(
              'HAPUS',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
