import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LogBapendaScreen extends StatelessWidget {
  const LogBapendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Aktivitas Bapenda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 202, 175, 51),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil log dari Firestore dan diurutkan dari yang paling baru
        stream: FirebaseFirestore.instance
            .collection('logs_bapenda')
            .orderBy('waktu', descending: true)
            .limit(
              100,
            ) // Batasi 100 riwayat terakhir agar aplikasi tetap ringan
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat aktivitas.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const Divider(height: 30),
            itemBuilder: (context, index) {
              var data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              // Formatting Waktu Firebase ke tampilan yang mudah dibaca
              DateTime waktu;
              if (data['waktu'] != null) {
                waktu = (data['waktu'] as Timestamp).toDate();
              } else {
                waktu = DateTime.now();
              }
              String waktuStr = DateFormat('dd MMM yyyy, HH:mm').format(waktu);

              String aksi = data['aksi'] ?? 'INFO';
              String detail = data['detail'] ?? '';
              String oleh = data['oleh'] ?? 'Sistem';

              // Menentukan warna label (badge) sesuai dengan jenis aksi
              Color badgeColor = Colors.blue;
              if (aksi == 'TAMBAH') badgeColor = Colors.green;
              if (aksi == 'EDIT') badgeColor = Colors.orange;
              if (aksi == 'HAPUS') badgeColor = Colors.red;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Garis Timeline vertikal di sebelah kiri
                  Column(
                    children: [
                      Icon(Icons.circle, size: 14, color: badgeColor),
                      Container(
                        width: 2,
                        height: 60,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: badgeColor),
                              ),
                              child: Text(
                                aksi,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            Text(
                              waktuStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(detail, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              oleh,
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
