import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahan untuk akses langsung KCU
import 'package:sira_projects/controllers/master_data_controller.dart';
import 'package:sira_projects/data/repositories/master_data_repository.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> {
  late final MasterDataController _c;

  @override
  void initState() {
    super.initState();
    _c = MasterDataController(repo: context.read<MasterDataRepository>());
    _c.loadAllData();
  }

  // =====================================================================
  // DIALOG KHUSUS KCU (2 Kolom: Bank & PIC) -> Tembak Langsung ke Firebase
  // =====================================================================
  void _showAddKcuDialog() {
    final bankCtrl = TextEditingController();
    final picCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah KCU & PIC Bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Nama KCU/Bank',
                hintText: 'Contoh: KCU JAKARTA',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: picCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Nama PIC Bank',
                hintText: 'Contoh: BUDI SANTOSO',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (bankCtrl.text.isEmpty) return;

              // Simpan sebagai Map {Field: String} di doc 'kcu'
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
            child: const Text('TAMBAH'),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // DIALOG ASLI ANDA UNTUK NOTARIS & PIC (Tetap Dipertahankan)
  // =====================================================================
  void _showAddDialog(String docId, String title) {
    final inputCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah $title'),
        content: TextField(
          controller: inputCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(hintText: 'Masukkan nama $title baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () {
              _c.tambahItem(docId, inputCtrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('TAMBAH'),
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
        appBar: AppBar(
          title: const Text(
            'Panel Master Data',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'KCU/KCP'),
              Tab(text: 'NOTARIS'),
              Tab(text: 'PIC'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            if (_c.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              children: [
                _buildKcuView(), // Menggunakan View Khusus KCU yang baru
                _buildListView(
                  'notaris',
                  _c.listNotaris,
                  'NOTARIS',
                ), // Tetap menggunakan logic Anda
                _buildListView(
                  'pic',
                  _c.listPic,
                  'PIC',
                ), // Tetap menggunakan logic Anda
              ],
            );
          },
        ),
      ),
    );
  }

  // =====================================================================
  // VIEW KHUSUS KCU (Membaca Field:String dari Firebase)
  // =====================================================================
  Widget _buildKcuView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('master_data')
          .doc('kcu')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        data.remove('lastUpdate'); // Abaikan jika ada timestamp

        final listKeys = data.keys.toList()..sort();

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.indigo.withOpacity(0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${listKeys.length} KCU',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddKcuDialog, // Memanggil Dialog 2 Kolom
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah KCU'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: listKeys.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final namaBank = listKeys[index];
                  final picBank = data[namaBank];
                  return ListTile(
                    title: Text(
                      namaBank,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'PIC Bank: $picBank',
                      style: const TextStyle(color: Colors.indigo),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDeleteKcu(namaBank),
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
  // VIEW ASLI ANDA UNTUK NOTARIS & PIC (Tetap Dipertahankan)
  // =====================================================================
  Widget _buildListView(String docId, List<String> data, String title) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.withOpacity(0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${data.length} Item',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(docId, title),
                icon: const Icon(Icons.add),
                label: Text('Tambah $title'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: data.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              title: Text(data[index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(docId, data[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // FUNGSI HAPUS KHUSUS KCU
  // =====================================================================
  void _confirmDeleteKcu(String bankKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus KCU?'),
        content: Text(
          'Yakin ingin menghapus "$bankKey" beserta PIC-nya dari Master Data?',
        ),
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
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // FUNGSI HAPUS ASLI ANDA (Tetap Dipertahankan)
  // =====================================================================
  void _confirmDelete(String docId, String val) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item?'),
        content: Text('Yakin ingin menghapus "$val" dari Master Data?'),
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
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
