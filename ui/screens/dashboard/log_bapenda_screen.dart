// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LogBapendaScreen extends StatelessWidget {
  const LogBapendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Penyesuaian tema mode terang / gelap yang selaras dengan aplikasi
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color navyColor = const Color(0xFF0F172A);
    Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Riwayat Aktivitas Bapenda',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: surfaceColor,
        foregroundColor: isDark ? Colors.white : navyColor,
        iconTheme: IconThemeData(color: isDark ? Colors.white : navyColor),
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
            return Center(child: CircularProgressIndicator(color: navyColor));
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

          // Menggunakan ListView.builder layaknya Mandiri Screen
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 40),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildLogItem(
                data,
              ); // Memanggil widget UI yang sudah diseragamkan
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET ITEM TIMELINE (Disalin persis dari desain Mandiri Screen)
  // ===========================================================================
  Widget _buildLogItem(Map<String, dynamic> log) {
    String aksi = (log['aksi'] ?? 'INFO').toUpperCase();
    String detail = log['detail'] ?? '-';
    String oleh = log['oleh'] ?? 'Sistem';
    DateTime? waktu = (log['waktu'] as Timestamp?)?.toDate();

    IconData ikon;
    Color warna;
    switch (aksi) {
      case 'TAMBAH':
        ikon = Icons.add_circle_outline;
        warna = Colors.green;
        break;
      case 'EDIT':
        ikon = Icons.edit_note;
        warna = Colors.blue;
        break;
      case 'HAPUS':
        ikon = Icons.delete_forever;
        warna = Colors.red;
        break;
      case 'SELESAI':
        ikon = Icons.check_circle;
        warna = Colors.teal;
        break;
      case 'APPROVE':
        ikon = Icons.verified_user;
        warna = Colors.purple;
        break;
      case 'EXPORT':
        ikon = Icons.file_download;
        warna = Colors.orange;
        break;
      default:
        ikon = Icons.info_outline;
        warna = Colors.grey;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Garis Timeline vertikal di sebelah kiri
          Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warna.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, color: warna, size: 16),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.grey.withOpacity(0.15),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: warna.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          aksi,
                          style: TextStyle(
                            color: warna,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        waktu != null ? DateFormat('HH:mm').format(waktu) : '-',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            oleh,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (waktu != null)
                        Text(
                          DateFormat('dd MMM yyyy').format(waktu),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
